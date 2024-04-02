/*  PO INVENTORY LIST
*/
DECLARE @Date1 datetime = '1/01/2024'  -- inclusive
DECLARE @Date2 datetime = '4/1/2024'  -- not inclusive

Select 
      pod.hmy as YardiMM2PODetID,
      po.scode as PONumber, 	
      wo.scode as WONumber,
      v.uLastName as Vendor, 
      pod.iQtyOrdered as QtyOrdered,
	  po.SEXPTYPE as ExpenseType,
      pod.dUnitPrice as UnitPrice,
      pod.dTotalCost as TotalCost,
      po.dtordereddate as OrderDate,
      pod.dtReceivedDate as ReceivedDate,
      s.scode as ItemCode,
      pod.sDesc as ItemDesc,
      rtrim(ltrim(isnull(p.sAddr1,''))) + ', ' + rtrim(ltrim(isnull(p.sAddr2,''))) as Client
from mm2podet pod 
     left join mm2stock s on (pod.hStock = s.hMy)
     left join mm2po po   on (pod.hpo = po.hmy)     
     left join mm2wo wo   on (po.hWo=wo.hmy)
     left join vendor v   on (po.hVendor = v.hMyPerson)
     left join property p on (wo.hProperty = p.hMy)
where  
     (s.scode like ('material%') or s.scode like ('__-%'))   -- ItemCode = "Materials" end up in the Exception Table
     and ltrim(rtrim(po.SEXPTYPE)) in ('Plumbing-Inventory','CoOp-Inventory','Maintenance-Inventory')
     and pod.dtReceivedDate >= @Date1 and pod.dtReceivedDate < @Date2
order by po.scode

