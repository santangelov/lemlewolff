/* SUPPLIES Inventory Report - based on WO List Report */

Select  
rtrim(wo.sCode) as WONumber,
rtrim(p.sCode) as Property,
rtrim(u.sCode) as Unit,
wo.dtCall Call_Date,
wo.sBriefDesc Brief_Desc,
wod.dquan as Qty,
st.sCode as Stock,
wod.sdesc as StockDesc,
wod.dUnitPrice as UnitPrice,
wod.dPayAmt as PayAmt
From
MM2WO wo left outer join mm2wodet wod on (wo.hmy=wod.hWo)
left outer join mm2stock st on (wod.hStock = st.hMy)
left outer join Person ps on (wod.hPerson = ps.hMy)
left outer join property p on (wo.hProperty = p.hMy)
left outer join unit u on (wo.hUnit = u.hMy)
where 
	wo.sStatus in ('Work Completed')
    AND wo.sCode is not null -- WONumber
    AND wo.sCategory in ('Supplies')
    AND (year(wo.dtCall) = 2023 AND month(wo.dtCall) in (1,2,3,4,5,6)
		OR (year(wo.dtWCompl) = 2023))
order by wo.hMy
