/*  WO - Work Order Inventory
	-- These are the SALES (minus)
*/
DECLARE @Date1 datetime = '1/1/2024'  -- inclusive
DECLARE @Date2 datetime = '2/19/2024'  -- not inclusive

Select 
    rtrim(wo.sCode) as WONumber,
    wo.sCategory as Category,
    wo.sBriefDesc as BriefDesc,
    st.sCode as ItemCode,
    wod.sdesc as ItemDesc,
    wod.dquan as Qty,
    wod.dUnitPrice as UnitPrice,
    wod.dPayAmt as TotalAmt,
	wo.dtWCompl as CompleteDate,
    wo.sExpenseType as ExpenseType,
	rtrim(ltrim(p.sAddr1)) + ', ' + rtrim(ltrim(p.sAddr2)) as Client, 
    v.uLastName as Vendor
From
    MM2WO wo 
    left join mm2wodet wod on (wo.hmy=wod.hWo)
    left join mm2stock st on (wod.hStock = st.hMy)
    left join mmasset a on (wo.hasset = a.hMy)
    left join vendor v on (wo.hVendor = v.hMyPerson)
    left join property p on (wo.hProperty = p.hMy)
where 
	wo.sStatus in ('Work Completed')
    and wo.sCategory in ('Violation', 'Supplies', 'APH-Plumbing', 'Repairs', 'Plumbing', 'APH-Boiler')
    and wod.dquan is not null
    and wo.dtWCompl is not null
    and st.sCode like '__-%'
    and wo.dtWCompl >= @Date1 and wo.dtWCompl < @Date2
    --and wo.sCode = 477183
order by wo.hMy

