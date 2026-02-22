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
            return ExecuteWorkOrdersStoredProcedure(filter);
        }

        public List<Dictionary<string, object>> GetWorkOrderItems(int woNumber, List<string> itemCodes, List<string> filterItemCategories)
        {
            using (var conn = clsDataHelper.sqlconn(false)) // read-only connection, same pattern used solution-wide
            using (var cmd = new SqlCommand("spWorkOrderItems", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.CommandTimeout = 180;

                cmd.Parameters.Add("@WONumber", SqlDbType.Int).Value = woNumber;
                cmd.Parameters.Add("@ItemCodesCsv", SqlDbType.VarChar, -1).Value = (object)ToCsv(itemCodes) ?? DBNull.Value;
                cmd.Parameters.Add("@FilterItemCategoriesCsv", SqlDbType.VarChar, -1).Value = (object)ToCsv(filterItemCategories) ?? DBNull.Value;

                return ExecuteCommandToDictionaryList(cmd);
            }
        }

        private static List<Dictionary<string, object>> ExecuteWorkOrdersStoredProcedure(WorkOrderQueryFilter filter)
        {
            using (var conn = clsDataHelper.sqlconn(false)) // read-only connection, same pattern used solution-wide
            using (var cmd = new SqlCommand("spWorkOrders", conn))
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
    }

    public class WorkOrderQueryFilter
    {
        public List<string> Categories { get; set; }
        public bool? CompletionDateIsBlank { get; set; }
        public int? WONumber { get; set; }
        public List<string> BuildingNums { get; set; }
        public string JobStatus { get; set; }
    }
}
