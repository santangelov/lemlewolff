
select 'ADP', min(paydate), max(paydate) from [dbo].[tblImport_ADP] 
select 'PO', min(CallDate), max(CallDate) from [dbo].[tblImport_Yardi_POs]
select 'WO', min(CallDate), max(CallDate) from [dbo].[tblImport_Yardi_WOList]
select 'SORTLY', min(WODate), max(WODate) from tblImport_Sortly