using System.Collections.Generic;

namespace LW_Data
{
    public class WorkOrderDto
    {
        public Dictionary<string, object> Fields { get; set; } = new Dictionary<string, object>();
        public List<PurchaseOrderDto> PurchaseOrders { get; set; }
    }
}
