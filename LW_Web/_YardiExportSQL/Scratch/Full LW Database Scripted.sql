USE [lemlewolff]
GO
/****** Object:  View [dbo].[vwADPWOHoursByLaborer]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE   view [dbo].[vwADPWOHoursByLaborer]
AS

	select WONumber, LaborerID, sum([Hours]) sumAllHours
	from tblADP
	group by WONumber, LaborerID
GO
/****** Object:  View [dbo].[vwWorkOrderLaborers]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




-- select * from tblLaborers where laborerid in (46,48)
-- select * from [vwWorkOrderLaborers] where wonumber=489930

CREATE   view [dbo].[vwWorkOrderLaborers]
AS

	/*  BONUS
		Make it Zero if this is NULL. It becomes NULL if the denoiminator is Zero (which would be an error - NULLIF)
		Original Calculation: Laborer1_Bonus = isnull(CAST((isnull(FinalSalePrice,0)-isnull(TotalMaterialPricing,0)) * (isnull(l1.BonusFactor,0) / NullIf((isnull(l1.BonusFactor,0) + isnull(l2.BonusFactor,0) + isnull(l3.BonusFactor,0) + isnull(l4.BonusFactor,0)),0)) * @BonusPercent as decimal(10,2)),0),
		= (FinalSalePrice - TotalMaterialPricing) * (IndivBonusFactor / SumBonusFactors) * BonusPercent
	*/

	/* Later to speed this all up you may want to make a seperate View for calculating the Bonus */

	SELECT 
		a.WONumber,
		a.LaborerID,
		sum(CASE WHEN PayCode in ('REGULAR', 'REGSAL') THEN cast([Hours] as decimal(10,2)) else 0 end) as HrsReg,
		sum(CASE WHEN PayCode in ('OVERTIME') THEN			cast([Hours] as decimal(10,2)) else 0 end) as HrsOT,
		sum(CASE WHEN PayCode in ('REGULAR', 'REGSAL') THEN Dollars_Calculated else 0 end) as CostReg,
		sum(CASE WHEN PayCode in ('OVERTIME') THEN			Dollars_Calculated else 0 end) as CostOT,
		max(isnull(FinalSalePrice,0)) as FinalSalePrice,
		TotalMaterialPricing,
		isnull(l.BonusFactor,0) as BonusFactor,
		NullIf(bfTot.sumBonusFactorsForWO,0) as SumBonusFactor,
		cast((max(isnull(FinalSalePrice,0))-isnull(TotalMaterialPricing,0)) 
			* (isnull(l.BonusFactor,0) / nullif(sumBonusFactorsForWO,0)) 
			* (SELECT isnull(KeyValue,0) FROM tblLookupValues WHERE Category='Bonus' and KeyString = 'PercentOfSalePrice')
			as decimal(10,2)) 
				as BonusCalc
	from tblADP a 
		left join tblWorkOrders wo on a.WONumber = wo.WONumber
		left join tblLaborers l on a.LaborerID = l.LaborerID
		left join (
				select l.wonumber, sum(bonusFactor) as sumBonusFactorsForWO
				from vwADPWOHoursByLaborer l 
					inner join tblLaborers l2 on l.laborerid = l2.LaborerID
				group by l.wonumber) as bfTot on a.WONumber = bfTot.WONumber
	where a.LaborerID is not null 
		and isnull(a.WONumber,0) > 0
	group by a.WONumber, a.LaborerID, l.BonusFactor, bfTot.sumBonusFactorsForWO, 
		FinalSalePrice, TotalMaterialPricing, l.BonusFactor, sumBonusFactorsForWO

GO
/****** Object:  View [dbo].[vwWorkOrderLaborerNames]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





-- select * from vwWorkOrderLaborerNames where WONumber in (486129, 486137, 486494) 

CREATE view [dbo].[vwWorkOrderLaborerNames]
AS

	select WONumber,
		count(wonumber) as CountOfLaborers,
		STRING_AGG(l.FullName_Calc + (case when l.isSupervisor=1 then '*' else '' end) + ' (' + replace(cast(wol.HrsReg + wol.HrsOT as varchar(10)), '.00', '') + ')', '; ') WITHIN GROUP (ORDER BY l.isSupervisor desc, (wol.HrsReg + wol.HrsOT) desc) as LaborersAndHours,
		isnull(STRING_AGG(case when l.isSupervisor=1 then l.FirstName else NULL end, '+'),'') as SupervisorFirstNames
	from vwWorkOrderLaborers wol
		left join tblLaborers l on wol.LaborerID = l.LaborerID
	group by WONumber
GO
/****** Object:  View [dbo].[vwWOTeamGroups]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[vwWOTeamGroups]
AS

WITH LaborerMaxHours AS (
    SELECT laborerID, WONumber, SUM(ISNULL(HrsReg, 0) + ISNULL(HrsOT, 0)) AS MaxHours
    FROM vwWorkOrderLaborers
    GROUP BY laborerID, WONumber
),
RankedHours AS (
    SELECT 
        WONumber, 
        mh.LaborerID, 
        MaxHours, 
        ROW_NUMBER() OVER (PARTITION BY WONumber ORDER BY (l.isSupervisor) DESC, MaxHours DESC) AS rn
    FROM LaborerMaxHours mh
    LEFT JOIN tblLaborers l ON mh.laborerID = l.laborerID
)
SELECT 
	--wo.PostedMonth, l.FirstName, l.LastName, isnull(wo.category,'(blank)') as Category, 
	--sum(wo.InvoicePrice) as TotalInvoicePrice,
	wo.WONumber,
	case when l.firstname is null then 'n/a' else l.FirstName + ' ' + left(lastName,1) + './' + Category END as TeamGrouping
FROM 
	tblWorkOrders wo
    left join RankedHours rh on wo.WONumber = rh.WONumber
	LEFT JOIN tblLaborers l ON rh.laborerID = l.laborerID
WHERE 
    rn = 1
GROUP BY 
	wo.WONumber,
	wo.PostedMonth,
	l.FirstName, l.LastName,
	wo.category

GO
/****** Object:  View [dbo].[vwPO_GroupLaborMaterialsVendor]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




-- select * from [vwPO_GroupLaborMaterialsVendor] where WONumber=485197

CREATE view [dbo].[vwPO_GroupLaborMaterialsVendor]
AS

	SELECT 
		a.WONumber,
		MIN(CallDate) as CallDate,
		STRING_AGG(isnull(VendorName,''), '/') as VendorNames,
		min(InvoiceDate) as InvoiceDate,
		SUM(isnull(POAmount_Labor,0)) as POAmount_Labor,
		SUM(isnull(POAmount_Materials, 0)) as POAmount_Materials,
		SUM(LaborCost_Outside) as LaborCost_Outside,
		a.WOAndInvoiceAmt,
		NULL as LaborPricingOutside, -- Max(po.LaborPricingOutside); Should just be the marked up LaborCost - Re-Calculated in spRptBuilder_WOReview_06_Calcs
		(select string_agg(p.PONumber, '/') from (SELECT DISTINCT WONumber, PONumber FROM tblImport_Yardi_POs) as p where WONumber=a.WONumber group by WONumber) as PONumbers
	FROM
		(
			SELECT WONUmber, 
				CallDate, 
				lower(trim(po.VendorCode)) as VendorCode, 
				trim(po.VendorName) as VendorName, 
				min(InvoiceDate) as InvoiceDate,
				sum(case when AcctCategory='LABOR' then IndivPOTotal ELSE 0 END) as POAmount_Labor,				
				SUM(case when AcctCategory='LABOR' AND v.isSubcontractor=1 then IndivPOTotal ELSE 0 END) as LaborCost_Outside,	
				sum(case when AcctCategory='MATERIALS' then IndivPOTotal ELSE 0 END) as POAmount_Materials,
				Max(WOAndInvoiceAmt) as WOAndInvoiceAmt
			FROM tblImport_Yardi_POs  po
				left join tblVendors v on po.VendorCode = v.VendorCode
			WHERE PONumber is not null
				--AND WONumber=485197
			GROUP BY WONUmber, CallDate, po.VendorCode, po.VendorName
		) as a
	--WHERE WONumber=498109
	GROUP BY a.WONumber, WOAndInvoiceAmt
GO
/****** Object:  View [dbo].[vwPropertyUnitCount]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[vwPropertyUnitCount] AS

	SELECT 
		p.yardiPropertyRowID, 
		count(p.yardiPropertyRowID) as unitCount
	FROM dbo.tblProperties p
		inner join tblpropertyunits u on p.yardiPropertyRowID = u.yardiPropertyRowID
	WHERE 
		(isnull(u.unitTypeDesc,'') = '' or u.unitTypeDesc not in ('Mercantile','Misc','Miscellaneous','error','Parking'))
	GROUP BY 
		p.yardiPropertyRowID
GO
/****** Object:  View [dbo].[vwUnitOccupancy]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


--alter table [dbo].[tblPropertyUnits]
--drop column [yearsOccupied]
--go


CREATE view [dbo].[vwUnitOccupancy]
AS

	select 
		u.yardiUnitRowID, 
		CASE u.StatusBasedOnDates
			WHEN 'Occupied' THEN cast(round(datediff(day,[LastMoveInDate],getdate())/(365.25),(2)) as decimal(10,2))
			WHEN 'Vacant'   THEN cast(round(datediff(day,[LastMoveInDate],[LastMoveOutDate])/(365.25),(2)) as decimal(10,2))
			ELSE NULL
		END as yearsOccupied,
		CASE u.StatusBasedOnDates
			WHEN  'Occupied' THEN 'Current Occupancy Length' 
			WHEN  'Vacant' THEN 'Last Occupancy'
			WHEN  NULL THEN 'NO Occupancy on Record'
		END as yearsOccupied_Note
	from tblPropertyUnits u

GO
/****** Object:  View [dbo].[vwWO_DistinctWOs]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create view [dbo].[vwWO_DistinctWOs]
AS

	select 
		wo.WONumber, 
		MIN(wo.CallDate) as CallDate
	from tblImport_Yardi_WOList wo
	GROUP BY wo.WONumber
GO
/****** Object:  StoredProcedure [dbo].[spADP]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








CREATE PROCEDURE [dbo].[spADP]
	@ADPRowID int = NULL
AS
BEGIN

	SELECT * 
	FROM tblADP i 
	where 
		(@ADPRowID is null or (@ADPRowID is not null and @ADPRowID = i.ADPRowID))

END
GO
/****** Object:  StoredProcedure [dbo].[spADP_MissingFromAnalysisReport]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


--[spADP_MissingFromAnalysisReport] '1/1/2024', '2/1/2024'

CREATE   procedure [dbo].[spADP_MissingFromAnalysisReport] 
	@date1 datetime = NULL,
	@date2 datetime = NULL
AS
BEGIN

	select 
		adp.WONumber, CompanyCode, PayrollName, FileNumber, 
		convert(varchar(20), PayDate, 101) as PayDate, [Hours], Dollars
	from tblADP adp
		left join tblWorkOrders vw on adp.WONumber = vw.WONumber
	where
		vw.WONumber is null  -- ADP WO not in our list
		and isnull(adp.WONumber,'') > ''
		and adp.PayDate >= @date1 and adp.PayDate < @date2
	order by adp.WONumber, PayrollName, PayDate

END
GO
/****** Object:  StoredProcedure [dbo].[spADPUpdate]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







CREATE PROCEDURE [dbo].[spADPUpdate]
	@ADPRowID int = NULL,
	@CompanyCode varchar(50) = NULL,
	@LaborerID int = NULL,
	@PayrollName varchar(100) = NULL,
	@FileNumber varchar(50) = NULL,
	@TimeIn DateTime = NULL,
	@TimeOut DateTime = NULL,
	@Location varchar(10) = NULL,
	@WONumber varchar(10) = NULL,
	@Department varchar(50) = NULL,
	@PayDate DateTime = NULL,
	@PayCode varchar(50) = NULL,
	@Hours Decimal(5,3) = NULL,
	@Dollars Decimal(10,2) = NULL,
	@TimeDescription varchar(400) = NULL,
	@WODescription varchar(400) = NULL,
	@Createdby varchar(20) = NULL,
	@CreateDate DateTime = getdate,
	@isLockedForUpdates bit = 0,

	@NoReturn bit = 0,  -- 0=Return a row of the inserted or updated data; 1=Return nothing
	@allowUpdateOfLockedRows bit = 0
AS
BEGIN
	/* Only insert the row if it does not already exist. The unique columns should be 
		PayrollName, TimeIn, [TimeOut], WONumber, PayDate, PayCode,
	*/
	DECLARE @ADPRowID_Existing int = NULL

	-- Clean up any weird WO Numbers that get passed in (Remove .00 and commas before converting to integer
	SELECT @WONumber = cast(cast(replace(replace(@WONumber,'.00',''),',','') as integer) as varchar(10))

	IF @ADPRowID is NULL /* Find if there already exists this row matching most columns and then update it instead */
		SELECT TOP 1 @ADPRowID_Existing=ADPRowID 
		FROM tblADP
		where 
			PayrollName = @PayrollName 
			AND CompanyCode = @CompanyCode  -- Company Code no necessary, but just extra insurance
			AND [TimeIn] = @TimeIn  -- NOTE: we are seeing time adjustments and we end up taking them as a new row (TimeIn and TimeOut)
			AND [TimeOut] = @TimeOut 
			AND WONumber = @WONumber 
			AND PayDate = @PayDate 
			AND PayCode = @PayCode


	IF isnull(@ADPRowID,0) > 0 or isnull(@ADPRowID_Existing,0) > 0
		UPDATE tblADP Set 
			CompanyCode = @CompanyCode,
			LaborerID = @LaborerID,
			PayrollName = @PayrollName,
			FileNumber = @FileNumber,
			TimeIn = @TimeIn,
			[TimeOut] = @TimeOut,
			[Location] = @Location,
			WONumber = @WONumber,
			Department = @Department,
			PayDate = @PayDate,
			PayCode = @PayCode,
			[Hours] = @Hours,
			Dollars = @Dollars,
			TimeDescription = @TimeDescription,
			WODescription = @WODescription,
			CreatedBy = @CreatedBy,
			CreateDate = @CreateDate,
			isLockedForUpdates = @isLockedForUpdates
		WHERE 
			(isnull(@ADPRowID,0) > 0 and ADPRowID=@ADPRowID
			or isnull(@ADPRowID_Existing,0) > 0 and ADPRowID=@ADPRowID_Existing)
			and (@allowUpdateOfLockedRows=1 or @allowUpdateOfLockedRows=0 and isLockedForUpdates=0)


	IF isnull(@ADPRowID,0) = 0 and isnull(@ADPRowID_Existing,0) = 0 
		BEGIN
			-- Only insert if there is not already a duplicate row
			INSERT INTO tblADP(CompanyCode, LaborerID, PayrollName, FileNumber, TimeIn, [TimeOut], [Location], WONumber, Department, PayDate, PayCode, [Hours], Dollars, TimeDescription, WODescription, CreatedBy, CreateDate, isLockedForUpdates ) 
			SELECT @CompanyCode, @LaborerID, @PayrollName, @FileNumber, @TimeIn, @TimeOut, @Location, @WONumber, @Department, @PayDate, @PayCode, @Hours, @Dollars, @TimeDescription, @WODescription, @CreatedBy, @CreateDate, @isLockedForUpdates
			where NOT EXISTS (select ADPRowID from tblADP where 
				PayrollName = @PayrollName 
				AND CompanyCode = @CompanyCode  -- Company Code no necessary, but just extra insurance
				AND TimeIn = @TimeIn 
				AND [TimeOut] = @TimeOut 
				AND WONumber = @WONumber 
				AND PayDate = @PayDate 
				AND PayCode = @PayCode)

			SELECT @ADPRowID = SCOPE_IDENTITY()
		END

	IF @ADPRowID is null and @ADPRowID_Existing is not null
		SELECT @ADPRowID = @ADPRowID_Existing

	IF @NoReturn = 0 EXEC dbo.spADP @ADPRowID=@ADPRowID

END
GO
/****** Object:  StoredProcedure [dbo].[spBonusReport]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








--  spBonusReport '11/1/2024', '12/2/2024'

CREATE   procedure [dbo].[spBonusReport]
	@Date1 as DateTime = NULL,
	@Date2 as DateTime = NULL
AS
BEGIN
	IF OBJECT_ID('tempdb..#tmpJobs', 'U') IS NOT NULL DROP TABLE #tmpJobs;

	/* Make alterations & corrections */
	--update tblWorkOrders set Category='APH-Plumbing' where WONumber in (490659, 489572)  -- Remming out becuase we don't want to update this every time - but it should be this way and might get reverted

	/* DO SELECTION */
	select 
		xl.WONumber,
		w2.PostedMonth,
		l.FullName_Calc as LaborerName, 
		case when isnull(xl.FinalSalePrice,0) - isnull(xl.TotalMaterialPricing,0) = 0 then 
				0.00 
			else 
				cast((Laborer_Bonus / (xl.FinalSalePrice - isnull(xl.TotalMaterialPricing,0)) * 100) as decimal(10,2)) 
			end as ThePercentage,
		Laborer_Bonus,
		isnull(xl.FinalSalePrice,0) as FinalSalePrice,

		cast(
				xl.FinalSalePrice *
					(
						case when isnull(xl.FinalSalePrice,0) - isnull(xl.TotalMaterialPricing,0) = 0 then 
							0.00 
						else 
							cast((Laborer_Bonus / (xl.FinalSalePrice - isnull(xl.TotalMaterialPricing,0)) * 100) as decimal(10,2)) 
						end -- ThePercentage
					) / 100
				as decimal(10,2) -- CAST
			)
			as CheckCalc, 

		isnull(xl.TotalMaterialPricing,0) as TotalMaterialPricing
	into #tmpJobs
	FROM (
			select wo.WONumber, LaborerID, BonusCalc as Laborer_Bonus, wol.FinalSalePrice, wol.TotalMaterialPricing 
			from tblWorkOrders wo 
				INNER JOIN vwWorkOrderLaborers wol ON wo.WONumber = wol.WONumber
		) as xl
		left join tblLaborers l on xl.LaborerID = l.LaborerID
		left join tblWorkOrders w2 on xl.WONumber = w2.WONumber
	WHERE 
		isnull(l.BonusFactor,0) > 0 
		and xl.WONumber in 
			(
			select distinct wo.WONumber 
			from tblWorkOrders wo
				INNER JOIN vwWorkOrderLaborers wol ON wo.WONumber = wol.WONumber
			where 
				(@Date1 is null or (@Date1 is not null and (PostedMonth >= FORMAT(cast(@Date1 as DateTime), 'yyyy-MM') and PostedMonth <= FORMAT(cast(@Date2 as DateTime), 'yyyy-MM'))))
			)
		--and xl.WONumber in (486342)

	/* Bonus Results Table */
	select * 
	from #tmpJobs j
	order by WONumber, LaborerName

	/* Totals Table */
	select LaborerName, 
		sum(Laborer_Bonus) as LaborerBonus, 
		sum(FinalSalePrice) as SumFinalSalePrice, 
		sum(TotalMaterialPricing) as SumTotalMaterialPricing,
		sum(Laborer_Bonus) * (1 - sum(TotalMaterialPricing)/sum(FinalSalePrice)) as Invoice_x_Material
	from #tmpJobs j
	group by LaborerName
	order by LaborerName

	/* Clean up */
	drop table #tmpJobs


END
GO
/****** Object:  StoredProcedure [dbo].[spImport_Delete]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








--spImport_Delete @FileType='master'

CREATE   procedure [dbo].[spImport_Delete]
	@FileType varchar(50) = NULL
AS
BEGIN

	IF @FileType = 'Sortly'				DELETE FROM tblImport_Sortly
	--ELSE IF @FileType = 'ADP'			DELETE FROM tblImport_ADP  --- We don't need to ever delete from this table now - do it manually if need be
	ELSE IF @FileType = 'YardiWO'		DELETE FROM tblImport_Yardi_WOList
	ELSE IF @FileType = 'YardiPO'		DELETE FROM tblImport_Yardi_POs
	--ELSE IF @FileType = 'master'		DELETE FROM tblMasterWOReview
	ELSE IF @FileType in ('YardiWO2','InventoryWO')	DELETE FROM tblImport_Inv_Yardi_WOItems
	ELSE IF @FileType in ('YardiPO2','InventoryPO')	DELETE FROM tblImport_Inv_Yardi_POItems
	ELSE IF @FileType in ('MasterInv')	DELETE FROM tblMasterInventoryReview where isSeedItem=0
	--ELSE IF @FileType = 'MasterInv-All'	DELETE FROM tblMasterInventoryReview

END
GO
/****** Object:  StoredProcedure [dbo].[spImportDates]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE procedure [dbo].[spImportDates]
	@DateKey varchar(25) = NULL
AS

SELECT * FROM
	(select * from tblImportDates

	UNION

	select 
		'ADP' as DateKey, 
		min(PayDate) as LatestImportDateRage_Date1,
		max(PayDate) as LatestImportDateRage_Date2,
		max(CreateDate) as UpdateDate
	FROM tblADP) as importDates
WHERE @DateKey is null or (@DateKey is not null and DateKey = @DateKey)

GO
/****** Object:  StoredProcedure [dbo].[spImportDatesUpdate]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE procedure [dbo].[spImportDatesUpdate]
	@DateKey varchar(25),
	@LatestImportDateRange_Date1 DateTime = null,
	@LatestImportDateRange_Date2 DateTime
AS

IF (SELECT COUNT(*) FROM tblImportDates WHERE DateKey = @DateKey) = 1 
	BEGIN
		UPDATE tblImportDates Set
			DateKey = @DateKey,
			LatestImportDateRange_Date1 = @LatestImportDateRange_Date1,
			LatestImportDateRange_Date2 = @LatestImportDateRange_Date2,
			UpdateDate = getdate()
		WHERE DateKey = @DateKey
			and LatestImportDateRange_Date2 < @LatestImportDateRange_Date2
	END
ELSE
	BEGIN
		INSERT INTO tblImportDates(DateKey, LatestImportDateRange_Date1, LatestImportDateRange_Date2, UpdateDate)
		VALUES(@DateKey, @LatestImportDateRange_Date1, @LatestImportDateRange_Date2, getdate())
	END

SELECT * FROM tblImportDates WHERE DateKey = @DateKey
GO
/****** Object:  StoredProcedure [dbo].[spPhysicalInventoryUpdate]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--spPhysicalInventoryUpdate @PIRowID=607, @AsOfDate='2024-09-30 00:00:00.000', @Code='10-00100', 
--	@Description='Adhesive Glue VCT 1 gallon',
--	@PhysicalCount=0,
--	@ModDate=NULL,
--	@Modby=NULL


CREATE PROCEDURE [dbo].[spPhysicalInventoryUpdate]
	@PIRowID int = NULL,
	@AsOfDate datetime = NULL,
	@Code varchar(10) = NULL,
	@Description varchar(250) = NULL,  -- (Optional) NULL = do not update this field
	@PhysicalCount int = NULL,
	@CreateDate datetime = NULL,
	@Createdby varchar(25) = NULL,
	@ModDate datetime = NULL,
	@ModBy varchar(25) = NULL,

	@NoReturn bit = 0  -- 0=Return a row of the inserted or updated data; 1=Return nothing
AS
BEGIN
	-- If the Count passed in is NULL then do nothing. This is different form it being set to 0
	IF @PhysicalCount is null return
	if (@Description ='') SELECT @Description = null

	-- Insert unless there is a duplicate - then remove the duplicate and insert the new row
	IF @PIRowID is NULL 
		BEGIN
			-- Grab a decription if the passed in description is blank (from past table entries, or the inventory table)
			DECLARE @AltDescription varchar(250) = NULL
			
			SELECT TOP 1 @AltDescription = COALESCE(@Description, phi.[Description], i.itemName, pp.[Description])  
				FROM tblPhysicalInventory phi 
					left join tblSortlyInventory i on phi.Code = i.ItemCode
					left join tblPhysicalInventory pp on pp.Code = phi.Code and isnull(pp.[Description],'') <> ''
				WHERE phi.Code=@Code 
				ORDER BY phi.PIRowID desc

			-- if the EXACT row already exists then do not import it
			IF (SELECT COUNT(*) FROM tblPhysicalInventory WHERE AsOfDate=@AsOfDate and Code=@Code and [Description] = @AltDescription) > 0 Return

			-- Remove any rows that would be duplicates
			DELETE FROM tblPhysicalInventory WHERE AsOfDate=@AsOfDate and Code=@Code

			INSERT INTO tblPhysicalInventory(Code, PhysicalCount, [Description], AsOfDate, createdBy, createDate)
			VALUES(@Code, @PhysicalCount, @AltDescription, @AsOfDate, @Createdby, isnull(@CreateDate, getdate()))

			SELECT @PIRowID = SCOPE_IDENTITY()
		END
	ELSE
		BEGIN
			UPDATE tblPhysicalInventory
				Set AsOfDate = @AsOfDate,
				Code = @Code,
				[Description] = case when isnull(@Description,'')  = '' then [Description] else @Description END,
				PhysicalCount = @PhysicalCount,
				modBy = @Modby,
				modDate = isnull(@ModDate, getdate())
			WHERE PIRowID = @PIRowID
		END

	IF @NoReturn = 0 SELECT * FROM tblPhysicalInventory WHERE PIRowID = @PIRowID

END
GO
/****** Object:  StoredProcedure [dbo].[spPOInventoryItemReport]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





-- spPOInventoryItemReport '1/1/2024', '9/16/2024'

CREATE procedure [dbo].[spPOInventoryItemReport]
	@Date1 as DateTime = NULL,
	@Date2 as DateTime = NULL
AS 
BEGIN

	select 
		po.PONumber,
		po.WONumber,
		po.expenseType,
		po.VendorName,
		pod.QTYOrdered,
		pod.UnitPrice,
		pod.OrderDate,
		pod.ReceivedDate,
		pod.ItemCode,
		pod.ItemDesc
	from tblPurchaseOrders_Details pod 
		left join tblPurchaseOrders po on pod.PONumber = po.PONumber
	where 
		--pod.ReceivedDate is not null -- Only reporting on materials recieved
		po.OrderDate >= @Date1 and po.OrderDate < @Date2

	order by po.PONumber, po.OrderDate

END

GO
/****** Object:  StoredProcedure [dbo].[spPropertyUnitUpdate]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE     PROCEDURE [dbo].[spPropertyUnitUpdate]
	@yardiUnitRowID int = NULL,  -- To update pass in RowID from Yardi - always required
	@yardiPropertyRowID int = NULL,
	@AptNumber varchar(25) = NULL,
	@Bedrooms int = 0,
	@rent decimal(10,2) = NULL,
	@SqFt decimal(10,2) = NULL,
	@UnitStatus varchar(50) = NULL,
	@LastMoveInDate DateTime = NULL,
	@LastMoveOutDate DateTime = NULL,
	@isExcluded bit = 0,
	@LastTenantRent decimal(10,2) = NULL,
	@unitTypeDesc varchar(20) = NULL
AS
BEGIN
	IF (@yardiPropertyRowID is null or @yardiUnitRowID is null) return -1  -- these are required

	IF NOT EXISTS (SELECT 1 FROM tblPropertyUnits WHERE yardiUnitRowID = @yardiUnitRowID)
		BEGIN
			INSERT INTO tblPropertyUnits
			(yardiPropertyRowID, yardiUnitRowID, AptNumber, Bedrooms, rent, SqFt, UnitStatus, LastMoveInDate, LastMoveOutDate, modDate, createDate, isExcluded, LastTenantRent, unitTypeDesc )
			VALUES(@yardiPropertyRowID, @yardiUnitRowID, @AptNumber, @Bedrooms, @rent, @SqFt, @UnitStatus, @LastMoveInDate, @LastMoveOutDate, getdate(), getdate(), @isExcluded, @LastTenantRent, @unitTypeDesc)
		END
	ELSE IF @yardiUnitRowID is not null
		BEGIN
			UPDATE tblPropertyUnits Set 
				yardiUnitRowID = @yardiUnitRowID,
				yardiPropertyRowID = @yardiPropertyRowID,
				AptNumber = @AptNumber,
				Bedrooms = @Bedrooms,
				rent = @rent,
				SqFt = @SqFt,
				UnitStatus = @UnitStatus,
				LastMoveInDate = @LastMoveInDate,
				LastMoveOutDate = @LastMoveOutDate,
				isExcluded = @isExcluded,
				modDate = getdate(),
				LastTenantRent = @LastTenantRent,
				unitTypeDesc = @unitTypeDesc
		
			WHERE 
				yardiUnitRowID=@yardiUnitRowID
				AND (
					yardiPropertyRowID <> @yardiPropertyRowID
					or AptNumber <> @AptNumber
					or Bedrooms <> @Bedrooms
					or rent <> @rent
					or SqFt <> @SqFt
					or UnitStatus <> @UnitStatus
					or isnull(LastMoveInDate,'1/1/1900') <> isnull(@LastMoveInDate,'1/1/1900')
					or isnull(LastMoveOutDate,'1/1/1900') <> isnull(@LastMoveOutDate,'1/1/1900')
					or isExcluded <> @isExcluded
					or isnull(LastTenantRent,0) <> isnull(@LastTenantRent,0)
					or isnull(unitTypeDesc,'') <> isnull(@unitTypeDesc,'')
				)

		END

END
GO
/****** Object:  StoredProcedure [dbo].[spPropertyUpdate]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE     PROCEDURE [dbo].[spPropertyUpdate]
	@yardiPropertyRowID int = NULL, -- KEY value to update rows - required always, even on INSERTS because this comes from Yardi
	@buildingCode varchar(20) = NULL,
	@addr1_Co varchar(75) = NULL,
	@addr2 varchar(75) = NULL,
	@addr3 varchar(75) = NULL,
	@addr4 varchar(75) = NULL,
	@city varchar(75) = NULL,
	@stateCode varchar(2) = NULL,
	@zipCode varchar(10) = NULL,
	@isInactive bit = 0,
	@inactiveDate datetime = NULL
AS
BEGIN

	IF @buildingCode is null return -1
	if @yardiPropertyRowID is null return -1

	IF @yardiPropertyRowID not in (SELECT yardiPropertyRowID FROM tblProperties)
		BEGIN
			INSERT INTO tblProperties
			( yardiPropertyRowID, buildingCode, addr1_Co, addr2, addr3, addr4, city, stateCode, zipCode, isInactive, inactiveDate )
			VALUES( @yardiPropertyRowID, @buildingCode, @addr1_Co, @addr2, @addr3, @addr4, @city, @stateCode, @zipCode, @isInactive, @inactiveDate )

			SELECT @yardiPropertyRowID = SCOPE_IDENTITY()
		END
	ELSE IF (isnull(@yardiPropertyRowID,0) > 0)
		BEGIN
			UPDATE tblProperties Set 
				yardiPropertyRowID = @yardiPropertyRowID,
				buildingCode = @buildingCode,
				addr1_Co = @addr1_Co,
				addr2 = @addr2,
				addr3 = @addr3,
				addr4 = @addr4,
				city = @city,
				stateCode = @stateCode,
				zipCode = @zipCode,
				ModDate = getdate(),
				isInactive = @isInactive,
				inactiveDate = @inactiveDate
			WHERE 
				yardiPropertyRowID = @yardiPropertyRowID
				AND (
					buildingCode <> @buildingCode
					or addr1_Co <> @addr1_Co
					or addr2 <> @addr2
					or addr3 <> @addr3
					or addr4 <> @addr4
					or city <> @city
					or stateCode <> @stateCode
					or zipCode <> @zipCode
					or isInactive <> @isInactive
					or inactiveDate <> @inactiveDate
				)
		END

END
GO
/****** Object:  StoredProcedure [dbo].[spPurchaseOrders_Import]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE procedure [dbo].[spPurchaseOrders_Import]
AS

/* UPDATE existing ones from tblImport_Yardi_POs */
UPDATE tblPurchaseOrders 
	set PONumber = i.PONumber, WONumber = i.WONumber, CallDate = i.CallDate, VendorCode = i.VendorCode, VendorName = i.VendorName,
		expenseType = i.expenseType, POAmount = i.POAmount, WOAndInvoiceAmt = i.WOAndInvoiceAmt
FROM 
	tblPurchaseOrders po inner join tblImport_Yardi_POs i on po.PONumber = i.PONumber
WHERE 
	po.CallDate <> i.CallDate
	or po.VendorCode <> i.VendorCode
	or po.VendorName <> i.VendorName
	or po.expenseType <> i.expenseType
	or po.POAmount <> i.POAmount
	or po.WOAndInvoiceAmt <> i.WOAndInvoiceAmt


/* Insert new ones from tblImport_Yardi_POs */
INSERT INTO tblPurchaseOrders (PONumber, WONumber, CallDate, VendorCode, VendorName,
		expenseType, POAmount, WOAndInvoiceAmt)
	select 
		PONumber, WONumber, CallDate, VendorCode, VendorName,
		expenseType, POAmount, WOAndInvoiceAmt
	from tblImport_Yardi_POs
	where ponumber not in (select ponumber from tblPurchaseOrders)
	group by 	
		PONumber, WONumber, CallDate, VendorCode, VendorName,
		expenseType, POAmount, WOAndInvoiceAmt

/* Update the tblWorkOrders table with Vendor names from POs - these are the Externals */
UPDATE tblWorkOrders SET POVendors = a.Vendors
FROM tblWorkOrders wo 
	inner join (
		select wonumber, STRING_AGG(VendorName, '; ') as Vendors
		from (select distinct wonumber, vendorname from tblPurchaseOrders) as aa
		where aa.WONumber in (select wonumber from tblWorkorders)
		group by wonumber) as a on wo.WONumber = a.WONumber
WHERE wo.POVendors is null
GO
/****** Object:  StoredProcedure [dbo].[spRptBuilder_Inventory_01_Import]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








/* ====================================== 
-- WO = Sales
-- PO = Costs
-- Sortly = Sales

	-- Removed Unit Prices from being imported from the WO and PO exports from Yardi. All UnitPrices come from sortly now

 ====================================== */

CREATE         procedure [dbo].[spRptBuilder_Inventory_01_Import]
AS

/* INSERT INTO THE REPORTING TABLE */
------------------------------------------
--DELETE FROM tblMasterInventoryReview WHERE isSeedItem=0

/* Update Sortly inventory table */
EXEC spSortlyFillInventoryTable    --- Keeps a list of all inventory iems from sortly with names and unit prices


/* PO Items */
------------------------------------------

	INSERT INTO tblInventoryTracking 
		([Source], [ItemCode], [ItemDesc], WONumber, PONumber, Quantity,UnitPrice, Total, 
		ReceivedDate, Category, ExpenseType, Vendor, Client, DateOfSale)
	SELECT 'PO' as [Source], 
		po.ItemCode, 
		left(po.ItemDesc,75) as ItemDesc, 
		po.WONumber, 
		po.PONumber, 
		QtyOrdered as Quantity, 
		po.UnitPrice, 
		TotalCost as Total,
		po.ReceivedDate,   -- Only taken from Yardi POs
		wo.Category, 
		po.ExpenseType,
		po.Vendor,
		po.Client,
		po.ReceivedDate as DateOfSale
	FROM [dbo].[tblImport_Inv_Yardi_POItems] po
		LEFT JOIN (select WONumber, min(Category) as Category from [tblImport_Inv_Yardi_WOItems] group by wonumber) WO on po.WONumber = wo.WONumber
		LEFT JOIN tblInventoryTracking t on 
				po.ItemCode = t.itemcode 
				and isnull(po.PONumber,-1) = isnull(t.PONumber,-1)
				and isnull(po.WONumber,-1) = isnull(t.WONumber,-1)
				and t.Source = 'PO'
	WHERE 
		po.ItemCode is NOT NULL 
		AND po.ItemCode like ('__-%')
		AND T.ItemCode is null

	/* Update any details that have changes but are already in tblInventoryTracking */
	UPDATE tblInventoryTracking
		set Quantity = imp.QtyOrdered,
			Total = imp.TotalCost,
			ReceivedDate = imp.ReceivedDate,
			DateOfSale = imp.ReceivedDate,
			ExpenseType = imp.ExpenseType,
			Vendor = imp.Vendor,
			Client = imp.Client
	FROM tblInventoryTracking it
		inner join tblImport_Inv_Yardi_POItems imp on it.PONumber = imp.PONumber and it.ItemCode = imp.ItemCode
	WHERE it.[Source] = 'PO' 
		and (it.Quantity <> imp.qtyOrdered
			or it.Total <> imp.totalCost
			or isnull(it.ReceivedDate,'1/1/1900') <> isnull(imp.ReceivedDate,'1/1/1900')
			or isnull(it.DateOfSale,'1/1/1900') <> isnull(imp.ReceivedDate,'1/1/1900')
			or isnull(it.ExpenseType,'') <> isnull(imp.ExpenseType,'')
			or isnull(it.Vendor,'') <> isnull(imp.vendor,'')
			or isnull(it.Client,'') <> isnull(imp.Client,'')
		)

/* UPDATE tblPurchaseOrders with new POs */
insert into tblPurchaseOrders(ponumber, wonumber, vendorname, OrderDate, ReceivedDate, expenseType, TotalCostOfItems)
select i.PONumber, 
	WONumber, 
	Vendors, 
	min(OrderDate) as MinOrderDate, 
	min(ReceivedDate) as MinReceivedDate, 
	ExpenseType, 
	sum(TotalCost) as TotalCostsOfItems -- inlcudes all meterials and COGS
from tblImport_Inv_Yardi_POItems i
	inner join (select ponumber, string_agg(Vendor, ' / ') as Vendors from (select distinct ponumber, vendor from tblImport_Inv_Yardi_POItems) a group by ponumber) v
		on i.PONumber = v.PONumber
where i.PONumber not in (select ponumber from tblPurchaseOrders)
group by i.PONumber, WONumber, Vendors, ExpenseType
ORDER BY PONumber
	

/* WO Items.  Quantity is MINUS (qty x -1) */
------------------------------------------
	INSERT INTO tblInventoryTracking 
		([Source], [ItemCode], [ItemDesc], WONumber, Quantity, Category, Vendor, Client, DateOfSale)
	select 'WO' as [Source], 
		i.ItemCode, 
		left(i.ItemDesc,75) as ItemDesc, 
		i.WONumber, 
		isnull(i.Qty,0) * -1 as Quantity, 
		i.Category,
		i.Vendor,
		i.Client,
		i.CompleteDate
	from [dbo].[tblImport_Inv_Yardi_WOItems] i
		LEFT JOIN tblInventoryTracking t on 
				i.ItemCode = t.itemcode 
				and isnull(i.WONumber,-1) = isnull(t.WONumber,-1)
				and isnull(i.Vendor,'') = isnull(t.Vendor,'')
				and t.Source = 'WO'
	WHERE 
		i.ItemCode is not null 
		and i.ItemCode like ('__-%')
		and t.itemcode is null


	UPDATE tblInventoryTracking
		Set Quantity = isnull(i.qty,0) * -1,
			Category = i.category,
			Client = i.Client,
			DateOfSale = i.CompleteDate
	FROM tblInventoryTracking it
		inner join tblImport_Inv_Yardi_WOItems i on it.WONumber = i.WONumber and it.itemcode = i.itemcode
	WHERE 
		it.Source = 'WO'
		and (
			it.Quantity <> isnull(i.qty,0) * -1
			or it.Category <> i.Category
			or it.Client <> i.Client
			or isnull(it.DateOfSale,'1/1/1900') <> isnull(i.CompleteDate, '1/1/1900')
		)


/* SORTLY */
------------------------------------------

INSERT INTO tblInventoryTracking 
    ([Source], [ItemCode], [ItemDesc], WONumber, Quantity, DateOfSale, ReceivedDate)
SELECT 
    'Sortly' AS [Source], 
    i.Notes AS ItemCode, 
    LEFT(i.ItemName, 75) AS ItemDesc, 
    i.WONumber_Calc AS WONumber, 
    ISNULL(i.Quantity, 0) * -1 AS Quantity,
    CASE 
        WHEN ISNULL(w.DateOfSale, '1900-01-01') <> ISNULL(i.WODate, '1900-01-01') AND w.DateOfSale IS NOT NULL 
        THEN w.DateOfSale 
        ELSE i.WODate 
    END AS DateOfSale, 
    i.WODate AS ReceivedDate
FROM 
    [dbo].[tblImport_Sortly] i
LEFT JOIN 
    tblWorkOrders w ON i.WONumber_Calc = w.WONumber
WHERE 
    i.Notes IS NOT NULL 
	AND i.Notes LIKE ('__-%')
	AND i.PrimaryFolder like '%Today%Work Orders%'
    AND NOT EXISTS (
        SELECT 1
        FROM tblInventoryTracking t
        WHERE 
            ISNULL(t.ItemCode, '') = ISNULL(i.Notes, '') 
            AND ISNULL(t.WONumber, -1) = ISNULL(i.WONumber_Calc, -1)
            AND t.Source = 'Sortly'
    )



/*  MAKE ANY UPDATES */
------------------------------------------
UPDATE tblInventoryTracking
	Set Quantity = isnull(i.Quantity,0) * -1,
		DateOfSale = case when isnull(w.DateOfSale,'1/1/1900') <> isnull(i.WODate,'1/1/1900') and w.DateOfSale is not null THEN w.DateOfSale ELSE i.WoDate END,
		ReceivedDate = i.WODate
FROM [dbo].[tblImport_Sortly] i
	LEFT JOIN tblWorkOrders w on i.WONumber_Calc = w.WONumber
	LEFT JOIN tblInventoryTracking t on 
			i.Notes = t.itemcode 
			and i.WONumber_Calc = isnull(t.WONumber,-1)
			and t.Source = 'Sortly'
WHERE 
	i.Notes is not null 
	and i.Notes like ('__-%')
	and i.PrimaryFolder like '%Today%Work Orders%'
	and (
		isnull(t.Quantity,0) <> isnull(i.Quantity,0) * -1
		or isnull(t.DateOfSale,'1/1/1900') <> case when isnull(w.DateOfSale,'1/1/1900') <> isnull(i.WODate,'1/1/1900') and w.DateOfSale is not null THEN w.DateOfSale ELSE i.WoDate END
		or isnull(t.ReceivedDate,'1/1/1900') <> isnull(i.WODate,'1/1/1901')
		)

GO
/****** Object:  StoredProcedure [dbo].[spRptBuilder_Inventory_FullInventory]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




  -- spRptBuilder_Inventory_FullInventory 


CREATE procedure [dbo].[spRptBuilder_Inventory_FullInventory]
	@EndDate as datetime = NULL   -- Non-Inclusive  -- Last Month
AS
DECLARE @ignoreCategory varchar(100) = 'CABINETS' -- One category to ignore from reports; 'xxx' = don't ignore any categories

DECLARE @AsOfDate datetime = getdate()  -- default to today's date
IF (@EndDate is not null) SELECT @AsOfDate = @EndDate

DECLARE @LastPhysInvDate datetime = (SELECT Max(AsOfDate) from tblPhysicalInventory WHERE AsOfDate <= @AsOfDate)

-- We don't want to generate the report past beyond the last physical inventory date
if @LastPhysInvDate > dateadd(m, -6, getdate()) 
	BEGIN
	SELECT @AsOfDate = dateadd(d, 1, @LastPhysInvDate)
	SELECT @EndDate = dateadd(m, 6, @AsOfDate)
	END

--SELECT @LastPhysInvDate as LasPhyInvDate, @AsOfDate as AsOfDate, @EndDate as EndDate

/* Grab Work Order numbers that are in ADP and not yet picked up in Yardi */
		select WONumber, min(PayDate) as ReceivedDate
		into #tblADP_AddlWOs
		from tblADP 
		where WONumber not in (0)
			and PayDate is not null
			and LaborerID in (select LaborerID from tblLaborers where isCoopSupplier=1)
			and (PayDate >= dateadd(m, -6,  @EndDate) and PayDate < @EndDate)
			and isnull(TimeDescription,'') = ''   -- If there is a description then it is not inventory so ignore it
		group by WONumber

		CREATE NONCLUSTERED INDEX idx_temp_table_column ON #tblADP_AddlWOs(wonumber)

/*===============*/
SELECT
	Format(dateadd(m, -6,  @EndDate), 'MMM yyyy') as Month6,
	Format(dateadd(m, -5,  @EndDate), 'MMM yyyy') as Month5,
	Format(dateadd(m, -4,  @EndDate), 'MMM yyyy') as Month4,
	Format(dateadd(m, -3,  @EndDate), 'MMM yyyy') as Month3,
	Format(dateadd(m, -2,  @EndDate), 'MMM yyyy') as Month2,
	Format(dateadd(m, -1,  @EndDate), 'MMM yyyy') as Month1


/*  Anualized Turnover = average of past 6 months times 2 (x2 = 1 year average)
*/
select 
	i.itemCode, 
	upper(c.KeyString) as Category, 
	isnull(ic.ItemDesc, m.ItemDesc) as itemDesc, 
	cast(isnull(ic.Quantity,0) as int) as LastPhysicalCount,
	cast(isnull(m.YardiSalesQuantity,0) as int) as TotalSales,
	cast(isnull(m.YardiPurchaseQuantity,0) as int) as TotalPurchases,

	isnull((SELECT Max(v) FROM (VALUES (YardiSales1Mo), (YardiSales2Mo), (YardiSales3Mo), (YardiSales4Mo), (YardiSales5Mo), (YardiSales6Mo)) AS value(v) where isnull(v,0) <> 0),0) as [SixMoHigh],
	isnull((SELECT Min(v) FROM (VALUES (YardiSales1Mo), (YardiSales2Mo), (YardiSales3Mo), (YardiSales4Mo), (YardiSales5Mo), (YardiSales6Mo)) AS value(v) where isnull(v,0) <> 0),0) as [SixMoLow],
	isnull(CAST(((YardiSales1Mo + YardiSales2Mo + YardiSales3Mo + YardiSales4Mo + YardiSales5Mo + YardiSales6Mo) / 6) as decimal(10,2)), 0.00) as SixMoAvg,
	isnull(CAST((((YardiSales1Mo + YardiSales2Mo + YardiSales3Mo + YardiSales4Mo + YardiSales5Mo + YardiSales6Mo) / 6) * 2) as decimal(10,2)), 0.00) as AnnualizedTurnover,

	isnull(YardiSales6Mo, 0.00) as YardiSales6Mo,
	isnull(YardiSales5Mo, 0.00) as YardiSales5Mo,
	isnull(YardiSales4Mo, 0.00) as YardiSales4Mo,
	isnull(YardiSales3Mo, 0.00) as YardiSales3Mo,
	isnull(YardiSales2Mo, 0.00) as YardiSales2Mo,
	isnull(YardiSales1Mo, 0.00) as YardiSales1Mo,

	cast(isnull(ic.Quantity,0) + isnull(m.Quantity,0) as int) as TotalEndQuantity,
	isnull(si.UnitPrice,0.00) as UnitPrice,
	isnull(cast((si.UnitPrice * (isnull(ic.Quantity,0) + isnull(m.Quantity,0))) as decimal(10,2)), 0.00) as TotalEndValue
from 
	-- I: ITEM CODES
	-- Get all inventory codes possible from Physical Counts, and Master inventory
	(SELECT DISTINCT ItemCode from 
		(SELECT DISTINCT Code as ItemCode FROM tblPhysicalInventory where AsOfDate = @LastPhysInvDate and isnull(code,'') > '' and PhysicalCount is not null
			UNION
		 SELECT DISTINCT itemCode from tblInventoryTracking where DateOfSale >= @LastPhysInvDate and DateOfSale < @EndDate) as u) as i

	-- IC: PHYSICAL INVENTORY COUNT
	-- Get counts from physical inventory count table
	left join 
		(select Code as itemCode, max([Description]) as ItemDesc, sum(isnull(PhysicalCount,0)) as Quantity
		from tblPhysicalInventory 
		where AsOfDate = @LastPhysInvDate and isnull(code,'') > '' and PhysicalCount is not null
		group by Code) as ic on i.ItemCode = ic.itemCode

	-- M: MASTER INVENTORY
	-- Get counts from Master Inventory with WO and POs
	left join 
		(select ItemCode, 
			-- These are over 6 months from the WHERE clause
			max(it.ItemDesc) as ItemDesc, 
			sum(isnull(it.Quantity,0)) as Quantity,		
			sum(CASE WHEN isnull(Quantity,0) < 0 THEN Quantity ELSE 0 END) as YardiSalesQuantity,    /* Limit these by the past 6 months  */
			sum(CASE WHEN isnull(Quantity,0) > 0 THEN Quantity ELSE 0 END) as YardiPurchaseQuantity,
			
			sum(CASE WHEN isnull(Quantity,0) < 0 AND isnull(it.ReportingDate_calc, adp.ReceivedDate) >= dateadd(m, -1,  @EndDate) AND isnull(it.ReportingDate_calc, adp.ReceivedDate) < @EndDate THEN isnull(Quantity,0.00)  ELSE 0.00 END) as YardiSales1Mo,
			sum(CASE WHEN isnull(Quantity,0) < 0 AND isnull(it.ReportingDate_calc, adp.ReceivedDate) >= dateadd(m, -2,  @EndDate) AND isnull(it.ReportingDate_calc, adp.ReceivedDate) < dateadd(m, -1,  @EndDate) THEN isnull(Quantity,0.00)  ELSE 0.00 END) as YardiSales2Mo,
			sum(CASE WHEN isnull(Quantity,0) < 0 AND isnull(it.ReportingDate_calc, adp.ReceivedDate) >= dateadd(m, -3,  @EndDate) AND isnull(it.ReportingDate_calc, adp.ReceivedDate) < dateadd(m, -2,  @EndDate) THEN isnull(Quantity,0.00)  ELSE 0.00 END) as YardiSales3Mo,
			sum(CASE WHEN isnull(Quantity,0) < 0 AND isnull(it.ReportingDate_calc, adp.ReceivedDate) >= dateadd(m, -4,  @EndDate) AND isnull(it.ReportingDate_calc, adp.ReceivedDate) < dateadd(m, -3,  @EndDate) THEN isnull(Quantity,0.00)  ELSE 0.00 END) as YardiSales4Mo,
			sum(CASE WHEN isnull(Quantity,0) < 0 AND isnull(it.ReportingDate_calc, adp.ReceivedDate) >= dateadd(m, -5,  @EndDate) AND isnull(it.ReportingDate_calc, adp.ReceivedDate) < dateadd(m, -4,  @EndDate) THEN isnull(Quantity,0.00)  ELSE 0.00 END) as YardiSales5Mo,
			sum(CASE WHEN isnull(Quantity,0) < 0 AND isnull(it.ReportingDate_calc, adp.ReceivedDate) >= dateadd(m, -6,  @EndDate) AND isnull(it.ReportingDate_calc, adp.ReceivedDate) < dateadd(m, -5,  @EndDate) THEN isnull(Quantity,0.00)  ELSE 0.00 END) as YardiSales6Mo

		/* NOTES:
			--	Be sure to sync any changes to the WHERE clause with the PIVOT spRptBuilder_Inventory_PivotByDay stored procedure.
				It needs to match here.
		*/
		from tblInventoryTracking it
			left join #tblADP_AddlWOs adp on it.WONumber = adp.WONumber  -- Consider dates in the ADP table that are not yet imported into Yardi
			left join tblWorkOrders wo on it.WONumber = wo.WONumber -- only rely on Category from the Work Order table
			left join tblLookupValues lv on left(it.ItemCode,2) = cast(lv.keyValue as int) and lv.Category='InvCategoryID'
		where 
			upper(lv.KeyString) not in (@ignoreCategory)   -- InventoryCategory
			and -- Only include Purchase Order sources without a Work Order number and everything else
				((it.Source='PO' and isnull(it.WONumber,0) = 0) or it.Source <> 'PO' )
			and isnull(wo.Category,'') not in ('APH-Plumbing', 'APH-Boiler')  -- Instructed to not pick up these cateogries for this report [10/17/2024]
			and (isnull(it.ReportingDate_calc, adp.ReceivedDate) >= dateadd(m, -6,  @EndDate) and isnull(it.ReportingDate_calc, adp.ReceivedDate) < @EndDate)  -- Full set is 6 months of data
		group by ItemCode) as m on i.ItemCode = m.ItemCode

	-- SI: SORTLY (To get Prices)
	left join tblSortlyInventory si on i.itemCode = si.itemCode

	-- C: CATEGORIES
	left join tblLookupValues c on c.Category = 'InvCategoryID' and cast(substring(i.itemCode,1,2) as int) = cast(c.KeyValue as int) 

WHERE 
	upper(c.KeyString) not in (@ignoreCategory)

	--and i.ItemCode in ('10-00200') 

ORDER BY i.itemCode

DROP TABLE #tblADP_AddlWOs


GO
/****** Object:  StoredProcedure [dbo].[spRptBuilder_Inventory_PivotByDay]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








-- spRptBuilder_Inventory_PivotByDay '10/1/2024', '11/1/2024'

CREATE       procedure [dbo].[spRptBuilder_Inventory_PivotByDay]
	@StartDate as datetime = NULL,   -- Inclusive 
	@EndDate   as datetime = NULL    -- Non-Inclusive 
AS
BEGIN

DECLARE @ignoreCategory varchar(100) = 'CABINETS' -- One category to ignore from reports; 'xxx' = don't ignore any categories

/* Use the ADP data to get the population (Work orders) because it shows all the wo that guys worked on.
	-- all wo from date to date -- filter out WO using the names of people from ADP 
	-- This version includes Sortly
*/

/* Get the last physical inventory date before the beginning of this run and use it in the query */
DECLARE @PhysInventoryDate datetime = NULL
SELECT @PhysInventoryDate = max(asOfDate) FROM tblPhysicalInventory where asofdate <= isnull(@StartDate,(SELECT MIN(AsOfDate) FROM tblPhysicalInventory))


/* Grab any Work Orders from the ADP Reporting that have not hit Yardi yet */
select WONumber, min(PayDate) as ReceivedDate
into #tblADP_AddlWOs
from tblADP 
where WONumber not in (0)
	and PayDate is not null
	and LaborerID in (select LaborerID from tblLaborers where isCoopSupplier=1)
	and (PayDate >= @StartDate and PayDate < @EndDate)
	and isnull(TimeDescription,'') = ''   -- If there is a description then it is not inventory so ignore it
group by WONumber

CREATE NONCLUSTERED INDEX idx_temp_table_column ON #tblADP_AddlWOs(wonumber)

/* Get all the distinct dates to present */
DECLARE @cols as nvarchar(MAX) = ''
SELECT @cols=STRING_AGG(cast(a.header as nvarchar(max)), ',')
FROM   (
        SELECT DISTINCT 
			'[' + format(isnull(it.ReportingDate_calc, adp.receivedDate), 'MM-dd-yy ') +
			CASE WHEN isnull(it.WONumber,0) = 0 
				THEN 'PO' + cast(it.PONumber as varchar(10)) 
				ELSE 'WO' + cast(it.WONumber as varchar(10)) 
				END + ']'  as header
        FROM tblInventoryTracking it
			left join #tblADP_AddlWOs adp on it.WONumber = adp.WONumber
		where (isnull(it.ReportingDate_calc, adp.receivedDate) is not null
			and isnull(it.ReportingDate_calc, adp.receivedDate) >= @StartDate
			and isnull(it.ReportingDate_calc, adp.receivedDate) < @EndDate)
			and ((it.Source='PO' and isnull(it.WONumber,0) = 0) or it.Source <> 'PO' )
        ) as a 

/* Fill from tblInventoryTracking which has inventory from Yardi and Sortly */
	
	select 
		upper(lv.KeyString) as InventoryCategory, 
		it.ItemCode, 
		isnull(si.itemName, it.ItemDesc) as [Description], 
		si.UnitPrice, 
		format(isnull(it.ReportingDate_calc, aa.receivedDate), 'MM-dd-yy ') +
			CASE WHEN isnull(it.WONumber,0) = 0 
				THEN 'PO' + cast(it.PONumber as varchar(10)) 
				ELSE 'WO' + cast(it.WONumber as varchar(10)) 
				END  as header,
		sum(it.Quantity) as Quantity,
		isnull(ib.seedCount,0) as QtyStart,
		qt.QtyTotalPerItem + isnull(ib.seedCount,0) as QtyTotal,
		cast(si.UnitPrice * (isnull(QtyTotalPerItem,0) + isnull(ib.seedCount,0)) as decimal(10,2)) as PriceTotal
	into #tmp 
	from tblInventoryTracking it  -- Contains YARDI and SORTLY
		left join tblLookupValues lv on left(it.ItemCode,2) = cast(lv.keyValue as int) and lv.Category='InvCategoryID'
		left join tblSortlyInventory si on it.itemCode = si.ItemCode
		left join #tblADP_AddlWOs aa on it.WONumber = aa.WONumber
		left join tblWorkOrders wo on it.WONumber = wo.WONumber
		left join (
			select Code, sum(isnull(PhysicalCount,0)) as seedCount 
			from tblPhysicalInventory as ib
			where isnull(code,'') <> '' and PhysicalCount is not null and AsOfDate = @PhysInventoryDate
			group by Code
			) as ib on it.ItemCode = ib.Code
		left join (	
			select it2.ItemCode, sum(it2.Quantity) as QtyTotalPerItem  
			FROM tblInventoryTracking it2
				left join #tblADP_AddlWOs aaa on it2.WONumber = aaa.WONumber
			WHERE (isnull(it2.ReportingDate_calc, aaa.receivedDate) is not null
					and isnull(it2.ReportingDate_calc, aaa.receivedDate) >= @StartDate 
					and isnull(it2.ReportingDate_calc, aaa.receivedDate) < @EndDate)
					OR 
					(aaa.WONumber is not null) -- The WO is found in the temp ADP table
				and (isnull(it2.ReportingDate_calc, aaa.receivedDate) is not null)  -- added because NULL dates were being included
			group by it2.ItemCode ) qt on it.itemcode = qt.itemcode 
	where 
		upper(lv.KeyString) not in (@ignoreCategory)   -- InventoryCategory
		and -- Only include Purchase Order sources without a Work Order number and everything else
			((it.Source='PO' and isnull(it.WONumber,0) = 0) or it.Source <> 'PO' )
		and isnull(wo.Category,'') not in ('APH-Plumbing', 'APH-Boiler')  -- Instructed to not pick up these cateogries for this report [10/17/2024]
		and ((isnull(it.ReportingDate_calc, aa.receivedDate) is not null
				and isnull(it.ReportingDate_calc, aa.receivedDate) >= @StartDate
				and isnull(it.ReportingDate_calc, aa.receivedDate) < @EndDate) 
			or (aa.WONumber is not null)) -- The WO is found in the temp ADP table
		
		--and it.WONumber in (506303, 506484)
	    --and it.itemCode in ('10-00400')
	
	group by 
		lv.KeyString, it.ItemCode, si.unitprice, 
		isnull(si.itemName, it.ItemDesc),isnull(ib.seedCount,0),
		QtyTotalPerItem + isnull(ib.seedCount,0),
		cast(si.UnitPrice * (isnull(QtyTotalPerItem,0) + isnull(ib.seedCount,0)) as decimal(10,2)),
		format(isnull(it.ReportingDate_calc, aa.receivedDate), 'MM-dd-yy ') +
			CASE WHEN isnull(it.WONumber,0) = 0 
				THEN 'PO' + cast(it.PONumber as varchar(10)) 
				ELSE 'WO' + cast(it.WONumber as varchar(10)) END


/* GROUP up #tmp table to get totals */
SELECT
		#tmp.InventoryCategory, 
		#tmp.ItemCode, 
		#tmp.[Description], 
		#tmp.UnitPrice, 
		#tmp.header,
		sum(Quantity) as Quantity,
		sum(QtyStart) as QtyStart,
		sum(QtyTotal) as QtyTotal,
		sum(PriceTotal) as PriceTotal
INTO #tmp2
FROM #tmp
WHERE upper(InventoryCategory) not in (@ignoreCategory)
GROUP BY InventoryCategory, #tmp.ItemCode, #tmp.header, #tmp.UnitPrice, [Description]

/*=============================================*/
/* Tab 1: DATE RANGE */
/* Return the Start Date for the Spreadsheet */
Select 
	format(@StartDate, 'MM/dd/yy') as [Report Start Date], 
	format(@EndDate, 'MM/dd/yy') as [End Date],
	format(@PhysInventoryDate, 'MM/dd/yy') as [Physical Inventory Date]

/*=============================================*/
/* SUMMARIES */
/* Tab 2: Display Summaries by Category */
select InventoryCategory, sum(QtyStart) as QtyStart, sum(QtyTotal) as QtyTotal, sum(PriceTotal) as Total 
from #tmp2
WHERE upper(InventoryCategory) not in (@ignoreCategory)
group by InventoryCategory
order by InventoryCategory

/*=============================================*/
/* Tab 3: INVENTORY DETAILS */
DECLARE @sql nvarchar(max) = 'select * from #tmp2 pivot ( sum(Quantity) for header in ( ' + @cols + ' ) ) as c'
EXEC Sp_executesql @sql

/*=============================================*/
/* Tab 4: LABORERS (WO) */
/* Display list of Laborors OR PO Vendors for Externals*/

-- Get all the WONumbers and Names from ADP 
--	-- Get everything where the PayDate falls between the report date range
select distinct adp.wonumber, woLab.laborers
into #tmpADP
from tblADP adp left join 
	(select distinct l.wonumber, string_agg(l.FullName_Calc,' / ') as Laborers
		from (select distinct wonumber, la.FullName_Calc from tblADP left join tblLaborers la on tblADP.LaborerID = la.LaborerID) as l 
		where isnull(l.WONumber,'') > ''
		group by l.WONumber) as wolab on adp.WONumber = wolab.WONumber
where isnull(adp.WONumber,'') > '' 
	and (adp.PayDate >= @StartDate and adp.PayDate < @EndDate)

SELECT DISTINCT 
	it.WONumber, 
	isnull(case	when adp.Laborers is null 
			then wo.POVendors 
			else adp.Laborers + isnull(' / ' + wo.POVendors,'') 
			end, it.Category) as [Laborers],
	upper(wo.Category) as WOCategory
FROM tblInventoryTracking it
	left join tblWorkOrders wo on it.WONumber = wo.WONumber
	left join #tmpADP adp on it.WONumber = adp.WONumber
where 
	isnull(it.WONumber,0) > 0
	and isnull(wo.Category,'') not in ('APH-Plumbing', 'APH-Boiler')
	and (isnull(it.reportingDate_calc, it.DateOfSale) is not null
		and isnull(it.reportingDate_calc, it.DateOfSale) >= @StartDate
		and isnull(it.reportingDate_calc, it.DateOfSale) < @EndDate
		)
		OR
		(it.WONumber in (SELECT WONumber from #tblADP_AddlWOs)
	)
order by it.WONumber

/*=============================================*/
/* Tab 5: VENDORS (PO) */
/* Display list Vendors for Externals*/
SELECT DISTINCT p.PONumber, STRING_AGG(p.VendorName, ' / ') as Vendors
FROM tblPurchaseOrders p
WHERE p.VendorName is not null
group by p.poNumber
order by p.ponumber

/*=============================================*/
/* Tab 5: EXCEPTIONS */
SELECT po.WONumber, d.PONumber, po.VendorName, d.QtyOrdered, d.UnitPrice, 
	cast(isnull(d.QtyOrdered,0) * isnull(d.UnitPrice,0) as decimal(10,2)) as TotalCost, 
	format(po.OrderDate, 'MM/dd/yy') as OrderDate, 
	format(po.ReceivedDate, 'MM/dd/yy') as ReceivedDate, 
	d.ItemCode, d.ItemDesc, po.ExpenseType, 
	CASE WHEN isnull(prop.addr1_Co,'') > '' AND isnull(prop.addr2,'') > '' 
		THEN upper(trim(prop.addr1_Co + ', ' + prop.addr2)) 
		ELSE upper(trim(prop.addr1_Co + prop.addr2)) END as Client
FROM tblPurchaseOrders_Details d
	left join tblPurchaseOrders po on d.PONumber = po.PONumber
	left join tblWorkOrders wo on po.WONumber = wo.WONumber
	left join tblProperties prop on wo.BuildingNum = prop.buildingCode
where 
	(po.ReceivedDate is not null
	and po.ReceivedDate >= @StartDate
	and po.ReceivedDate < @EndDate)
	AND ItemCode like 'material%'
order by WONumber, PONumber

/*---------------------------------------------*/
/* Cleanup */
DROP TABLE #tmp
DROP TABLE #tmp2
DROP TABLE #tmpADP
DROP TABLE #tblADP_AddlWOs

END
GO
/****** Object:  StoredProcedure [dbo].[spRptBuilder_Vacancy_Cover]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- spRptBuilder_Vacancy_Cover @buildingCode='1011'

CREATE procedure [dbo].[spRptBuilder_Vacancy_Cover]
	@BuildingCode varchar(20) = NULL,
	@AptNumber varchar(25) = NULL
AS
	/* This will not return any that are excluded or inactive */

	select 
		p.buildingCode, 
		p.addr1_Co, 
		p.fullAddress_calc, 
		u.statusBasedOnDates, 
		u.AptNumber, 
		u.Bedrooms, 
		u.rent, 
		u.UnitStatus, 
		uo.yearsOccupied, 
		uo.yearsOccupied_Note, 
		isnull(u.LastTenantRent,0) as LastTenantRent,
		u.unitTypeDesc,
		c.unitCount
	from tblProperties p
		inner join  tblPropertyUnits u on p.yardiPropertyRowID = u.yardiPropertyRowID
		left join vwUnitOccupancy uo on u.yardiUnitRowID = uo.yardiUnitRowID
		left join vwPropertyUnitCount c on p.yardiPropertyRowID = c.yardiPropertyRowID
	where 
		u.isExcluded = 0
		AND p.isInactive = 0
		AND (@buildingCode is null or (@buildingCode is not null and @buildingCode=p.buildingCode))
		AND (@AptNumber is null or (@aptNumber is not null and @aptNumber=u.aptNumber))
	order by p.buildingCode, u.AptNumber

GO
/****** Object:  StoredProcedure [dbo].[spRptBuilder_Vacancy_Cover_pt2]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



--3655 - 3656-5A
--3655 - 3658-2B
--3522 - 4E
-- 3533 - 2D
-- 4114 - 5K

-- spRptBuilder_Vacancy_Cover_pt2 '4114', '5K'   -- 10022

--select * from tblProperties where buildingCode='4114'
--select * from tblWorkOrders where AptNum='5K' and BuildingNum='4114' and yardiPropertyRowID=2103

CREATE procedure [dbo].[spRptBuilder_Vacancy_Cover_pt2]
	@BuildingCode varchar(20) = NULL,
	@AptNumber varchar(20) = NULL
AS
SELECT 
	wo.Category, 
	sum(wo.InvoicePrice) as SumOfInvoicePrice,
	STRING_AGG(WONumber, ', ') as WONumbers
FROM tblProperties p
	inner join tblPropertyUnits u on p.yardiPropertyRowID = u.yardiPropertyRowID
	inner join tblWorkOrders wo on u.AptNumber = wo.AptNum and p.buildingCode = wo.BuildingNum
WHERE 
	coalesce(wo.ScheduledCompletedDate, wo.CallDate, '1/1/1899') > isnull(u.LastMoveOutDate,'1/1/1900')
	and p.buildingCode=@BuildingCode
	and u.AptNumber = @AptNumber
GROUP BY 
	isnull(p.addr2, p.addr1_Co), u.AptNumber, wo.Category, p.buildingCode
ORDER BY Category




GO
/****** Object:  StoredProcedure [dbo].[spRptBuilder_WOReview_01_WOs]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








/*  STEP 1: Insert or Update initial Work Order Details 
*/

-- spRptBuilder_WOReview_01_WOs @WONumbers = '462622,464327'


CREATE procedure [dbo].[spRptBuilder_WOReview_01_WOs]
	--@CallDateStart datetime = NULL,
	--@CallDateEnd dateTime = NULL,
	@woNumbers varchar(max) = NULL,
	@NoReturn bit = 0  -- Don't return rows for speed
AS
BEGIN

	-- 1. Insert any new WONumbers we need to update
	INSERT INTO tblWorkOrders(WONumber)
		SELECT distinct wo.WONumber FROM tblImport_Yardi_WOList wo
		where
			wo.WONumber not in (SELECT WONumber FROM tblWorkOrders) -- Only insert new work orders
			--and (@CallDateStart is null or (@CallDateStart is not null and isnull(wo.CallDate,'1/1/1900') >= @CallDateStart))
			--and (@CallDateEnd is null or (@CallDateEnd is not null and isnull(wo.CallDate,'1/1/2900') <= @CallDateEnd))
			and (@woNumbers is null or (@woNumbers is not null and wo.wonumber in (SELECT value FROM STRING_SPLIT( @woNumbers, ','))))

	-- 2. Then update all the WOs all at once with just one query
	UPDATE tblWorkOrders Set
		CallDate = src.CallDate,
		BuildingNum = src.BuildingNum,
		AptNum = src.AptNum,
		JobStatus = src.JobStatus,
		ScheduledCompletedDate = src.ScheduledCompletedDate,
		BatchID = src.BatchID,
		BatchDate = src.BatchDate,
		TRansBatchDate = src.TransBatchDate,
		BriefDesc = src.Rad,
		Category = src.Category,
		CompletedDate = src.CompletedDate,
		InvoicePrice = src.InvoicePrice,
		MaterialFromInventCost = InventoryPayAmt,
		PostedMonth = src.PostedMonth
	FROM
		(select CallDate, WONumber, BuildingNum, AptNum, JobStatus, 
			cast(format(max(isnull(SchedDate, CompleteDate)), 'MM/dd/yyyy') as DateTime) as ScheduledCompletedDate,
			max(BriefDesc) as Rad,
			Category,
			cast(format([CompleteDate], 'MM/dd/yyyy') as Date) as CompletedDate,
			BatchID, BatchDate,
			TransBatchDate,
			sum(PayAmt) as InvoicePrice,
			PostedMonth,
			sum(case when Category not in ('Retail') and Code like ('%-%') then PayAmt else 0 end) as InventoryPayAmt  -- Code=ItemType; Grabbing Inventory from Yardli here for other than Retail
		from tblImport_Yardi_WOList wo
		where
			--(@CallDateStart is null or (@CallDateStart is not null and isnull(wo.CallDate,'1/1/1900') >= @CallDateStart))
			--and (@CallDateEnd is null or (@CallDateEnd is not null and isnull(wo.CallDate,'1/1/2900') <= @CallDateEnd))
			 (@woNumbers is null or (@woNumbers is not null and wo.wonumber in (SELECT value FROM STRING_SPLIT( @woNumbers, ','))))
		group by CallDate, WONumber, BuildingNum, AptNum, JobStatus, 
			BatchID, BatchDate, TransBatchDate, isnull(SchedDate, CompleteDate),
			Category, CompleteDate, PostedMonth
		) as src
	WHERE tblWorkOrders.WONumber = src.WONumber

	/* UPDATE OR INSERT INTO THE WORK ORDER DETAIL TABLE tblWorkOrderItems by the Work Order Detail ID (mm2wodet.hMy) */
	/* INSERT */
	INSERT INTO tblWorkOrderItems (YardiWODetailRowID, WONumber, ItemCode, Quantity, PayAmount, FullDescription)
	SELECT WODetailRowID, WONumber, [Code], Quantity, PayAmt, FullDesc
	FROM tblImport_Yardi_WOList AS src
	WHERE NOT EXISTS (SELECT YardiWODetailRowID FROM tblWorkOrderItems WHERE YardiWODetailRowID = src.WODetailRowID)
		AND ISNULL(WONumber, 0) > 0
		AND WODetailRowID IS NOT NULL

	/* UPDATE */
	UPDATE tblWorkOrderItems
		Set ItemCode = i.[Code], 
			Quantity = i.Quantity,
			PayAmount = i.PayAmt,
			FullDescription = i.FullDesc
	FROM tblWorkOrderItems woi 
		inner join tblImport_Yardi_WOList i on i.WODetailRowID = woi.YardiWODetailRowID
	WHERE (woi.ItemCode <> i.[Code]
			or woi.Quantity <> i.Quantity
			or woi.PayAmount <> i.PayAmt
			or woi.FullDescription <> i.FullDesc)
		and isnull(i.wonumber,0) > 0
		and i.WODetailRowID is not null

END

GO
/****** Object:  StoredProcedure [dbo].[spRptBuilder_WOReview_02_POs]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*  STEP 2: Update with PO Information
*/

-- spRptBuilder_WOReview_02_POs @woNumbers='462390'

CREATE procedure [dbo].[spRptBuilder_WOReview_02_POs]
	@woNumbers varchar(max) = NULL
AS
BEGIN

/* UPDATE THE MASTER TABLE */

UPDATE tblWorkOrders Set
	InvoiceDate = a.InvoiceDate,
	PONumbers = a.PONumbers,
	POVendors = a.VendorNames,
	PurchasedMaterialCost = a.POAmount_Materials,
	LaborCost_Outside = a.LaborCost_Outside	
FROM
	tblWorkOrders updWO 
	left join dbo.vwPO_GroupLaborMaterialsVendor as a on updWO.WONumber = a.WONumber 
WHERE 
	(@woNumbers is null or (@woNumbers is not null and updWO.wonumber in (SELECT value FROM STRING_SPLIT( @woNumbers, ','))))
	or (
		updWO.InvoiceDate <> a.InvoiceDate
		or updWO.PONumbers <> a.PONumbers
		or updWO.POVendors <> a.VendorNames
		or updWO.PurchasedMaterialCost <> a.POAmount_Materials
		or updWO.LaborCost_Outside <> a.LaborCost_Outside	
		)

END
GO
/****** Object:  StoredProcedure [dbo].[spRptBuilder_WOReview_03_Labor]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








--update tblWorkOrders set Laborer1_ID=null, Laborer2_ID=null, laborer3_id=null, Laborer4_ID=null 
--where WONumber in (select distinct WONumber from tbladp where isnull(PayrollName,'') > '')   --4,933

-- spRptBuilder_WOReview_03_Labor 

CREATE     procedure [dbo].[spRptBuilder_WOReview_03_Labor]
AS
BEGIN
	/* Update tblLaborers table
		Make sure any new laborers found in the ADP import are registered in the tblLaborers table
		Set defaults
	*/
	INSERT INTO tblLaborers(
		LastName, FirstName, 
		LWSalariedHourlyRate, 
		LWSmJobMinRateAdj, LWOTRate, LWMaterialRate, includeForInventory, BonusFactor, isSupervisor, isCoopSupplier)
	select distinct 
		trim(substring(PayrollName, 0, CHARINDEX(',', PayrollName))) as LastName, 
		trim(substring(PayrollName, CHARINDEX(',', PayrollName) + 1, LEN(payrollName))) as FirstName,
		NULL, 
		1, 1, 0, 1, 0, 0, 0
	from tblADP 
	where LaborerID is null 
		and PayrollName not in (select distinct fullname_calc from tblLaborers)
		and PayrollName is not null

	/* DO SOME CALCULATIONS PREP */
	-- Set the Laborer IDs in tblADP   -- From here on you can make all joins with the LaborerID
	-- update tblADP set LaborerID=null
	UPDATE tblADP Set LaborerID = l.LaborerID
	from tblADP a INNER JOIN tblLaborers l ON a.PayrollName = l.FullName_Calc
	WHERE a.LaborerID is null

	-- Delete this random row if it shows up
	delete from tblADP where PayrollName='Grand Totals'

	-- Update the dollars here from the lookup table when they are not brought in by ADP
	-- For salaried workers in ADP. These are defined by a value being present in tblLaborers
	update tblADP
		Set Dollars_Calculated = 
			cast(
				(case when (paycode in ('REGULAR','REGSAL') and [Hours] > 0 and Dollars = 0 and isnull(l.LWSalariedHourlyRate,0) > 0) 
					THEN isnull(l.LWSalariedHourlyRate,0) * isnull([Hours],0) 
					ELSE Dollars 
					END) 
			as decimal(10,2) )
	from tblADP adp
		INNER JOIN tblLaborers l ON adp.LaborerID = l.LaborerID
	WHERE 
		isnull(Dollars_Calculated, 0.00) <>
				cast(
					(case when (paycode in ('REGULAR','REGSAL') and [Hours] > 0 and Dollars = 0 and isnull(l.LWSalariedHourlyRate,0) > 0) 
						THEN isnull(l.LWSalariedHourlyRate,0) * isnull([Hours],0) 
						ELSE Dollars 
						END) 
				as decimal(10,2) )

/* SECOND UPDATE - Update the Labor Totals in the Work Orders table */

	UPDATE tblWorkOrders Set 
		LaborAdj_OT = wolc.sumCostOT,
		Labor_Total = wolc.sumTotalCost
	FROM tblWorkOrders wo
		inner join 
		( SELECT distinct 
				wonumber, 
				sum(isnull(costOT,0)) as sumCostOT, 
				sum(isnull(costOT,0)) + sum(isnull(costReg,0)) as sumTotalCost
			FROM vwWorkOrderLaborers 
			group by wonumber
			) as wolc on wo.WONumber = wolc.WONumber
	WHERE
		isnull(LaborAdj_OT,0) <> isnull(wolc.sumCostOT,0)
		or isnull(Labor_Total,0) <> isnull(sumTotalCost,0)

END
GO
/****** Object:  StoredProcedure [dbo].[spRptBuilder_WOReview_04_SortlyFixes]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







-- [spRptBuilder_WOReview_04_SortlyFixes] 1
 --select * from tblImport_Sortly where 

CREATE     procedure [dbo].[spRptBuilder_WOReview_04_SortlyFixes]
	@ResetAll bit = NULL  -- NO LONGER IN USE
AS
BEGIN

	UPDATE tblImport_Sortly
	Set 
		WONumber_Calc = 
			case 
				when trim(SubFolderLevel4) like ('[0-9][0-9][0-9][0-9][0-9][0-9]') then cast(SubFolderLevel4 as int)
				when trim(SubFolderLevel3) like ('WO%[0-9][0-9][0-9][0-9][0-9][0-9]%') then SUBSTRING(SubFolderLevel3, PATINDEX('%[0-9]%', SubFolderLevel3), 6) 
				when trim(SubFolderLevel2) like ('WO%[0-9][0-9][0-9][0-9][0-9][0-9]%') then SUBSTRING(SubFolderLevel2, PATINDEX('%[0-9]%', SubFolderLevel2), 6) 
				when trim(SubFolderLevel4) like ('WO%[0-9][0-9][0-9][0-9][0-9][0-9]%') then SUBSTRING(SubFolderLevel4, PATINDEX('%[0-9]%', SubFolderLevel4), 6) 
				when trim(SubFolderLevel1) like ('WO%[0-9][0-9][0-9][0-9][0-9][0-9]%') then SUBSTRING(SubFolderLevel1, PATINDEX('%[0-9]%', SubFolderLevel1), 6) 
				when trim(PrimaryFolder)   like ('WO%[0-9][0-9][0-9][0-9][0-9][0-9]%') then SUBSTRING(PrimaryFolder,   PATINDEX('%[0-9]%', PrimaryFolder), 6) 
				else NULL end
		where WONumber_Calc is null
			and PrimaryFolder like '%Today%Work Orders%' 


	UPDATE tblImport_Sortly
	Set
		WODate = TRY_CAST(SubFolderLevel3 + '/' + SubFolderLevel1 as datetime)
		WHERE PrimaryFolder like '%Today%Work Orders%' 
			and cast(isnull(WODate,'1/1/1900') as datetime) <> TRY_CAST(SubFolderLevel3 + '/' + SubFolderLevel1 as datetime)

/* Update Sortly inventory table */
EXEC spSortlyFillInventoryTable

END

GO
/****** Object:  StoredProcedure [dbo].[spRptBuilder_WOReview_05_Materials]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- spRptBuilder_WOReview_05_Materials @woNumbers='460923, 463563, 463823, 463852, 463853, 464214'

CREATE   procedure [dbo].[spRptBuilder_WOReview_05_Materials]
	--@CallDateStart datetime = NULL,
	--@CallDateEnd dateTime = NULL,
	@woNumbers varchar(max) = NULL
AS
BEGIN

	/* Update Material costs from Sortly */

	UPDATE tblWorkOrders Set
		MaterialFromInventCost = isnull(case when Category in ('Repairs') then isnull(SumOfTotalValue,0) else 0 end, 0)
	from ( 
			SELECT 
				woNumber_Calc as WONumber,
				sum(isnull(TotalValue,0)) as SumOfTotalValue
			FROM tblImport_Sortly s
			WHERE
				--(@CallDateStart is null or (@CallDateStart is not null and isnull(s.ActivityDate_Calc,'1/1/1900') >= @CallDateStart))
				--and (@CallDateEnd is null or (@CallDateEnd is not null and isnull(s.ActivityDate_Calc,'1/1/2900') <= @CallDateEnd))
				 (@woNumbers is null or (@woNumbers is not null and s.WONumber_Calc in (SELECT value FROM STRING_SPLIT( @woNumbers, ','))))
			GROUP BY WONumber_Calc
		) as src
	WHERE 
		tblWorkOrders.WONumber = src.WONumber


END
GO
/****** Object:  StoredProcedure [dbo].[spRptBuilder_WOReview_06_Calcs]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO










-- spRptBuilder_WOReview_06_Calcs @WONumbers='475380'

CREATE         procedure [dbo].[spRptBuilder_WOReview_06_Calcs]
AS
BEGIN
	/* Do this in several passes so we can use the fields in later passes that are already calculated */

	/*  Calc:	TotalMaterialCost
	*/
	UPDATE tblWorkOrders Set
		TotalMaterialCost = cast(isnull(PurchasedMaterialCost,0) + isnull(MaterialFromInventCost,0) as decimal(10,2))
	WHERE
		isnull(TotalMaterialCost,0) <> cast(isnull(PurchasedMaterialCost,0) + isnull(MaterialFromInventCost,0) as decimal(10,2))


	/*  Calc:	TotalMaterialsLaborAndOL
				FinalSalePrice
				LaborPricing_Outside
	*/
	UPDATE tblWorkOrders Set
		TotalMaterialsLaborAndOL = isnull(Labor_Total,0) + isnull(TotalMaterialCost,0) + isnull(LaborCost_Outside,0),
		FinalSalePrice = (isnull(InvoicePrice,0) - isnull(SalesTax,0)),
		LaborPricing_Outside = isnull(LaborCost_Outside, 0) * (SELECT isnull(KeyValue,1) FROM tblLookupValues WHERE Category='LaborMarkup' and KeyString='Outside' and KeyString2 is null)   -- The two OUTSIDE values are both 1.80 so we only look for "Outside"
	WHERE  
		isnull(TotalMaterialsLaborAndOL,0) <> cast(isnull(Labor_Total,0) + isnull(TotalMaterialCost,0) + isnull(LaborCost_Outside,0) as decimal(10,2))
		or 
		isnull(FinalSalePrice,0) <> cast((isnull(InvoicePrice,0) - isnull(SalesTax,0)) as decimal(10,2))
		or 
		isnull(LaborPricing_Outside,0) <> isnull(LaborCost_Outside, 0) * (SELECT top 1 isnull(KeyValue,1) FROM tblLookupValues WHERE Category='LaborMarkup' and KeyString='Outside' and KeyString2 is null)

	/*  Calc:	TotalMaterialPricing
	*/
	UPDATE tblWorkOrders Set
		TotalMaterialPricing = cast(isnull(TotalMaterialCost,0) * isnull((SELECT max(isnull(KeyValue,1)) FROM tblLookupValues WHERE Category='MaterialMarkup' and KeyString=tblWorkOrders.Category and KeyString2 is null), 1.0) as decimal(10,2)) -- MaterialMarjup only has 1 key (
	WHERE 
		isnull(TotalMaterialPricing,0) <> cast(isnull(TotalMaterialCost,0) * isnull((SELECT max(isnull(KeyValue,1)) FROM tblLookupValues WHERE Category='MaterialMarkup' and KeyString=tblWorkOrders.Category and KeyString2 is null), 1.0) as decimal(10,2)) -- MaterialMarjup only has 1 key (

	/*  Calc:	GrossProfit
	*/
	UPDATE tblWorkOrders Set
		GrossProfit = isnull(InvoicePrice,0) - isnull(TotalMaterialsLaborAndOL,0)
	WHERE 
		(isnull(GrossProfit,0) <> cast((isnull(InvoicePrice,0) - isnull(TotalMaterialsLaborAndOL,0)) as decimal(10,2)))

	/*  Calc:	GrossProfitMargin_Pct
				Labor_MarkUp
	*/
	UPDATE tblWorkOrders Set
		GrossProfitMargin_Pct = cast(100 * isnull(GrossProfit,0) / nullif(isnull(InvoicePrice,0),0) as decimal(10,2)),		-- The NULLF makes it NULL if the number is 0 to avoid DIV/0 error. (Dividing by NULL is NULL)
		Labor_MarkUp = 
			cast(CASE WHEN isnull(LaborPricing_Outside,0) > 0 
				 THEN isnull(Labor_Total,0) * (SELECT isnull(KeyValue,1) FROM tblLookupValues WHERE Category='LaborMarkup' and KeyString='Outside' and KeyString2 is null)   -- Always the same value so far, so only considering 1 key
				 ELSE isnull(Labor_Total,0) * 
					isnull((SELECT isnull(KeyValue,1) FROM tblLookupValues WHERE Category='LaborMarkup' and KeyString='Internal' and KeyString2 = tblWorkOrders.Category),	-- First look to match Division
						(SELECT isnull(KeyValue,1) FROM tblLookupValues WHERE Category='LaborMarkup' and KeyString='Internal' and KeyString2 is NULL))			-- Second to just take the number with KeyString=NULL
				 END as decimal(10,2))			-- Labor Markup Internally has to check the Division/Category
	WHERE 
		isnull(GrossProfitMargin_Pct,0) <> cast(100 * isnull(GrossProfit,0) / nullif(isnull(InvoicePrice,0),0) as decimal(10,2))		-- The NULLF makes it NULL if the number is 0 to avoid DIV/0 error. (Dividing by NULL is NULL)
		or
		isnull(Labor_MarkUp,0) <> 
			cast(CASE WHEN isnull(LaborPricing_Outside,0) > 0 
				 THEN isnull(Labor_Total,0) * (SELECT isnull(KeyValue,1) FROM tblLookupValues WHERE Category='LaborMarkup' and KeyString='Outside' and KeyString2 is null)   -- Always the same value so far, so only considering 1 key
				 ELSE isnull(Labor_Total,0) * 
					isnull((SELECT isnull(KeyValue,1) FROM tblLookupValues WHERE Category='LaborMarkup' and KeyString='Internal' and KeyString2 = tblWorkOrders.Category),	-- First look to match Division
						(SELECT isnull(KeyValue,1) FROM tblLookupValues WHERE Category='LaborMarkup' and KeyString='Internal' and KeyString2 is NULL))			-- Second to just take the number with KeyString=NULL
				 END as decimal(10,2))			-- Labor Markup Internally has to check the Division/Category

	/*  Calc:	CostPlusOH
	*/
	UPDATE tblWorkOrders Set
		CostPlusOH = isnull(Labor_MarkUp, 0) + isnull(TotalMaterialPricing,0) + isnull(LaborPricing_Outside,0)        
	WHERE 
		(isnull(CostPlusOH,0) <> isnull(Labor_MarkUp, 0) + isnull(TotalMaterialPricing,0) + isnull(LaborPricing_Outside,0))

	/*  Calc:	NetProfit
				NetProfitMargin_Pct
	*/
	UPDATE tblWorkOrders Set
		NetProfit = isnull(FinalSalePrice,0) - isnull(CostPlusOH,0),  -- NetProfit used below in calculating NetProfitMargin_Pct 
		NetProfitMargin_Pct = cast(100 * (isnull(FinalSalePrice,0) - isnull(CostPlusOH,0)) / nullif(isnull(FinalSalePrice,0),0) as decimal(10,2))
	WHERE
		isnull(NetProfit,0) <> isnull(FinalSalePrice,0) - isnull(CostPlusOH,0)
		or 
		cast(isnull(NetProfitMargin_Pct,0) as decimal(10,2)) <> cast(100 * (isnull(FinalSalePrice,0) - isnull(CostPlusOH,0)) / nullif(isnull(FinalSalePrice,0),0) as decimal(10,2))

	/*  Calc:	RadDetails
	*/
	UPDATE tblWorkOrders Set BriefDesc=REPLACE(BriefDesc,',',' ') WHERE BriefDesc like ('%,%')

	--/*  Calc:  Bonuses
	--	FinalSalePrice * (WN / Sum(WNs)) * B1
	--	Make it Zero if this is NULL. It becomes NULL if the denoiminator is Zero (which would be an error - NULLIF)
	--	Only updates values when they are NULL so we don't keep re-calculating them
	--*/
	--DECLARE @BonusPercent decimal(10,2) = (SELECT KeyValue FROM tblLookupValues WHERE Category='Bonus' and KeyString = 'PercentOfSalePrice')

	--UPDATE tblWorkOrders SET
	--		Laborer1_Bonus = isnull(CAST((isnull(FinalSalePrice,0)-isnull(TotalMaterialPricing,0)) * (isnull(l1.BonusFactor,0) / NullIf((isnull(l1.BonusFactor,0) + isnull(l2.BonusFactor,0) + isnull(l3.BonusFactor,0) + isnull(l4.BonusFactor,0)),0)) * @BonusPercent as decimal(10,2)),0),
	--		Laborer2_Bonus = isnull(CAST((isnull(FinalSalePrice,0)-isnull(TotalMaterialPricing,0)) * (isnull(l2.BonusFactor,0) / NullIf((isnull(l1.BonusFactor,0) + isnull(l2.BonusFactor,0) + isnull(l3.BonusFactor,0) + isnull(l4.BonusFactor,0)),0)) * @BonusPercent as decimal(10,2)),0),
	--		Laborer3_Bonus = isnull(CAST((isnull(FinalSalePrice,0)-isnull(TotalMaterialPricing,0)) * (isnull(l3.BonusFactor,0) / NullIf((isnull(l1.BonusFactor,0) + isnull(l2.BonusFactor,0) + isnull(l3.BonusFactor,0) + isnull(l4.BonusFactor,0)),0)) * @BonusPercent as decimal(10,2)),0),
	--		Laborer4_Bonus = isnull(CAST((isnull(FinalSalePrice,0)-isnull(TotalMaterialPricing,0)) * (isnull(l4.BonusFactor,0) / NullIf((isnull(l1.BonusFactor,0) + isnull(l2.BonusFactor,0) + isnull(l3.BonusFactor,0) + isnull(l4.BonusFactor,0)),0)) * @BonusPercent as decimal(10,2)),0)
	--FROM 
	--	tblWorkOrders w 
	--	left join tblLaborers l1 on w.Laborer1_ID = l1.LaborerID
	--	left join tblLaborers l2 on w.Laborer2_ID = l2.LaborerID
	--	left join tblLaborers l3 on w.Laborer3_ID = l3.LaborerID
	--	left join tblLaborers l4 on w.Laborer4_ID = l4.LaborerID
	--WHERE 
	--	(Laborer1_Bonus <> isnull(CAST((isnull(FinalSalePrice,0)-isnull(TotalMaterialPricing,0)) * (isnull(l1.BonusFactor,0) / NullIf((isnull(l1.BonusFactor,0) + isnull(l2.BonusFactor,0) + isnull(l3.BonusFactor,0) + isnull(l4.BonusFactor,0)),0)) * @BonusPercent as decimal(10,2)),0))
	--	or (Laborer2_Bonus <> isnull(CAST((isnull(FinalSalePrice,0)-isnull(TotalMaterialPricing,0)) * (isnull(l2.BonusFactor,0) / NullIf((isnull(l1.BonusFactor,0) + isnull(l2.BonusFactor,0) + isnull(l3.BonusFactor,0) + isnull(l4.BonusFactor,0)),0)) * @BonusPercent as decimal(10,2)),0))
	--	or (Laborer3_Bonus <> isnull(CAST((isnull(FinalSalePrice,0)-isnull(TotalMaterialPricing,0)) * (isnull(l3.BonusFactor,0) / NullIf((isnull(l1.BonusFactor,0) + isnull(l2.BonusFactor,0) + isnull(l3.BonusFactor,0) + isnull(l4.BonusFactor,0)),0)) * @BonusPercent as decimal(10,2)),0))
	--	or (Laborer4_Bonus <> isnull(CAST((isnull(FinalSalePrice,0)-isnull(TotalMaterialPricing,0)) * (isnull(l4.BonusFactor,0) / NullIf((isnull(l1.BonusFactor,0) + isnull(l2.BonusFactor,0) + isnull(l3.BonusFactor,0) + isnull(l4.BonusFactor,0)),0)) * @BonusPercent as decimal(10,2)),0))


END		
GO
/****** Object:  StoredProcedure [dbo].[spSortlyFillInventoryTable]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   procedure [dbo].[spSortlyFillInventoryTable]
AS
BEGIN
	/* INSERT NEW - in order of folders. 1-Inventory and then Quarantine */
	INSERT INTO tblSortlyInventory(itemCode, itemName, SortlyID, UnitPrice)
		SELECT distinct i.Notes, i.ItemName, i.SortlyID, i.UnitPrice
		FROM tblImport_Sortly i
		WHERE (i.PrimaryFolder in ('1-Inventory')) --or i.SubFolderLevel2 in ('Quarantine','Quaratine'))
			and i.Notes not in (SELECT itemcode from tblSortlyInventory)
			and isnull(i.Notes,'') like '__-_____'

	/* Update the SortlyInventory table */
	/* We are taking the MAX of the Unit Prices found in all folders. -- This may be wrong */
	UPDATE tblSortlyInventory
		Set itemName = i.ItemName,
			UnitPrice = MaxUnitPrice   -- Taking the MAX because by error there are duplicates
	FROM tblSortlyInventory 
		left join (  -- Using a subquery to get rid of duplicates and get other values
				select PrimaryFolder, 
					max(itemName) as itemName, 
					Notes, 
					max(UnitPrice) as MaxUnitPrice,
					min(WODate) as MinWODate
				from tblImport_Sortly 
				where Notes <> '' 
				group by PrimaryFolder, Notes) as i on itemCode = i.Notes  
	WHERE i.PrimaryFolder = '1-Inventory'
		and (tblSortlyInventory.itemName <> i.itemName
		or tblSortlyInventory.UnitPrice <> i.MaxUnitPrice)

	/* -- Delete any line items that we know are invalid */
	DELETE it
	FROM tblInventoryTracking it 
	INNER JOIN tblInvalidPOItems xx ON it.PONumber=xx.PONumber and it.ItemCode=xx.ItemCode and it.Quantity=xx.Quantity

END
GO
/****** Object:  StoredProcedure [dbo].[spSortlyWorkOrderUpdate]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO










CREATE PROCEDURE [dbo].[spSortlyWorkOrderUpdate]
	@SortlyImportRowID int = NULL,
	@WONumber int = NULL,  -- the WO Number is calcualted in Sortly - but if it's sent in here then use it
	@ActivityDate_Calc datetime = NULL,
	@SortlyID varchar(20) = NULL,
	@ItemName varchar(100) = NULL,
	@Quantity int = NULL,
	@UnitPrice decimal(10,2) = NULL,
	@TotalValue decimal(10,2) = NULL,
	@Notes varchar(500) = NULL,
	@Tags varchar(100) = NULL,
	@PrimaryFolder varchar(100) = NULL,
	@SubFolderLevel1 varchar(100) = NULL,
	@SubFolderLevel2 varchar(100) = NULL,
	@SubFolderLevel3 varchar(100) = NULL,
	@SubFolderLevel4 varchar(100) = NULL,
	@WODate datetime = NULL,
	@SellPrice decimal(10,2) = NULL,
	@LandedCost decimal(10,2) = NULL,
	@Createdby varchar(20) = NULL,
	@CreateDate DateTime = getdate,

	@NoReturn bit = 0  -- 0=Return a row of the inserted or updated data; 1=Return nothing
AS
BEGIN

	IF @SortlyImportRowID is NULL 
		BEGIN
			INSERT INTO tblImport_Sortly(WONumber_Calc, ActivityDate_Calc, SortlyID, ItemName, Quantity, UnitPrice, TotalValue, Notes, Tags, 
			PrimaryFolder, SubFolderLevel1, SubFolderLevel2, SubFolderLevel3, SubFolderLevel4, WODate, SellPrice, LandedCost, CreatedBy, CreateDate) 
			VALUES(@WONumber, @ActivityDate_Calc, @SortlyID, @ItemName, @Quantity, @UnitPrice, @TotalValue, @Notes, @Tags, 
			@PrimaryFolder, @SubFolderLevel1, @SubFolderLevel2, @SubFolderLevel3, @SubFolderLevel4, @WODate, @SellPrice, @LandedCost, @CreatedBy, @CreateDate) 

			SELECT @SortlyImportRowID = SCOPE_IDENTITY()
		END
	ELSE
		BEGIN
			UPDATE tblImport_Sortly Set 
				WONumber_Calc=@WONumber, 
				ActivityDate_Calc=@ActivityDate_Calc, 
				SortlyID=@SortlyID, 
				ItemName=@ItemName, 
				Quantity=@Quantity, 
				UnitPrice=@UnitPrice, 
				TotalValue=@TotalValue, 
				Notes=@Notes, 
				Tags=@Tags, 
				PrimaryFolder=@PrimaryFolder, 
				SubFolderLevel1=@SubFolderLevel1, 
				SubFolderLevel2=@SubFolderLevel2, 
				SubFolderLevel3=@SubFolderLevel3, 
				SubFolderLevel4=@SubFolderLevel4, 
				WODate=@WODate, 
				SellPrice=@SellPrice, 
				LandedCost=@LandedCost, 
				CreatedBy=@CreatedBy, 
				CreateDate=@CreateDate
			WHERE @SortlyImportRowID=@SortlyImportRowID
		END

	IF @NoReturn = 0 EXEC dbo.spSortlyWorkOrders @SortlyImportRowID=@SortlyImportRowID

END
GO
/****** Object:  StoredProcedure [dbo].[spUsers]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





-- [spUsers] @emailAddress='vinny@pixelmarsala.com', @password_enc='tqncz8O7ae1cxSmc1Bn6cg=='

CREATE   procedure [dbo].[spUsers]
	@emailAddress varchar(200) = NULL,
	@password_enc varchar(500) = NULL,
	@userID int = NULL,
	@includeIsDisabled bit = 0   -- default to Not include Disabled
AS

	SELECT *, trim(FirstName + ' ' + LastName) as FullName,
		case	when isSuperAdmin=1 THEN 'Super Admin'
				when isAdmin=1 THEN 'Admin' 
				when isProjectManager=1 THEN 'Project Mgr' 
				when isDisabled=1 THEN 'Disabled'
				else 'User'
				END as UserLevel,
		case when @password_enc is not null and tempPassword_enc=@password_enc then 1 else 0 end as MatchedOnTempPW

	From tblUsers u
	where 
		(@emailAddress is null or (@emailAddress is not null and emailAddress=@emailAddress))
		and (@userID is null or (@userID is not null and userID=@userID))
		and (@password_enc is null or (@password_enc is not null and (password_enc=@password_enc or tempPassword_enc=@password_enc)))
		and (@includeIsDisabled=1 or (@includeIsDisabled = 0 and isDisabled=0))
	order by FirstName, LastName

GO
/****** Object:  StoredProcedure [dbo].[spUserUpdate]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO









CREATE     PROCEDURE [dbo].[spUserUpdate]
	@UserID int = NULL,
	@emailAddress varchar(200) = NULL,
	@FirstName varchar(50) = NULL,
	@LastName varchar(50) = NULL,
	@password_enc varchar(500) = NULL,
	@isAdmin bit= 0,
	@isDisabled bit = 0,
	@isSuperAdmin bit = 0,
	@tempPassword_enc varchar(200) = NULL,
	@forgotPassword bit = 0
AS
BEGIN
	/* To initiate a ForgotPassword pass in EmailAddress and new password */
	IF @forgotPassword = 1
		BEGIN
			UPDATE tblUsers set tempPassword_enc=@tempPassword_enc
			WHERE emailAddress=@emailAddress

			EXEC dbo.spUsers @emailAddress=@emailAddress
			RETURN
		END


	IF @UserID is NULL 
		BEGIN
			INSERT INTO tblUsers
			( FirstName, LastName, password_enc, isAdmin, isSuperAdmin, emailAddress, isDisabled, tempPassword_enc )
			VALUES( @FirstName, @LastName, @password_enc, @isAdmin, @isSuperAdmin, @emailAddress, @isDisabled, @tempPassword_enc )

			SELECT @UserID = SCOPE_IDENTITY()
		END
	ELSE
		BEGIN
			UPDATE tblUsers Set 
				FirstName = @FirstName, 
				LastName = @LastName, 
				[password_enc] = @password_enc, 
				emailAddress = @emailAddress,
				isAdmin = @isAdmin, 
				isSuperAdmin = @isSuperAdmin,
				isDisabled = @isDisabled,
				tempPassword_enc = @tempPassword_enc
		
			WHERE UserID=@UserID
		END

	EXEC dbo.spUsers @UserID=@UserID

END
GO
/****** Object:  StoredProcedure [dbo].[spWOAnalysisReport]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








-- [spWOAnalysisReport] '10/1/2024', '10/15/2024'


CREATE   PROCEDURE [dbo].[spWOAnalysisReport]
	@Date1 as DateTime = NULL,
	@Date2 as DateTime = NULL,
	@WONumber int = NULL
AS 
BEGIN

	select 
		wo.WONumber,
		isnull(BuildingNum,'') as BuildingNum,
		isnull(AptNum,'') as AptNum,
		JobStatus,
		isnull(format(ScheduledCompletedDate, 'MM/dd/yyyy'),'') as ScheduledCompletedDate,
		isnull(format(InvoiceDate, 'MM/dd/yyyy'),'') as InvoiceDate,
		isnull(format(CallDate, 'MM/dd/yyyy'),'') as CallDate,
		wo.PostedMonth,
		wo.BatchID, 
		isnull(format(BatchDate, 'MM/dd/yyyy'),'') as BatchDate,
		isnull(format(TransBatchDate, 'MM/dd/yyyy'),'') as TransBatchDate,
		wo.BriefDesc,
		wo.Category,
		wo.MaterialFromInventCost,
		isnull(wo.PONumbers,'') as PONumbers,
		isnull(wo.POVendors,'') as Vendors,
		isnull(PurchasedMaterialCost,0) as PurchasedMaterialCost,
		isnull(TotalMaterialCost,0) as TotalMaterialCost,
		isnull(TotalMaterialPricing,0) as TotalMaterialPricing,
		isnull(wo.LaborCost_Outside,0) as LaborCost_Outside,
		isnull(wo.LaborPricing_Outside,0) as LaborPricing_Outside,
		isnull(format(wo.CompletedDate, 'MM/dd/yyyy'),'') as CompletedDate,
		isnull(ln.LaborersAndHours,'') as LaborersAndHours,
		tg.TeamGrouping as Team,
		isnull(LaborAdj_OT,0.00) as LaborAdj_OT,
		isnull(wo.Labor_Total,0.00) as Labor_Total,
		isnull(Labor_MarkUp,0.00) as Labor_MarkUp,
		isnull(TotalMaterialsLaborAndOL,0.00) as TotalMaterialsLaborAndOL,
		isnull(FinalSalePrice,0.00) as FinalSalePrice,
		isnull(SalesTax,0.00) as SalesTax,
		isnull(InvoicePrice,0.00) as InvoicePrice,
		isnull(GrossProfit,0.00) as GrossProfit,
		isnull(CostPlusOH,0.00) as CostPlusOH,
		isnull(NetProfit,0.00) as NetProfit,
		isnull(GrossProfitMargin_Pct,0.00) as GrossProfitMargin_Pct,
		isnull(NetProfitMargin_Pct,0.00) as NetProfitMargin_Pct
	from tblWorkOrders wo
		left join vwWorkOrderLaborerNames ln on wo.WONumber = ln.WONumber
		left join vwWOTeamGroups tg on wo.WONumber = tg.WONumber
	where
		(@Date1 is null or (@Date1 is not null and (
					(CallDate >= @Date1 and CallDate < @Date2)
					OR (CompletedDate >= @Date1 and CompletedDate < @Date2)
					OR (BatchDate >= @Date1 and BatchDate < @Date2)
					OR (TransBatchDate >= @Date1 and TransBatchDate < @Date2))))
		and (@WONumber is null or (@WoNUmber is not null and @Wonumber=wo.WONumber))
	ORDER BY WONumber

END
GO
/****** Object:  StoredProcedure [dbo].[spWOAnalysisReport_Labor]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- [spWOAnalysisReport_Labor] @Date1='1/1/2024', @Date2='5/31/2024'
-- [spWOAnalysisReport_Labor] @WONumber=493955

-- Filter 
-- -- By Posted Month(s)- one or more
-- -- Status=Work Completed
-- -- Category in (Repairs, Violation)
-- -- Vendor = Century Maintenance
-- SUM the Invoice Price


CREATE   PROCEDURE [dbo].[spWOAnalysisReport_Labor]
	@Date1 as DateTime = NULL,
	@Date2 as DateTime = NULL,
	@WONumber int = NULL
AS 
BEGIN

	SELECT 
		wo.WONumber, 
		wo.JobStatus, 
		wo.PostedMonth,
		isnull(format(wo.CompletedDate, 'MM/dd/yyyy'),'') as CompletedDate,
		wo.Category, 
		wo.POVendors, 
		l.FullName_Calc as LaborerName, 
		
		wl.HrsReg, wl.HrsOT, wl.CostReg, wl.CostOT, 
		isnull(wl.BonusCalc, 0.00) as Bonus 
	
	FROM tblWorkOrders wo
		left join vwWorkOrderLaborers wl on wo.WONumber = wl.WONumber
		inner join tblLaborers l on wl.LaborerID = l.LaborerID
	
	WHERE
		(@Date1 is null or (@Date1 is not null and (
					(CallDate >= @Date1 and CallDate < @Date2)
					OR (CompletedDate >= @Date1 and CompletedDate < @Date2)
					OR (BatchDate >= @Date1 and BatchDate < @Date2)
					OR (TransBatchDate >= @Date1 and TransBatchDate < @Date2))))
		and (@WONumber is null or (@WoNUmber is not null and @Wonumber=wo.WONumber))
	ORDER BY WONumber, l.FullName_Calc

END
GO
/****** Object:  StoredProcedure [dbo].[spWOAnalysisReport_LaborerTeamSubtotals]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- [spWOAnalysisReport_LaborerTeamSubtotals] @PostedMonth = '2024-03' 
-- [spWOAnalysisReport_LaborerTeamSubtotals] @WONumber=488609 
-- 488609


CREATE   procedure [dbo].[spWOAnalysisReport_LaborerTeamSubtotals]
	@Date1 as DateTime = NULL,
	@Date2 as DateTime = NULL,
	@WONumber int = NULL,
	@PostedMonth varchar(10) = NULL
AS 
BEGIN

	select 
		isnull(wo.PostedMonth,'') as PostedMonth,
		isnull(tg.TeamGrouping,'') as TeamCode, 
		sum(wo.InvoicePrice) as SubTotalInvoicePrices
	from tblWorkOrders wo
		left join vwWOTeamGroups tg on wo.WONumber = tg.WONumber
	WHERE
		(@Date1 is null or (@Date1 is not null and (
					(CallDate >= @Date1 and CallDate < @Date2)
					OR (CompletedDate >= @Date1 and CompletedDate < @Date2)
					OR (BatchDate >= @Date1 and BatchDate < @Date2)
					OR (TransBatchDate >= @Date1 and TransBatchDate < @Date2))))
		and (@WONumber is null or (@WoNUmber is not null and @Wonumber=wo.WONumber))
		and (@PostedMonth is null or (@PostedMonth is not null and @PostedMonth=wo.PostedMonth))
	group by wo.PostedMonth, tg.TeamGrouping
	order by PostedMonth, tg.TeamGrouping

END
GO
/****** Object:  StoredProcedure [dbo].[spWOAnalysisReport_Lookup_Laborers]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[spWOAnalysisReport_Lookup_Laborers]
AS
	select LastName, FirstName, LWSalariedHourlyRate, LWSmJobMinRateAdj, LWOTRate, 
		LWMaterialRate, BonusFactor --isnull(TeamCode,'') as TeamCode
	from tblLaborers order by LastName, FirstName
GO
/****** Object:  StoredProcedure [dbo].[spWOAnalysisReport_LookupValues]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[spWOAnalysisReport_LookupValues]
AS
	select Category, KeyString, isnull(KeyString2,''), KeyValue 
	from tblLookupValues order by category, keystring, KeyString2
GO
/****** Object:  StoredProcedure [dbo].[spWorkOrderUpdate]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- select rowupdatedate from tblworkorders where wonumber=498833

CREATE             PROCEDURE [dbo].[spWorkOrderUpdate]
	@WORowID int = NULL,
	@WONumber int = NULL,
	@CompleteDate datetime = NULL,
	@CallDate datetime = NULL,
	@SchedDate datetime = NULL,
	@JobStatus varchar(50) = NULL,
	@Category varchar(50) = NULL,
	@BatchID bigint = null,
	@BriefDesc varchar(1000) = NULL,
	@ExpenseType varchar(50) = NULL,
	@yardiCreateDate datetime = NULL,
	@yardiUpdatedDate datetime = NULL
	
AS
BEGIN

	-- INSERT the blank record if it does not exist
	IF (SELECT count(WONumber) from tblWorkOrders WHERE WONumber=@WONumber) = 0  -- New Record
		INSERT INTO tblWorkOrders(WONumber) VALUES(@WONumber)

	-- Update the record only if what we are reading in is newer
	UPDATE tblWorkOrders Set
		CompletedDate = @CompleteDate,
		DateOfSale = CASE WHEN isnull(@CompleteDate,'1/1/1900') < isnull(DateOfSale,'1/1/2100') THEN @CompleteDate ELSE DateOfSale END,
		CallDate = @CallDate,
		SchedDate = @SchedDate,
		JobStatus = @JobStatus,
		Category = @Category,
		BatchID = @BatchID,
		BriefDesc = @BriefDesc,
		ExpenseType = @ExpenseType,
		yardiCreateDate = @yardiCreateDate,
		yardiUpdateDate = @yardiUpdatedDate,
		rowUpdateDate = getdate()
	WHERE 
		WONumber = @WONumber
		--and isnull(rowUpdateDate,'1/1/1900') < @yardiUpdatedDate
		and (
			CompletedDate <> @CompleteDate
			or CallDate <> @CallDate
			or SchedDate <> @SchedDate
			or JobStatus <> @JobStatus
			or Category <> @Category
			or BatchID <> @BatchID
			or BriefDesc <> @BriefDesc
			or ExpenseType <> @ExpenseType
			)
END
GO
/****** Object:  StoredProcedure [dbo].[spYardiPODetailsUpdate]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE procedure [dbo].[spYardiPODetailsUpdate]
/* Only some of the parameters are used - this is for compatibility with some other procedures */
	@POItemRowID int = NULL,
	@YardiMM2PODetID bigint = NULL,  
	@PONumber int = NULL,
	@WONumber int = NULL,
	@Vendor varchar(250) = NULL,
	@QtyOrdered decimal(10,2) = 0.00,
	@UnitPrice decimal(10,2) = 0.00,
	@TotalCost decimal(10,2) = 0.00,
	@OrderDate datetime = NULL,
	@ReceivedDate datetime = NULL,
	@ItemCode varchar(15) = NULL,
	@ItemDesc varchar(200) = NULL,
	@ExpenseType varchar(50) = NULL,
	@isSeedItem bit = 0,
	@client varchar(250) = NULL,
	@VendorCode varchar(25) = NULL, -- Not Used
	@POAmount decimal(10,2) = NULL, -- Not Used
	@WOAndInvoiceAmt decimal(10,2) = NULL -- Not Used

AS
BEGIN

	/* Make sure the PO is in the tblPurchaseOrders as well */
	IF (@PONumber not in (SELECT PONumber from tblPurchaseOrders)) 
		BEGIN
		INSERT INTO tblPurchaseOrders(PONumber, WONumber, VendorCode, VendorName, expenseType, POAmount, WOAndInvoiceAmt, OrderDate, ReceivedDate, TotalCostOfItems)
		SELECT @PONumber, @WONumber, @VendorCode, @Vendor, @ExpenseType, @POAmount, @WOAndInvoiceAmt, @OrderDate, @ReceivedDate, @TotalCost
		END
	ELSE
		BEGIN
		UPDATE tblPurchaseOrders Set
			WONumber = @WONumber, 
			VendorCode = @VendorCode, 
			VendorName = @Vendor, 
			expenseType = @ExpenseType, 
			POAmount = @POAmount, 
			WOAndInvoiceAmt = @WOAndInvoiceAmt, 
			OrderDate = @OrderDate, 
			ReceivedDate = @ReceivedDate, 
			TotalCostOfItems = @TotalCost
		WHERE PONumber = @PONumber
		END
		
	IF (@YardiMM2PODetID is not null and (SELECT COUNT(*) FROM tblPurchaseOrders_Details WHERE YardiPODetailRowID = @YardiMM2PODetID) = 0)
		BEGIN

		INSERT INTO tblPurchaseOrders_Details(YardiPODetailRowID, PONumber, QTYOrdered, UnitPrice, OrderDate, ItemCode, ItemDesc, ReceivedDate)
		SELECT @YardiMM2PODetID, @PONumber, @QtyOrdered, @UnitPrice, @OrderDate, @ItemCode, @ItemDesc, @ReceivedDate
				
		END
	ELSE
		BEGIN

		UPDATE tblPurchaseOrders_Details Set 
			PONumber = @PONumber,
			QTYOrdered = @QtyOrdered,
			UnitPrice = @UnitPrice,
			OrderDate = @OrderDate,
			ItemCode = @ItemCode,
			ItemDesc = @ItemDesc,
			ReceivedDate = @ReceivedDate
		WHERE YardiPODetailRowID = @YardiMM2PODetID
			AND (
				@YardiMM2PODetID is not null
				AND (PONumber <> @PONumber
					OR QTYOrdered <> @QtyOrdered
					OR UnitPrice <> @UnitPrice
					OR ((case when isnull(OrderDate, '1970-01-01') <> isnull(@OrderDate, '1970-01-01') then 1 else 0 end) = 1)
					OR ItemCode <> @ItemCode
					OR ((case when isnull(ReceivedDate, '1970-01-01') <> isnull(@ReceivedDate, '1970-01-01') then 1 else 0 end) = 1)
					)
				)
		END
END
GO
/****** Object:  StoredProcedure [dbo].[spYardiPOs]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








CREATE   PROCEDURE [dbo].[spYardiPOs]
	@Yardi_POListID int = NULL,
	@WONumber int = NULL
AS
BEGIN

	SELECT * 
	FROM tblImport_Yardi_POs y 
	where 
		(@Yardi_POListID is null or (@Yardi_POListID is not null and @Yardi_POListID = y.Yardi_POListID))
		AND (@WONumber is null or (@WONumber is not null and @WONumber = y.WONumber))

END
GO
/****** Object:  StoredProcedure [dbo].[spYardiPOsInvItemsUpdate]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO









CREATE     PROCEDURE [dbo].[spYardiPOsInvItemsUpdate]
	@POItemRowID int = NULL,
	@YardiMM2PODetID bigint = NULL,  
	@PONumber int = NULL,
	@WONumber int = NULL,
	@Vendor varchar(250) = NULL,
	@QtyOrdered decimal(10,2) = 0.00,
	@UnitPrice decimal(10,2) = 0.00,
	@TotalCost decimal(10,2) = 0.00,
	@OrderDate datetime = NULL,
	@ReceivedDate datetime = NULL,
	@ItemCode varchar(15) = NULL,
	@ItemDesc varchar(200) = NULL,
	@ExpenseType varchar(50) = NULL,
	@isSeedItem bit = 0,
	@client varchar(250) = NULL,
	@VendorCode varchar(25) = NULL,
	@POAmount decimal(10,2) = NULL,
	@WOAndInvoiceAmt decimal(10,2) = NULL
AS
BEGIN

	-- We are only inserting at this point - Nothing updated in Yrdi will reflect here
	IF @POItemRowID is NULL 
		BEGIN
			INSERT INTO tblImport_Inv_Yardi_POItems( YardiMM2PODetID, PONumber, WONumber, QtyOrdered, UnitPrice, TotalCost, OrderDate, ReceivedDate, ItemCode, ItemDesc, ExpenseType, isSeedItem, Vendor, Client, VendorCode, POAmount, WOAndInvoiceAmt)
			SELECT @YardiMM2PODetID, @PONumber, @WONumber, @QtyOrdered, @UnitPrice, @TotalCost, @OrderDate, @ReceivedDate, @ItemCode, @ItemDesc, @ExpenseType, @isSeedItem, @Vendor, @Client, @VendorCode, @POAmount, @WOAndInvoiceAmt
			WHERE NOT EXISTS (
				SELECT 1 FROM tblPurchaseOrders_Details WHERE YardiPODetailRowID = @YardiMM2PODetID
				)

			SELECT @POItemRowID = SCOPE_IDENTITY()
		END


END
GO
/****** Object:  StoredProcedure [dbo].[spYardiPOsUpdate]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE     PROCEDURE [dbo].[spYardiPOsUpdate]
	@Yardi_POListID int = NULL,
	@WONumber int = NULL,
	@CallDate datetime = NULL,
	@PONumber int = NULL,
	@VendorCode varchar(25) = NULL,
	@VendorName varchar(250) = NULL,
	@InvoiceDate datetime = NULL,
	@AcctCode varchar(20) = NULL,
	@AcctCategory varchar(20) = NULL,
	@AcctDesc varchar(75) = NULL,
	@IndivPOTotal decimal(10,2) = 0.00,
	@POAmount decimal(10,2) = 0.00,
	@WOAndInvoiceAmt decimal(10,2) = 0.00,
	@LaborPricingOutside decimal(10,2) = 0.00,
	@expenseType varchar(50) = NULL,
	@requestedBy varchar(100) = NULL,
	@PODate datetime = NULL,
	@createdBy varchar(25) = NULL,
	@CreateDate DateTime = getdate,

	@NoReturn bit = 0  -- 0=Return a row of the inserted or updated data; 1=Return nothing
AS
BEGIN

	IF @Yardi_POListID is NULL 
		BEGIN
			INSERT INTO tblImport_Yardi_POs
			( WONumber, CallDate, PONumber, VendorCode, VendorName, InvoiceDate, AcctCode,
				AcctCategory, AcctDesc, IndivPOTotal, POAmount, WOAndInvoiceAmt, LaborPricingOutside,
				expenseType, requestedBy, PODate, createdBy, createDate )
			VALUES( @WONumber, @CallDate, @PONumber, @VendorCode, @VendorName, @InvoiceDate, @AcctCode,
					@AcctCategory, @AcctDesc, @IndivPOTotal, @POAmount, @WOAndInvoiceAmt, @LaborPricingOutside,
					@expenseType, @requestedBy, @PODate, @createdBy, getdate() )

			SELECT @Yardi_POListID = SCOPE_IDENTITY()
		END
	ELSE
		BEGIN
			UPDATE tblImport_Yardi_POs Set 
				WONumber = @WONumber, 
				CallDate = @CallDate, 
				PONumber = @PONumber, 
				VendorCode = @VendorCode, 
				VendorName = @VendorName, 
				InvoiceDate = @InvoiceDate, 
				AcctCode = @AcctCode,
				AcctCategory = @AcctCategory, 
				AcctDesc = @AcctDesc, 
				IndivPOTotal = @IndivPOTotal,
				POAmount = @POAmount, 
				WOAndInvoiceAmt = @WOAndInvoiceAmt, 
				LaborPricingOutside = @LaborPricingOutside,
				expenseType = @expenseType, 
				requestedBy = @requestedBy, 
				PODate = @PODate, 
				createdBy = @createdBy, 
				createDate = @createDate
		
			WHERE Yardi_POListID=@Yardi_POListID
		END

	IF @NoReturn = 0 EXEC dbo.spYardiPOs @Yardi_POListID=@Yardi_POListID

END
GO
/****** Object:  StoredProcedure [dbo].[spYardiWOs]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







CREATE   PROCEDURE [dbo].[spYardiWOs]
	@WOListRowID int = NULL,
	@WONumber int = NULL
AS
BEGIN

	SELECT * 
	FROM tblImport_Yardi_WOList y 
	where 
		(@WOListRowID is null or (@WOListRowID is not null and @WOListRowID = y.WOListRowID))
		AND (@WONumber is null or (@WONumber is not null and @WONumber = y.WONumber))

END
GO
/****** Object:  StoredProcedure [dbo].[spYardiWOsInvItemsUpdate]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE     PROCEDURE [dbo].[spYardiWOsInvItemsUpdate]
	@WOItemRowID int = NULL,
	@WONumber int = NULL,
	@Category varchar(50) = NULL,
	@BriefDesc varchar(500) = NULL,
	@ItemCode varchar(15) = NULL,
	@ItemDesc varchar(50) = NULL,
	@Qty int = NULL,
	@UnitPrice decimal(10,2) = 0.00,
	@TotalAmt decimal(10,2) = 0.00,
	@CompleteDate datetime = NULL,
	@isSeedItem bit = 0,
	@vendor varchar(250) = NULL,
	@Client varchar(250) = NULL
AS
BEGIN

	IF @WOItemRowID is NULL 
		BEGIN
			INSERT INTO tblImport_Inv_Yardi_WOItems( WONumber, Category, BriefDesc, ItemCode, ItemDesc, Qty, UnitPrice, TotalAmt, CompleteDate, isSeedItem, vendor, client)
			VALUES(@WONumber, @Category, @BriefDesc, @ItemCode, @ItemDesc, @Qty, @UnitPrice, @TotalAmt, @CompleteDate, @isSeedItem, @Vendor, @Client)

			SELECT @WOItemRowID = SCOPE_IDENTITY()
		END
	ELSE
		BEGIN
			UPDATE tblImport_Inv_Yardi_WOItems Set 
				WONumber = @WONumber, 
				Category = @Category, 
				BriefDesc = @BriefDesc, 
				ItemCode = @ItemCode, 
				ItemDesc = @ItemDesc, 
				Qty = @Qty, 
				UnitPrice = @UnitPrice, 
				TotalAmt = @TotalAmt, 
				CompleteDate = @CompleteDate,
				isSeedItem = @isSeedItem,
				vendor = @Vendor,
				client = @Client
			WHERE WOItemRowID=@WOItemRowID
		END

END
GO
/****** Object:  StoredProcedure [dbo].[spYardiWOsUpdate]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE     PROCEDURE [dbo].[spYardiWOsUpdate]
	@WOListRowID int = NULL,
	@WONumber int = NULL,
	@BuildingNum varchar(50) = NULL,
	@AptNum varchar(50) = NULL,
	@JobStatus varchar(50) = NULL,
	@Category varchar(50) = NULL,
	@CallDate datetime = NULL,
	@StartDate datetime = NULL,
	@SchedDate datetime = NULL,
	@CompleteDate datetime = NULL,
	@BatchID bigint = NULL,
	@BatchDate datetime = NULL,
	@TransBatchDate datetime = NULL,
	@Employee varchar(100) = NULL,
	@BriefDesc varchar(1000) = NULL,
	@Quantity decimal(10,2) = 0.00,
	@Code varchar(250) = NULL,
	@FullDesc varchar(max) = NULL,
	@UnitPrice decimal(10,2) = 0.00,
	@PayAmt decimal(10,2) = NULL,
	@PostedMonth varchar(10) = NULL,
	@YardiWODetailRowID int = NULL,

	@Createdby varchar(20) = NULL,
	@CreateDate DateTime = getdate,

	@NoReturn bit = 0  -- 0=Return a row of the inserted or updated data; 1=Return nothing
AS
BEGIN

	IF @WOListRowID is NULL 
		BEGIN
			INSERT INTO tblImport_Yardi_WOList(WONumber, BuildingNum, AptNum, JobStatus, Category, CallDate, StartDate, 
					SchedDate, CompleteDate, BatchID, BatchDate, TransBatchDate, Employee, BriefDesc, Quantity, Code, FullDesc, UnitPrice, PayAmt, PostedMonth,
					WODetailRowID,
					createdBy, createDate)
			VALUES(@WONumber, @BuildingNum, @AptNum, @JobStatus, @Category, @CallDate, @StartDate, 
					@SchedDate, @CompleteDate, @BatchID, @BatchDate, @TransBatchDate, @Employee, @BriefDesc, @Quantity, @Code, @FullDesc, @UnitPrice, @PayAmt, @PostedMonth,
					@YardiWODetailRowID,
					@createdBy, getdate())

			SELECT @WOListRowID = SCOPE_IDENTITY()
		END
	ELSE
		BEGIN
			UPDATE tblImport_Yardi_WOList Set 
				WONumber = @WONumber, 
				BuildingNum = @BuildingNum, 
				AptNum = @AptNum, 
				JobStatus = @JobStatus, 
				Category = @Category, 
				CallDate = @CallDate, 
				StartDate = @StartDate, 
				SchedDate = @SchedDate, 
				CompleteDate = @CompleteDate, 
				BatchID = @BatchID,
				BatchDate = @BatchDate,
				TransBatchDate = @TransBatchDate,
				Employee = @Employee, 
				BriefDesc = @BriefDesc, 
				Quantity = @Quantity, 
				Code = @Code, 
				FullDesc = @FullDesc, 
				UnitPrice = @UnitPrice, 
				PayAmt = @PayAmt, 
				PostedMonth = @PostedMonth,
				WODetailRowID = @YardiWODetailRowID,
				createdBy = @createdBy, 
				createDate = @createDate
			WHERE WOListRowID=@WOListRowID
		END

	IF @NoReturn = 0 EXEC dbo.spYardiWOs @WOListRowID=@WOListRowID

END
GO
/****** Object:  StoredProcedure [dbo].[xxx_spPurchaseOrderItems_ExceptionsUpdate]    Script Date: 4/29/2025 5:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE     PROCEDURE [dbo].[xxx_spPurchaseOrderItems_ExceptionsUpdate]
	@POItemExRowID int = NULL,
	@YardiMM2PODetID bigint = NULL,
	@PONumber int = NULL,
	@WONumber int = NULL,
	@Vendor varchar(250) = NULL,
	@QtyOrdered decimal(10,2) = 0.00,
	@UnitPrice decimal(10,2) = 0.00,
	@TotalCost decimal(10,2) = 0.00,
	@OrderDate datetime = NULL,
	@ReceivedDate datetime = NULL,
	@ItemCode varchar(15) = NULL,
	@ItemDesc varchar(200) = NULL,
	@ExpenseType varchar(50) = NULL,
	@client varchar(250) = NULL,
	@VendorCode varchar(25) = NULL,
	@POAmount decimal(10,2) = NULL,
	@WOAndInvoiceAmt decimal(10,2) = NULL
AS
BEGIN

	IF @POItemExRowID is NULL   -- We should only be inserting at this time
		BEGIN
			INSERT INTO tblPurchaseOrderItems_Exceptions( YardiMM2PODetID, PONumber, WONumber, QtyOrdered, UnitPrice, TotalCost, OrderDate, ReceivedDate, ItemCode, ItemDesc, ExpenseType, Vendor, Client, VendorCode, POAmount, WOAndInvoiceAmt)
			SELECT @YardiMM2PODetID, @PONumber, @WONumber, @QtyOrdered, @UnitPrice, @TotalCost, @OrderDate, @ReceivedDate, @ItemCode, @ItemDesc, @ExpenseType, @Vendor, @Client, @VendorCode, @POAmount, @WOAndInvoiceAmt
			WHERE @YardiMM2PODetID not in (SELECT YardiMM2PODetID FROM tblPurchaseOrderItems_Exceptions)
		END

END
GO
