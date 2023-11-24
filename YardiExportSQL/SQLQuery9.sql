


select m.WONumber, 
	case when min(wo.CompleteDate) < min(WODate) THEN min(wo.CompleteDate) ELSE min(WODate) END as DateOfSale
from tblMasterInventoryReview M
	left join tblImport_Inv_Yardi_WOItems wo on m.WONumber = wo.WONumber
	left join [dbo].[tblImport_Sortly] s on m.WONumber = s.WONumber_Calc
where wo.CompleteDate is not null and WODate is not null
group by m.WONumber


--select * from [tblImport_Sortly]
