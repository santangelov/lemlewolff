/*  5 - Work Order Export to fill the General Work Order lookup table
		We always grab ALL Work orders in this select
		
		1. Import file to tblWorkOrders_Staging
		2. Run spRptBuilder_WorkOrdersImport_01  --> Loads up tblWorkOrders
*/

Select 
	rtrim(wo.sCode) as WONumber,
	max(wo.dtWCompl) as CompleteDate
From
	MM2WO wo
    left join vendor v on (wo.hVendor = v.hMyPerson)
where 
	rtrim(v.uCode) = 'all2'
group by rtrim(wo.sCode)
order by rtrim(wo.sCode)
