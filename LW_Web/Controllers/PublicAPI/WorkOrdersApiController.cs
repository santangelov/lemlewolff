using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web.Mvc;
using LW_Data;

namespace LW_Web.Controllers
{
    /*
     Findings mini-audit:
     - tblWorkOrders completion-date column is [CompletedDate] [date] NULL.
     - tblWorkOrderItems columns are: WOItemRowID, YardiWODetailRowID, WONumber, ItemCode, Quantity, PayAmount, FullDescription.
     - Vacancy API credentials come from Web.config appSettings keys VacancyApiAccountId and VacancyApiPassword; auth is enforced by IsAuthorized() with Basic header parsing and WWW-Authenticate on 401.
     - ItemCode master source investigation: tblSortlyInventory (itemCode/itemName) exists and is joined in some procedures, but there is no FK from tblWorkOrderItems.ItemCode, datatype/length differs (varchar(50) vs varchar(10)), and tblPhysicalInventory is date-snapshot based (Code/Description by AsOfDate). Not a definitive single source-of-truth for all WO item descriptions, so no enrichment is applied.
     - Public API organization: this controller, VacancyApiController, and the Properties API controller file now live under Controllers/PublicAPI. The Properties API class name remains ApiController to preserve existing /Api/Properties route behavior.
    */
    [RoutePrefix("api/work-orders")]
    public class WorkOrdersApiController : Controller
    {
        private readonly string _accountId;
        private readonly string _password;

        public WorkOrdersApiController()
        {
            _accountId = ConfigurationManager.AppSettings["VacancyApiAccountId"];
            _password = ConfigurationManager.AppSettings["VacancyApiPassword"];
        }

        [HttpPost]
        [Route("query")]
        public ActionResult Query(WorkOrderSearchRequest request)
        {
            if (!IsAuthorized(Request.Headers["Authorization"]))
            {
                Response.AddHeader("WWW-Authenticate", "Basic realm=\"WorkOrderAPI\"");
                return new HttpStatusCodeResult(401, "Unauthorized");
            }

            request = request ?? new WorkOrderSearchRequest();

            bool hasFilters =
                (request.Categories != null && request.Categories.Any(x => !string.IsNullOrWhiteSpace(x))) ||
                request.CompletionDateIsBlank.HasValue ||
                (request.WONumbers != null && request.WONumbers.Any()) ||
                (request.BuildingNums != null && request.BuildingNums.Any(x => !string.IsNullOrWhiteSpace(x))) ||
                !string.IsNullOrWhiteSpace(request.JobStatus);

            if (!hasFilters)
            {
                return JsonError(400,
                    "At least one filter is required (Categories, CompletionDateIsBlank, WONumbers, BuildingNums, or JobStatus). Returning all work orders is not allowed.");
            }

            int estimatedParameterCount = EstimateFilterParameterCount(request);
            if (estimatedParameterCount > 2000)
            {
                return JsonError(400,
                    "Too many filter values were provided.",
                    "Reduce total Categories/WONumbers/BuildingNums values or switch to broader field-based filters.");
            }

            try
            {
                var workOrders = GetWorkOrders(request);

                if (request.IncludeWOItems.GetValueOrDefault(false) && workOrders.Count > 0)
                {
                    Dictionary<int, List<Dictionary<string, object>>> itemLookup;
                    try
                    {
                        itemLookup = GetWorkOrderItems(request);
                    }
                    catch (SqlException ex) when (ex.Number == 229)
                    {
                        return JsonError(403,
                            "The configured database user does not have permission to read work order items (dbo.tblWorkOrderItems).",
                            "Grant SELECT on dbo.tblWorkOrderItems, or set IncludeWOItems=false.");
                    }

                    foreach (var workOrder in workOrders)
                    {
                        int woNumber = workOrder.ContainsKey("WONumber") && workOrder["WONumber"] != null
                            ? Convert.ToInt32(workOrder["WONumber"])
                            : 0;

                        workOrder["WorkOrderItems"] = itemLookup.ContainsKey(woNumber)
                            ? itemLookup[woNumber]
                            : new List<Dictionary<string, object>>();
                    }
                }

                return Json(workOrders, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                return JsonError(500, "Unexpected error while processing request.", ex.Message);
            }
        }

        private List<Dictionary<string, object>> GetWorkOrders(WorkOrderSearchRequest request)
        {
            var sql = @"SELECT * FROM dbo.tblWorkOrders wo WHERE 1 = 1";

            using (var conn = clsDataHelper.sqlconn(false))
            using (var cmd = new SqlCommand())
            {
                cmd.Connection = conn;
                sql += BuildWorkOrderFilterSql(cmd, request, "wo", "wof");

                cmd.CommandText = sql;
                cmd.CommandType = CommandType.Text;
                cmd.CommandTimeout = 180;

                return ExecuteCommandToDictionaryList(cmd);
            }
        }

        private Dictionary<int, List<Dictionary<string, object>>> GetWorkOrderItems(WorkOrderSearchRequest request)
        {
            var result = new Dictionary<int, List<Dictionary<string, object>>>();
            var sql = @"
                SELECT woi.*
                FROM dbo.tblWorkOrderItems woi
                INNER JOIN dbo.tblWorkOrders wo ON wo.WONumber = woi.WONumber
                WHERE 1 = 1";

            using (var conn = clsDataHelper.sqlconn(false))
            using (var cmd = new SqlCommand())
            {
                cmd.Connection = conn;
                sql += BuildWorkOrderFilterSql(cmd, request, "wo", "itf");

                cmd.CommandText = sql;
                cmd.CommandType = CommandType.Text;
                cmd.CommandTimeout = 180;

                var items = ExecuteCommandToDictionaryList(cmd);

                foreach (var item in items)
                {
                    if (!item.ContainsKey("WONumber") || item["WONumber"] == null)
                    {
                        continue;
                    }

                    int woNumber = Convert.ToInt32(item["WONumber"]);
                    if (!result.ContainsKey(woNumber))
                    {
                        result[woNumber] = new List<Dictionary<string, object>>();
                    }

                    result[woNumber].Add(item);
                }
            }

            return result;
        }

        private static int EstimateFilterParameterCount(WorkOrderSearchRequest request)
        {
            int count = 0;

            if (request.Categories != null)
            {
                count += request.Categories
                    .Where(x => !string.IsNullOrWhiteSpace(x))
                    .Select(x => x.Trim())
                    .Distinct(StringComparer.OrdinalIgnoreCase)
                    .Count();
            }

            if (request.WONumbers != null)
            {
                count += request.WONumbers.Distinct().Count();
            }

            if (request.BuildingNums != null)
            {
                count += request.BuildingNums
                    .Where(x => !string.IsNullOrWhiteSpace(x))
                    .Select(x => x.Trim())
                    .Distinct(StringComparer.OrdinalIgnoreCase)
                    .Count();
            }

            if (!string.IsNullOrWhiteSpace(request.JobStatus))
            {
                count += 1;
            }

            return count;
        }

        private static string BuildWorkOrderFilterSql(SqlCommand cmd, WorkOrderSearchRequest request, string woAlias, string paramPrefix)
        {
            var sql = string.Empty;

            if (request.Categories != null)
            {
                var categories = request.Categories
                    .Where(x => !string.IsNullOrWhiteSpace(x))
                    .Select(x => x.Trim())
                    .Distinct(StringComparer.OrdinalIgnoreCase)
                    .ToList();

                if (categories.Count > 0)
                {
                    var categoryParams = new List<string>();
                    for (int i = 0; i < categories.Count; i++)
                    {
                        string paramName = "@" + paramPrefix + "cat" + i;
                        categoryParams.Add(paramName);
                        cmd.Parameters.Add(paramName, SqlDbType.VarChar, 50).Value = categories[i].ToUpperInvariant();
                    }

                    sql += "\nAND UPPER(" + woAlias + ".Category) IN (" + string.Join(",", categoryParams) + ")";
                }
            }

            if (request.CompletionDateIsBlank.HasValue)
            {
                sql += request.CompletionDateIsBlank.Value
                    ? "\nAND " + woAlias + ".CompletedDate IS NULL"
                    : "\nAND " + woAlias + ".CompletedDate IS NOT NULL";
            }

            if (request.WONumbers != null)
            {
                var woNumbers = request.WONumbers.Distinct().ToList();
                if (woNumbers.Count > 0)
                {
                    var woParams = new List<string>();
                    for (int i = 0; i < woNumbers.Count; i++)
                    {
                        string paramName = "@" + paramPrefix + "wo" + i;
                        woParams.Add(paramName);
                        cmd.Parameters.Add(paramName, SqlDbType.Int).Value = woNumbers[i];
                    }

                    sql += "\nAND " + woAlias + ".WONumber IN (" + string.Join(",", woParams) + ")";
                }
            }

            if (request.BuildingNums != null)
            {
                var buildingNums = request.BuildingNums
                    .Where(x => !string.IsNullOrWhiteSpace(x))
                    .Select(x => x.Trim())
                    .Distinct(StringComparer.OrdinalIgnoreCase)
                    .ToList();

                if (buildingNums.Count > 0)
                {
                    var buildingParams = new List<string>();
                    for (int i = 0; i < buildingNums.Count; i++)
                    {
                        string paramName = "@" + paramPrefix + "bld" + i;
                        buildingParams.Add(paramName);
                        cmd.Parameters.Add(paramName, SqlDbType.VarChar, 50).Value = buildingNums[i].ToUpperInvariant();
                    }

                    sql += "\nAND UPPER(" + woAlias + ".BuildingNum) IN (" + string.Join(",", buildingParams) + ")";
                }
            }

            if (!string.IsNullOrWhiteSpace(request.JobStatus))
            {
                string paramName = "@" + paramPrefix + "jobStatus";
                cmd.Parameters.Add(paramName, SqlDbType.VarChar, 50).Value = request.JobStatus.Trim().ToUpperInvariant();
                sql += "\nAND UPPER(" + woAlias + ".JobStatus) = " + paramName;
            }

            return sql;
        }

        private static List<Dictionary<string, object>> ExecuteCommandToDictionaryList(SqlCommand cmd)
        {
            var table = new DataTable();
            using (var da = new SqlDataAdapter(cmd))
            {
                da.Fill(table);
            }

            return DataTableToDictionaryList(table);
        }

        private static List<Dictionary<string, object>> DataTableToDictionaryList(DataTable table)
        {
            var rows = new List<Dictionary<string, object>>();

            foreach (DataRow row in table.Rows)
            {
                var item = new Dictionary<string, object>();

                foreach (DataColumn column in table.Columns)
                {
                    object value = row[column];
                    item[column.ColumnName] = value == DBNull.Value ? null : value;
                }

                rows.Add(item);
            }

            return rows;
        }

        private ActionResult JsonError(int statusCode, string message, string detail = null)
        {
            Response.StatusCode = statusCode;
            Response.TrySkipIisCustomErrors = true;

            if (string.IsNullOrWhiteSpace(detail))
            {
                return Json(new { message }, JsonRequestBehavior.AllowGet);
            }

            return Json(new { message, detail }, JsonRequestBehavior.AllowGet);
        }

        private bool IsAuthorized(string authorizationHeader)
        {
            if (string.IsNullOrWhiteSpace(authorizationHeader))
            {
                return false;
            }

            const string basicPrefix = "Basic ";
            if (!authorizationHeader.StartsWith(basicPrefix, StringComparison.OrdinalIgnoreCase))
            {
                return false;
            }

            string encodedCredentials = authorizationHeader.Substring(basicPrefix.Length).Trim();
            if (string.IsNullOrWhiteSpace(encodedCredentials))
            {
                return false;
            }

            string decodedCredentials;
            try
            {
                byte[] credentialBytes = Convert.FromBase64String(encodedCredentials);
                decodedCredentials = System.Text.Encoding.UTF8.GetString(credentialBytes);
            }
            catch (FormatException)
            {
                decodedCredentials = encodedCredentials;
            }

            string[] parts = decodedCredentials.Split(new[] { ':' }, 2);

            if (parts.Length != 2 && encodedCredentials.Contains(":"))
            {
                parts = encodedCredentials.Split(new[] { ':' }, 2);
            }

            if (parts.Length != 2)
            {
                return false;
            }

            string providedAccountId = parts[0];
            string providedPassword = parts[1];

            return !string.IsNullOrEmpty(providedAccountId)
                && !string.IsNullOrEmpty(providedPassword)
                && string.Equals(providedAccountId, _accountId)
                && string.Equals(providedPassword, _password);
        }
    }

    public class WorkOrderSearchRequest
    {
        public List<string> Categories { get; set; }
        public bool? CompletionDateIsBlank { get; set; }
        public List<int> WONumbers { get; set; }
        public List<string> BuildingNums { get; set; }
        public string JobStatus { get; set; }
        public bool? IncludeWOItems { get; set; }
    }
}
