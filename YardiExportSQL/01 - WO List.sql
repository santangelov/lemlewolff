/*  1 - IMPORT WO LIST 	
	This was started from the WO LIST report in Yardi, and some fields were added from the DIRECTORY report in Yardi
	-- 7/16: added that Completion date is in 2023 (can add months later if needed) - this gets all jobs started in last year and ended this year
	-- 7/30: added Batch Dates (SDATEOCCURRED) - the other date that could be used but left off is trans.uPOSTDATE
*/
DECLARE @Date1 datetime = cast(format(dateadd(month, -8, getdate()), 'M/d/yyyy') as DateTime)  -- inclusive
DECLARE @Date2 datetime = cast(format(getdate(), 'M/d/yyyy') as DateTime)  -- not inclusive


Select 
	rtrim(wo.sCode) WONumber,
	rtrim(p.sCode) BuildingNum,
	rtrim(u.sCode) AptNum,
	wo.sStatus JobStatus,
	wo.sCategory Category, 
	wo.dtCall CallDate,
	wod.dtStart StartDate,
	wo.dtSched SchedDate,
    wo.hChgRcd as BatchID,
    t.sDateCreated as BatchDate,
	wo.dtWCompl CompleteDate,
	ps.ucode Employee,
	wo.sBriefDesc BriefDesc, -- RAD
	isnull(wod.dquan,0) Quantity,
	st.sCode [Code],
	wod.sdesc FullDesc,
	isnull(wod.dUnitPrice,0) UnitPrice,
	isnull(wod.dPayAmt,0) PayAmt,
    b.bDate as woBatchOccuredDate,  -- tblWorkOrders.TransBatchDate
	format(b.PostedMonth, 'yyyy-MM') as PostedMonth,
	@Date1 as Date1,
	@Date2 as Date2
From
	MM2WO wo 
    left join mm2wodet wod on (wo.hmy=wod.hWo)
	left join mm2stock st on (wod.hStock = st.hMy)
	left join Person ps on (wod.hPerson = ps.hMy)
	left join property p on (wo.hProperty = p.hMy)
	left join unit u on (wo.hUnit = u.hMy)
	left join mmasset a on (wo.hasset = a.hMy)
	left join vendor v on (wo.hVendor = v.hMyPerson)
    left join trans t on wo.hChgRcd = t.hMy
    left join (select HPARENT2, max(SDATEOCCURRED) Bdate, max(upostdate) as PostedMonth
			   from trans 
               where HPARENT2 <> 0 and SDATEOCCURRED >= @Date1 and SDATEOCCURRED < @Date2
               group by HPARENT2) b on wo.hchgrcd = b.HPARENT2 and isnull(wo.hchgrcd,0) <> 0   
WHERE 
	rtrim(v.ucode) in ('all2')
	AND ( 
          (wo.dtCall >= @Date1 and wo.dtCall < @Date2)
      	  OR (t.HPARENT2 in ( 
                select HPARENT2 FROM trans
                where SDATEOCCURRED >= @Date1 and SDATEOCCURRED < @Date2 and HPARENT2 <> 0 ))
		  OR (t.sDateCreated >= @Date1 and t.sDateCreated < @Date2)   -- Batch Date
          OR (wo.dtWCompl >= @Date1 and wo.dtWCompl < @Date2)
     	)
	-- AND rtrim(wo.sCode) in (475380)
