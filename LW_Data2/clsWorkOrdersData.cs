using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;

namespace LW_Data
{
    public class clsWorkOrdersData
    {
        public List<Dictionary<string, object>> GetWorkOrders(WorkOrderQueryFilter filter)
        {
            return ExecuteStoredProcedure("spWorkOrders", filter);
        }

        public Dictionary<int, List<Dictionary<string, object>>> GetWorkOrderItems(WorkOrderQueryFilter filter)
        {
            var result = new Dictionary<int, List<Dictionary<string, object>>>();
            var items = ExecuteStoredProcedure("spWorkOrderItems", filter);

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

            return result;
        }


        public List<Dictionary<string, object>> GetWorkOrdersForApi(WorkOrderQueryFilter filter, bool includeWOItems, bool includePOs)
        {
            var workOrders = GetWorkOrders(filter);
            if (workOrders.Count == 0)
            {
                return workOrders;
            }

            if (includeWOItems)
            {
                var itemLookup = GetWorkOrderItems(filter);
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

            if (includePOs)
            {
                var poCacheByWONumber = new Dictionary<string, List<Dictionary<string, object>>>(StringComparer.OrdinalIgnoreCase);
                var purchaseOrdersData = new clsPurchaseOrdersData();

                foreach (var workOrder in workOrders)
                {
                    string woNumber = workOrder.ContainsKey("WONumber") && workOrder["WONumber"] != null
                        ? Convert.ToString(workOrder["WONumber"])
                        : null;

                    if (string.IsNullOrWhiteSpace(woNumber))
                    {
                        workOrder["PurchaseOrders"] = new List<Dictionary<string, object>>();
                        continue;
                    }

                    if (!poCacheByWONumber.ContainsKey(woNumber))
                    {
                        poCacheByWONumber[woNumber] = purchaseOrdersData.GetByWONumber(woNumber);
                    }

                    workOrder["PurchaseOrders"] = poCacheByWONumber[woNumber];
                }
            }

            return workOrders;
        }

        public int AssignByWONumber(string woNumber, int? assignedToID)
        {
            var dh = new clsDataHelper();
            dh.cmd.Parameters.Add("@WONumber", SqlDbType.VarChar, 50).Value = (object)(woNumber ?? string.Empty);
            dh.cmd.Parameters.Add("@AssignedToID", SqlDbType.Int).Value = assignedToID.HasValue ? (object)assignedToID.Value : DBNull.Value;

            var dt = dh.GetDataTable("spWorkOrders_AssignByWONumber");
            if (dt == null || dt.Rows.Count == 0 || !dt.Columns.Contains("RowsAffected"))
            {
                return 0;
            }

            var value = dt.Rows[0]["RowsAffected"];
            return value == null || value == DBNull.Value ? 0 : Convert.ToInt32(value);
        }

        private static List<Dictionary<string, object>> ExecuteStoredProcedure(string storedProcedureName, WorkOrderQueryFilter filter)
        {
            using (var conn = clsDataHelper.sqlconn(false))
            using (var cmd = new SqlCommand(storedProcedureName, conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.CommandTimeout = 180;

                cmd.Parameters.Add("@CategoriesCsv", SqlDbType.VarChar, -1).Value = (object)ToCsv(filter.Categories) ?? DBNull.Value;
                cmd.Parameters.Add("@CompletionDateIsBlank", SqlDbType.Bit).Value = filter.CompletionDateIsBlank.HasValue
                    ? (object)filter.CompletionDateIsBlank.Value
                    : DBNull.Value;
                cmd.Parameters.Add("@WONumber", SqlDbType.Int).Value = filter.WONumber.HasValue
                    ? (object)filter.WONumber.Value
                    : DBNull.Value;
                cmd.Parameters.Add("@BuildingNumsCsv", SqlDbType.VarChar, -1).Value = (object)ToCsv(filter.BuildingNums) ?? DBNull.Value;
                cmd.Parameters.Add("@JobStatus", SqlDbType.VarChar, 50).Value = string.IsNullOrWhiteSpace(filter.JobStatus)
                    ? (object)DBNull.Value
                    : filter.JobStatus.Trim();
                cmd.Parameters.Add("@ItemCodesCsv", SqlDbType.VarChar, -1).Value = (object)ToCsv(filter.ItemCodes) ?? DBNull.Value;
                cmd.Parameters.Add("@FilterItemCategoriesCsv", SqlDbType.VarChar, -1).Value = (object)ToCsv(filter.FilterItemCategories) ?? DBNull.Value;
                cmd.Parameters.Add("@IsAssigned", SqlDbType.Bit).Value = filter.IsAssigned.HasValue
                    ? (object)filter.IsAssigned.Value
                    : DBNull.Value;
                cmd.Parameters.Add("@AssignedToID", SqlDbType.Int).Value = filter.AssignedToID.HasValue
                    ? (object)filter.AssignedToID.Value
                    : DBNull.Value;

                return ExecuteCommandToDictionaryList(cmd);
            }
        }

        private static string ToCsv(IEnumerable<string> values)
        {
            if (values == null)
            {
                return null;
            }

            var cleaned = values
                .Where(x => !string.IsNullOrWhiteSpace(x))
                .Select(x => x.Trim())
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToList();

            return cleaned.Count == 0 ? null : string.Join(",", cleaned);
        }

        private static List<Dictionary<string, object>> ExecuteCommandToDictionaryList(SqlCommand cmd)
        {
            var table = new DataTable();
            using (var da = new SqlDataAdapter(cmd))
            {
                da.Fill(table);
            }

            return clsDataMappingHelper.DataTableToDictionaryList(table);
        }
    }

    public class WorkOrderQueryFilter
    {
        public List<string> Categories { get; set; }
        public bool? CompletionDateIsBlank { get; set; }
        public int? WONumber { get; set; }
        public List<string> BuildingNums { get; set; }
        public string JobStatus { get; set; }
        public List<string> ItemCodes { get; set; }
        public List<string> FilterItemCategories { get; set; }
        public bool? IsAssigned { get; set; }
        public int? AssignedToID { get; set; }
    }
}
