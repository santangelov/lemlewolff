using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace LW_Data
{
    public class clsPurchaseOrdersData
    {
        public List<Dictionary<string, object>> GetByWONumber(string woNumber)
        {
            var dh = new clsDataHelper();
            dh.cmd.Parameters.Add("@WONumber", SqlDbType.VarChar, 50).Value = (object)(woNumber ?? string.Empty);
            return ExecuteAndShape(dh, "spPurchaseOrders_ByWONumber");
        }

        public Dictionary<string, object> GetByPONumber(string poNumber)
        {
            var dh = new clsDataHelper();
            dh.cmd.Parameters.Add("@PONumber", SqlDbType.VarChar, 50).Value = (object)(poNumber ?? string.Empty);
            var purchaseOrders = ExecuteAndShape(dh, "spPurchaseOrders_ByPONumber");
            return purchaseOrders.Count > 0 ? purchaseOrders[0] : null;
        }

        public List<Dictionary<string, object>> GetPurchaseOrders(string woNumber = null)
        {
            if (!string.IsNullOrWhiteSpace(woNumber))
            {
                return GetByWONumber(woNumber);
            }

            var dh = new clsDataHelper();
            return ExecuteAndShape(dh, "spPurchaseOrders");
        }

        private static List<Dictionary<string, object>> ExecuteAndShape(clsDataHelper dh, string storedProcedure)
        {
            var result = new List<Dictionary<string, object>>();

            var ds = dh.GetDataSetCMD(storedProcedure, ref dh.cmd);
            if (ds == null || ds.Tables.Count == 0)
            {
                return result;
            }

            var headers = clsDataMappingHelper.DataTableToDictionaryList(ds.Tables[0], true);
            var detailsByPONumber = new Dictionary<string, List<Dictionary<string, object>>>(StringComparer.OrdinalIgnoreCase);

            if (ds.Tables.Count > 1)
            {
                var details = clsDataMappingHelper.DataTableToDictionaryList(ds.Tables[1], true);
                foreach (var detail in details)
                {
                    var poNumber = detail.ContainsKey("PONumber") && detail["PONumber"] != null
                        ? Convert.ToString(detail["PONumber"])
                        : string.Empty;

                    if (!detailsByPONumber.ContainsKey(poNumber))
                    {
                        detailsByPONumber[poNumber] = new List<Dictionary<string, object>>();
                    }

                    detailsByPONumber[poNumber].Add(detail);
                }
            }

            foreach (var header in headers)
            {
                var poNumber = header.ContainsKey("PONumber") && header["PONumber"] != null
                    ? Convert.ToString(header["PONumber"])
                    : string.Empty;

                header["Details"] = detailsByPONumber.ContainsKey(poNumber)
                    ? detailsByPONumber[poNumber]
                    : new List<Dictionary<string, object>>();
            }

            return headers;
        }
    }
}
