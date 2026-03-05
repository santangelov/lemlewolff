USE [lemlewolff]
GO

/****** Object:  StoredProcedure [dbo].[spReport_ArrearsTracker_Daily]    Script Date: 3/5/2026 12:43:55 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- spReport_ArrearsTracker_Daily @AsOfDate='3/2/2026', @FilterIsList_Posting=1

ALTER PROCEDURE [dbo].[spReport_ArrearsTracker_Daily]
    @AsOfDate                    date,
    @BuildingCode                varchar(20) = NULL,
    @FilterOnlyExcel             bit = 1,
    @FilterIsList_Posting        bit = 0,
    @FilterIsList_Aquinas        bit = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @RequestedAsOfDate date;
    DECLARE @Cutoff90 date;
    DECLARE @ResolvedAsOfDate date;
    DECLARE @TenantSnapAsOf_Resolved date;

    IF @AsOfDate IS NULL
    BEGIN
        RAISERROR('spReport_ArrearsTracker_Daily: AsOfDate is required.', 16, 1);
        RETURN;
    END

    SET @RequestedAsOfDate = @AsOfDate;
    SET @Cutoff90 = DATEADD(day, -90, CAST(GETDATE() AS date));

    IF @RequestedAsOfDate < @Cutoff90
    BEGIN
        RAISERROR('spReport_ArrearsTracker_Daily: AsOfDate is older than the rolling 90-day daily window.', 16, 1);
        RETURN;
    END

    /* Resolve to closest prior daily snapshot date within the 90-day window. */
    SELECT @ResolvedAsOfDate = MAX(s.AsOfDate)
    FROM dbo.tblTenantAR_DailySnapshot s
    WHERE s.AsOfDate <= @RequestedAsOfDate
      AND s.AsOfDate >= @Cutoff90;

    IF @ResolvedAsOfDate IS NULL
    BEGIN
        RAISERROR('spReport_ArrearsTracker_Daily: No daily snapshot exists on or before requested AsOfDate within the rolling 90-day window.', 16, 1);
        RETURN;
    END

    /* Resolve month-end tenant snapshot date used for legal status/note/dayCounter fields. */
    SELECT @TenantSnapAsOf_Resolved = MAX(CAST(ts.ValidFrom AS date))
    FROM dbo.tblTenants_Snapshots ts
    WHERE CAST(ts.ValidFrom AS date) <= @ResolvedAsOfDate;

    /* =========================================
       Attorney / LawFirm resolution (optimized)
       - Materialize fnAttorneyResolve once
       - Join to tblLawFirms ONCE to fetch LawFirmCode (no name joins)
       ========================================= */
    IF OBJECT_ID('tempdb..#AttorneyResolved') IS NOT NULL DROP TABLE #AttorneyResolved;

    SELECT
        r.yardiLegalRowID,
        r.yardiPersonRowID,
        r.yardiUnitRowID,
        r.yardiPropertyRowID,
        r.AttorneyID,
        r.AttorneyLabel,
        r.LawFirmID,
        lf.LawFirmCode
    INTO #AttorneyResolved
    FROM dbo.fnAttorneyResolve(@ResolvedAsOfDate) r
    LEFT JOIN dbo.tblLawFirms lf
        ON lf.LawFirmID = r.LawFirmID;

    /* Lightweight indexes to help per-row matching */
    CREATE NONCLUSTERED INDEX IX_AR_Person
        ON #AttorneyResolved(yardiPersonRowID)
        INCLUDE (AttorneyLabel, LawFirmCode, yardiLegalRowID, yardiUnitRowID, yardiPropertyRowID);

    CREATE NONCLUSTERED INDEX IX_AR_Legal
        ON #AttorneyResolved(yardiLegalRowID)
        INCLUDE (AttorneyLabel, LawFirmCode, yardiPersonRowID, yardiUnitRowID, yardiPropertyRowID);

    CREATE NONCLUSTERED INDEX IX_AR_UnitProp
        ON #AttorneyResolved(yardiUnitRowID, yardiPropertyRowID)
        INCLUDE (AttorneyLabel, LawFirmCode, yardiPersonRowID, yardiLegalRowID);

    CREATE NONCLUSTERED INDEX IX_AR_Prop
        ON #AttorneyResolved(yardiPropertyRowID)
        INCLUDE (AttorneyLabel, LawFirmCode, yardiPersonRowID, yardiLegalRowID, yardiUnitRowID);

    SELECT
        ISNULL(p.portfolioName, '') AS [Portfolio],
        p.buildingCode AS [Property],
        u.AptNumber AS [Unit],
        COALESCE(t.tenantCode, '(unit-only / no tenant)') AS [Tenant Account],

		(  /*  CREATE A FULL ADDRESS WITH THE UNIT NUMBER */
		  TRIM(UPPER(CONCAT(
			CASE 
			  WHEN ISNULL(p.[addr2], '') = '' THEN '' 
			  ELSE TRIM(p.[addr2]) 
			END,

			CASE
			  WHEN ISNULL(u.AptNumber, '') = '' OR ISNULL(p.[addr2], '') = '' THEN ''
			  ELSE ', Unit ' + TRIM(u.AptNumber)
			END,

			CASE 
			  WHEN ISNULL(p.[addr3], '') = '' THEN '' 
			  ELSE ', ' + TRIM(p.[addr3]) 
			END,

			CASE 
			  WHEN ISNULL(p.[addr4], '') = '' THEN '' 
			  ELSE ', ' + TRIM(p.[addr4]) 
			END,

			CASE 
			  WHEN ISNULL(p.[City], '') = '' THEN '' 
			  ELSE ', ' + TRIM(p.[City]) 
			END,

			CASE 
			  WHEN ISNULL(p.[stateCode], '') = '' THEN '' 
			  ELSE ', ' + ISNULL(p.[stateCode], '') 
			END,

			CASE
			  WHEN ISNULL(p.[zipCode], '') = '' THEN ''
			  ELSE ' ' + ISNULL(p.[zipCode], '')
			END
		  )))
		) AS FullAddressWithUnit,
        CASE
            WHEN t.yardiPersonRowID IS NULL THEN '(unit-only / no tenant)'
            ELSE CONCAT(
                ISNULL(t.lastName, ''),
                CASE WHEN t.lastName IS NOT NULL AND t.firstName IS NOT NULL THEN ', ' ELSE '' END,
                ISNULL(t.firstName, '')
            )
        END AS [Name],
        s.endingBalance AS [Ending Balance],
        ISNULL(NULLIF(LTRIM(RTRIM(ts.LegalDisplay)), ''), '') AS [Current Legal Status],
        CASE
            WHEN ts.lastLegalNoteDate IS NULL OR ts.lastLegalNoteDate = '19000101' THEN ''
            ELSE CONVERT(varchar(20), ts.lastLegalNoteDate, 120)
        END AS [Last Legal Note],
        ts.dayCounter AS [Day Counter],
        ISNULL(ar.AttorneyLabel, '') AS [Attorney],
        ISNULL(ar.LawFirmCode, '')   AS [Law Firm],
        CASE WHEN ISNULL(NULLIF(LTRIM(RTRIM(ts.LegalDisplay)), ''), '') = '' THEN 'No' ELSE 'Yes' END AS [Legal Active],
        CASE WHEN @ResolvedAsOfDate = @RequestedAsOfDate THEN 'Present' ELSE 'Resolved' END AS [Present As Of],
        CASE
            WHEN t.yardiPersonRowID IS NULL AND u.CurrentTenantYardiID IS NOT NULL
                THEN CONCAT(
                    'Missing tenant in import. (unit-only / no tenant) CurrentTenantYardiID ',
                    CAST(u.CurrentTenantYardiID AS varchar(20)),
                    ' not found in tblStg_Tenants/tblTenants.'
                )
            WHEN t.yardiPersonRowID IS NULL AND u.CurrentTenantYardiID IS NULL
                THEN 'Missing tenant in import. (unit-only / no tenant) No CurrentTenantYardiID available on unit.'
            ELSE ''
        END AS [Exclusion Reasons],
        CASE WHEN t.yardiPersonRowID IS NULL THEN 'Unknown' ELSE t.[status] END AS [Tenent Status],
        u.LeaseStartDate AS [Lease Start Date],
        u.LeaseEndDate AS [Lease End Date]

        -- DEBUG COLUMNS
        ,u.CurrentTenantYardiID
        ,@RequestedAsOfDate AS RequestedAsOfDate
        ,@ResolvedAsOfDate AS ResolvedSnapshotAsOfDate
        ,CASE WHEN @ResolvedAsOfDate = @RequestedAsOfDate THEN CAST(0 AS bit) ELSE CAST(1 AS bit) END AS IsResolvedFromPriorSnapshot
        ,'DAILY' AS ModeUsed
    FROM dbo.tblTenantAR_DailySnapshot s
        INNER JOIN dbo.tblProperties p ON p.yardiPropertyRowID = s.yardiPropertyRowID
        LEFT JOIN dbo.tblPropertyUnits u ON u.yardiUnitRowID = s.yardiUnitRowID
        LEFT JOIN dbo.tblTenants t ON t.yardiPersonRowID = s.yardiPersonRowID
        LEFT JOIN dbo.tblTenants_Snapshots ts
            ON ts.yardiPersonRowID = s.yardiPersonRowID
           AND CAST(ts.ValidFrom AS date) = @TenantSnapAsOf_Resolved

        /* Attorney/LawFirm resolution match preference (best match per row):
           1) legal match (if ts.legalID_yardi is available)
           2) person match
           3) unit+property match
           4) property match
        */
        OUTER APPLY (
            SELECT TOP (1)
                r.AttorneyLabel,
                r.LawFirmCode
            FROM #AttorneyResolved r
            WHERE
                   (r.yardiLegalRowID  IS NOT NULL AND ts.legalID_yardi IS NOT NULL AND r.yardiLegalRowID = ts.legalID_yardi)
                OR (r.yardiPersonRowID IS NOT NULL AND r.yardiPersonRowID = s.yardiPersonRowID)
                OR (r.yardiUnitRowID   IS NOT NULL AND r.yardiPropertyRowID IS NOT NULL
                    AND r.yardiUnitRowID = s.yardiUnitRowID AND r.yardiPropertyRowID = s.yardiPropertyRowID)
                OR (r.yardiPropertyRowID IS NOT NULL AND r.yardiPropertyRowID = s.yardiPropertyRowID)
            ORDER BY
                CASE
                    WHEN r.yardiLegalRowID  IS NOT NULL AND ts.legalID_yardi IS NOT NULL AND r.yardiLegalRowID = ts.legalID_yardi THEN 1
                    WHEN r.yardiPersonRowID IS NOT NULL AND r.yardiPersonRowID = s.yardiPersonRowID THEN 2
                    WHEN r.yardiUnitRowID   IS NOT NULL AND r.yardiPropertyRowID IS NOT NULL
                         AND r.yardiUnitRowID = s.yardiUnitRowID AND r.yardiPropertyRowID = s.yardiPropertyRowID THEN 3
                    WHEN r.yardiPropertyRowID IS NOT NULL AND r.yardiPropertyRowID = s.yardiPropertyRowID THEN 4
                    ELSE 99
                END
        ) ar
    WHERE s.AsOfDate = @ResolvedAsOfDate
      AND (@BuildingCode IS NULL OR p.buildingCode = @BuildingCode)
      AND (@FilterIsList_Posting = 0 OR p.isInList_Posting = 1)
      AND (@FilterIsList_Aquinas = 0 OR p.isInList_Aquinas = 1)
      AND (@FilterOnlyExcel = 0 OR s.endingBalance > 0)
    ORDER BY p.buildingCode, u.AptNumber;

END
GO


