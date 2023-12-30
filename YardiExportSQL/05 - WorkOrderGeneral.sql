/*  5 - Work Order Export to fill the General Work Order lookup table
		We always grab ALL Work orders in this select
*/

Select 
	rtrim(wo.sCode) as WONumber,
    wo.sStatus as JObStatus,
    wo.sCategory as Category,
	wo.dtWCompl as CompleteDate,
    wo.dtCall as CallDate,
    wo.dtSched as SchedDate,
    wo.hChgRcd as BatchID,
    wo.sBriefDesc as BriefDesc,
    wo.sExpenseType as ExpenseType,
    wo.dtDateIn as yardiCreateDate,
    wo.dtUpdatedt as yardiUpdatedDate    
From MM2WO wo
where wo.hVendor in (select hMyPerson from vendor where rtrim(ucode) in ('all2'))
	-- and wo.dtUpdatedt > '1/1/2023'
    -- and wo.sStatus not in ('Canceled')
order by wo.sCode

