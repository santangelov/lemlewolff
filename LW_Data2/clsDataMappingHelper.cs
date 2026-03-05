using System;
using System.Collections.Generic;
using System.Data;

namespace LW_Data
{
    public static class clsDataMappingHelper
    {
        public static List<Dictionary<string, object>> DataTableToDictionaryList(DataTable table, bool caseInsensitiveKeys = false)
        {
            var rows = new List<Dictionary<string, object>>();
            if (table == null)
            {
                return rows;
            }

            foreach (DataRow row in table.Rows)
            {
                var item = caseInsensitiveKeys
                    ? new Dictionary<string, object>(StringComparer.OrdinalIgnoreCase)
                    : new Dictionary<string, object>();

                foreach (DataColumn column in table.Columns)
                {
                    var value = row[column];
                    item[column.ColumnName] = value == DBNull.Value ? null : value;
                }

                rows.Add(item);
            }

            return rows;
        }
    }
}
