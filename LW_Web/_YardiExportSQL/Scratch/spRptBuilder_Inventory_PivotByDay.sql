USE [lemlewolff]
GO

/****** Object:  StoredProcedure [dbo].[spRptBuilder_Inventory_PivotByDay]    Script Date: 2/4/2025 3:27:35 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





-- spRptBuilder_Inventory_PivotByDay '10/1/2024', '11/1/2024'

ALTER       procedure [dbo].[spRptBuilder_Inventory_PivotByDay]
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
			'[' + format(coalesce(m.DateOfSale, m.ReceivedDate, aa.receivedDate), 'MM-dd-yy ') +
			CASE WHEN isnull(m.WONumber,0) = 0 
				THEN 'PO' + cast(m.PONumber as varchar(10)) 
				ELSE 'WO' + cast(m.WONumber as varchar(10)) 
				END + ']'  as header
        FROM tblInventoryTracking m
			left join #tblADP_AddlWOs aa on m.WONumber = aa.WONumber
		where (coalesce(m.DateOfSale, m.ReceivedDate, aa.receivedDate) is not null
			and coalesce(m.DateOfSale, m.ReceivedDate, aa.receivedDate) >= @StartDate
			and coalesce(m.DateOfSale, m.ReceivedDate, aa.receivedDate) < @EndDate)
			and ((m.Source='PO' and isnull(m.WONumber,0) = 0) or m.Source <> 'PO' )
        ) as a 

/* Fill from tblInventoryTracking which has inventory from Yardi and Sortly */
	
	select 
		upper(lv.KeyString) as InventoryCategory, 
		m.ItemCode, 
		isnull(si.itemName, m.ItemDesc) as [Description], 
		si.UnitPrice, 
		format(coalesce(m.DateOfSale, m.ReceivedDate, aa.receivedDate), 'MM-dd-yy ') +
			CASE WHEN isnull(m.WONumber,0) = 0 
				THEN 'PO' + cast(m.PONumber as varchar(10)) 
				ELSE 'WO' + cast(m.WONumber as varchar(10)) 
				END  as header,
		sum(m.Quantity) as Quantity,
		isnull(ib.seedCount,0) as QtyStart,
		qt.QtyTotalPerItem + isnull(ib.seedCount,0) as QtyTotal,
		cast(si.UnitPrice * (isnull(QtyTotalPerItem,0) + isnull(ib.seedCount,0)) as decimal(10,2)) as PriceTotal
	into #tmp 
	from tblInventoryTracking m  -- Contains YARDI and SORTLY
		left join tblLookupValues lv on left(m.ItemCode,2) = cast(lv.keyValue as int) and lv.Category='InvCategoryID'
		left join tblSortlyInventory si on m.itemCode = si.ItemCode
		left join #tblADP_AddlWOs aa on m.WONumber = aa.WONumber
		left join tblWorkOrders wo on m.WONumber = wo.WONumber
		left join (
			select Code, sum(isnull(PhysicalCount,0)) as seedCount 
			from tblPhysicalInventory as ib
			where isnull(code,'') <> '' and PhysicalCount is not null and AsOfDate = @PhysInventoryDate
			group by Code
			) as ib on m.ItemCode = ib.Code
		left join (	
			select mm.ItemCode, sum(mm.Quantity) as QtyTotalPerItem  
			FROM tblInventoryTracking mm
				left join #tblADP_AddlWOs aaa on mm.WONumber = aaa.WONumber
			WHERE (coalesce(mm.DateOfSale, mm.ReceivedDate, aaa.receivedDate) is not null
					and coalesce(mm.DateOfSale, mm.ReceivedDate, aaa.receivedDate) >= @StartDate 
					and coalesce(mm.DateOfSale, mm.ReceivedDate, aaa.receivedDate) < @EndDate)
					OR 
					(aaa.WONumber is not null) -- The WO is found in the temp ADP table
				and (coalesce(mm.DateOfSale, mm.ReceivedDate, aaa.receivedDate) is not null)  -- added because NULL dates were being included
			group by mm.ItemCode ) qt on m.itemcode = qt.itemcode 
	where 
		upper(lv.KeyString) not in (@ignoreCategory)   -- InventoryCategory
		and -- Only include Purchase Order sources without a Work Order number and everything else
			((m.Source='PO' and isnull(m.WONumber,0) = 0) or m.Source <> 'PO' )
		and isnull(wo.Category,'') not in ('APH-Plumbing', 'APH-Boiler')  -- Instructed to not pick up these cateogries for this report [10/17/2024]
		and ((coalesce(m.DateOfSale, m.ReceivedDate, aa.receivedDate) is not null
				and coalesce(m.DateOfSale, m.ReceivedDate, aa.receivedDate) >= @StartDate
				and coalesce(m.DateOfSale, m.ReceivedDate, aa.receivedDate) < @EndDate) 
			or (aa.WONumber is not null)) -- The WO is found in the temp ADP table
		
		--and m.WONumber in (506303, 506484)
	    --and m.itemCode in ('10-00400')
	
	group by 
		lv.KeyString, m.ItemCode, si.unitprice, 
		isnull(si.itemName, m.ItemDesc),isnull(ib.seedCount,0),
		QtyTotalPerItem + isnull(ib.seedCount,0),
		cast(si.UnitPrice * (isnull(QtyTotalPerItem,0) + isnull(ib.seedCount,0)) as decimal(10,2)),
		format(coalesce(m.DateOfSale, m.ReceivedDate, aa.receivedDate), 'MM-dd-yy ') +
			CASE WHEN isnull(m.WONumber,0) = 0 
				THEN 'PO' + cast(m.PONumber as varchar(10)) 
				ELSE 'WO' + cast(m.WONumber as varchar(10)) END


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

select * from #tmp2

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

SELECT DISTINCT m.WONumber, 
	isnull(case	when adp.Laborers is null 
			then wo.POVendors 
			else adp.Laborers + isnull(' / ' + wo.POVendors,'') 
			end, m.Category) as [Laborers]
FROM tblInventoryTracking m
	left join tblWorkOrders wo on m.WONumber = wo.WONumber
	left join #tmpADP adp on m.WONumber = adp.WONumber
where 
	isnull(m.WONumber,0) > 0
	and isnull(wo.Category,'') not in ('APH-Plumbing', 'APH-Boiler')
	and (isnull(m.ReceivedDate, m.DateOfSale) is not null
		and isnull(m.ReceivedDate, m.DateOfSale) >= @StartDate
		and isnull(m.ReceivedDate, m.DateOfSale) < @EndDate
		)
		OR
		(m.WONumber in (SELECT WONumber from #tblADP_AddlWOs)
	)
order by WONumber

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
SELECT WONumber, PONumber, Vendor, QtyOrdered, UnitPrice, TotalCost, 
	format(OrderDate, 'MM/dd/yy') as OrderDate, format(ReceivedDate, 'MM/dd/yy') as ReceivedDate, 
	ItemCode, ItemDesc, ExpenseType, Client
FROM tblPurchaseOrderItems_Exceptions m
where 
	(m.ReceivedDate is not null
	and m.ReceivedDate >= @StartDate
	and m.ReceivedDate < @EndDate)
order by WONumber, PONumber


/*---------------------------------------------*/
/* Cleanup */
DROP TABLE #tmp
DROP TABLE #tmp2
DROP TABLE #tmpADP
DROP TABLE #tblADP_AddlWOs

END
GO


