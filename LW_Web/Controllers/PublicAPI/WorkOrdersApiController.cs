using System;
using System.Collections.Generic;
using System.Configuration;
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
        private readonly clsWorkOrdersData _workOrdersData;

        public WorkOrdersApiController()
        {
            _accountId = ConfigurationManager.AppSettings["VacancyApiAccountId"];
            _password = ConfigurationManager.AppSettings["VacancyApiPassword"];
            _workOrdersData = new clsWorkOrdersData();
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
                request.WONumber.HasValue ||
                (request.BuildingNums != null && request.BuildingNums.Any(x => !string.IsNullOrWhiteSpace(x))) ||
                !string.IsNullOrWhiteSpace(request.JobStatus);

            if (!hasFilters)
            {
                return JsonError(400,
                    "At least one filter is required (Categories, CompletionDateIsBlank, WONumber, BuildingNums, or JobStatus). Returning all work orders is not allowed.");
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
            return _workOrdersData.GetWorkOrders(ToFilter(request));
        }

        private Dictionary<int, List<Dictionary<string, object>>> GetWorkOrderItems(WorkOrderSearchRequest request)
        {
            return _workOrdersData.GetWorkOrderItems(ToFilter(request));
        }

        private static WorkOrderQueryFilter ToFilter(WorkOrderSearchRequest request)
        {
            return new WorkOrderQueryFilter
            {
                Categories = request.Categories,
                CompletionDateIsBlank = request.CompletionDateIsBlank,
                WONumber = request.WONumber,
                BuildingNums = request.BuildingNums,
                JobStatus = request.JobStatus,
                ItemCodes = request.ItemCodes,
                FilterItemCategories = request.FilterItemCategories
            };
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
        public int? WONumber { get; set; }
        public List<string> BuildingNums { get; set; }
        public string JobStatus { get; set; }
        public List<string> ItemCodes { get; set; }
        public List<string> FilterItemCategories { get; set; }
        public bool? IncludeWOItems { get; set; }
    }
}
