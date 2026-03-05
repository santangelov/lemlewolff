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
            var result = new List<Dictionary<string, object>>();
            var dh = new clsDataHelper();

            dh.cmd.Parameters.Add("@WONumber", SqlDbType.VarChar, 50).Value = (object)(woNumber ?? string.Empty);
            var ds = dh.GetDataSetCMD("spPurchaseOrders_ByWONumber", ref dh.cmd);
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

    public class PurchaseOrderDto
    {
        public Dictionary<string, object> Header { get; set; } = new Dictionary<string, object>(StringComparer.OrdinalIgnoreCase);
        public List<PurchaseOrderDetailDto> Details { get; set; } = new List<PurchaseOrderDetailDto>();
    }

    public class PurchaseOrderDetailDto
    {
        public Dictionary<string, object> Fields { get; set; } = new Dictionary<string, object>(StringComparer.OrdinalIgnoreCase);
    }
}
