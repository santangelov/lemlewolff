/*  PO INVENTORY LIST
*/
DECLARE @Date1 datetime = '1/01/2024'  -- inclusive
DECLARE @Date2 datetime = '2/19/2024'  -- not inclusive

Select 
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
     s.scode like ('__-%')
     and ltrim(rtrim(po.SEXPTYPE)) in ('Plumbing-Inventory','CoOp-Inventory','Boiler-Inventory','Maintenance-Inventory')
     and po.dtordereddate >= @Date1 and po.dtordereddate < @Date2
     --and dtOrderedDate > '1/1/2023'
     --and po.scode in (48543) -- PONumber
order by po.scode

