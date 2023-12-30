

select upper(lv.KeyString) as InventoryCategory, m.ItemCode, 
	max(m.ItemDesc) as Descripton, m.UnitPrice, 
	format(isnull(ReceivedDate, DateOfSale), 'yyyy-MM-dd') as ActionDate, 
	CASE WHEN isnull(m.WONumber,0) = 0 THEN NULL ELSE m.WONumber END as WONumber,
	m.PONumber, sum(m.Quantity) as Quantity,
	sum(isnull([Total],0)) as SumTotal,
	COALESCE(wor.Laborer1_Name, wor.POVendor, '') as Labor  -- Later add names to the tblWorkOrders table so we have full scope
from tblMasterInventoryReview m
	left join tblLookupValues lv on left(m.ItemCode,2) = cast(lv.keyValue as int)
	left join tblMasterWOReview wor on m.WONumber = wor.WONumber and m.WONumber not in (0)
where isnull(ReceivedDate, DateOfSale) is not null
group by lv.KeyString, ItemCode, isnull(ReceivedDate, DateOfSale), 
	unitprice, m.WONumber, m.PONumber,
	COALESCE(wor.Laborer1_Name, wor.POVendor, '')
order by ItemCode, Descripton, ActionDate