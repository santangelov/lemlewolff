/*  1 - IMPORT WO LIST 	
	This was started from the WO LIST report in Yardi, and some fields were added from the DIRECTORY report in Yardi
	-- 7/16: added that Completion date is in 2023 (can add months later if needed) - this gets all jobs started in last year and ended this year
	-- 7/30: added Batch Dates (SDATEOCCURRED) - the other date that could be used but left off is trans.uPOSTDATE
*/

DECLARE @Date1 datetime = '1/1/2023'  -- inclusive
DECLARE @Date2 datetime = '12/30/2023'  -- not inclusive

Select 
	rtrim(wo.sCode) WONumber,
	rtrim(p.sCode) BuildingNum,
	rtrim(u.sCode) AptNum,
	wo.sStatus JobStatus,
	wo.sCategory Category, -- Division
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
    b.bDate as woBatchOccuredDate
From
	MM2WO wo left outer join mm2wodet wod on (wo.hmy=wod.hWo)
	left join mm2stock st on (wod.hStock = st.hMy)
	left join Person ps on (wod.hPerson = ps.hMy)
	left join property p on (wo.hProperty = p.hMy)
	left join unit u on (wo.hUnit = u.hMy)
	left join mmasset a on (wo.hasset = a.hMy)
	left join vendor v on (wo.hVendor = v.hMyPerson)
    left join trans t on wo.hChgRcd = t.hMy
    left join (select tr.HPARENT2, max(tr.SDATEOCCURRED) Bdate
			   from trans tr where tr.HPARENT2 <> 0 
               		and tr.SDATEOCCURRED >= @Date1
                    and tr.SDATEOCCURRED < @Date2
               group by tr.HPARENT2) b on wo.hchgrcd = b.HPARENT2 and wo.hchgrcd <> 0 
where 
	rtrim(v.ucode) in ('all2')
    -- CONDITIONS:  Call Date is in range OR Completion Date is in range OR the new Batch Date is in Range
	AND ( 
          (wo.dtCall >= @Date1 and wo.dtCall < @Date2)
          OR (wo.dtWCompl >= @Date1 and wo.dtWCompl < @Date2)
      	  OR (wo.scode in (   -- Not using the joined table [b] because it makes query too slow
            select distinct wo.sCode
            from trans tr inner join MM2WO wo on tr.HPARENT2 = wo.hchgrcd
            where tr.HPARENT2 <> 0 
                and tr.SDATEOCCURRED >= @Date1
                and tr.SDATEOCCURRED < @Date2)
            )
     	)
    --and rtrim(wo.sCode) in (428151)
--order by rtrim(wo.sCode)

