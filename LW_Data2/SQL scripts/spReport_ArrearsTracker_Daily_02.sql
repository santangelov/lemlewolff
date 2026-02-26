USE [lemlewolff]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
Daily-mode Legal Arrears report (rolling 90-day window).

High-level behavior
- Returns DAILY ending balances for any requested date within the last 90 days (rolling window).
- If the exact requested date does not exist in dbo.tblTenantAR_DailySnapshot, resolves to the closest prior AsOfDate
  within the last 90 days and reports that as ResolvedSnapshotAsOfDate.
- Preserves existing building/list filters and @FilterOnlyExcel behavior.

Data sources (what each column is coming from)
- Ending Balance:
    dbo.tblTenantAR_DailySnapshot (authoritative for DAILY mode).
- Property / unit / lease / portfolio fields:
    dbo.tblProperties (portfolioName, buildingCode, list flags)
    dbo.tblPropertyUnits (AptNumber, LeaseStartDate, LeaseEndDate, CurrentTenantYardiID)
- Tenant display fields:
    dbo.tblTenants (tenantCode, first/last name, status)
    NOTE: tenants can be missing from imports; those rows are preserved and flagged as unit-only/no-tenant.
- Legal status / last legal note / day counter:
    dbo.tblTenants_Snapshots (month-end SCD snapshot) joined at @TenantSnapAsOf_Resolved (month-end <= resolved daily date).
    NOTE: this keeps existing behavior for legal fields; it does not attempt to derive legal status from daily sources.
- Attorney / Law Firm:
    Resolved from dbo.tblLegalRepresentation via dbo.fnAttorneyResolve(@AsOfDate):
      - dbo.tblLegalRepresentation (effective-dated representation assignments; can be populated via staging or manually)
      - dbo.tblAttorneys (AttorneyID -> DisplayName)
      - dbo.tblAttorneysLawFirms + dbo.tblLawFirms (effective-dated firm assignment)
    IMPORTANT: This report does NOT rely on tblTenants_Snapshots.attorneyLabel (it may be blank). Attorney/LawFirm are resolved
    directly from tblLegalRepresentation through fnAttorneyResolve.

If Attorney / Law Firm are blank
- No effective representation exists for the row’s scope as of the resolved daily date, OR no effective firm assignment exists.
To populate:
1) Insert/maintain dbo.tblLegalRepresentation rows with correct scope and effective dates.
   - Scope can be as specific as yardiLegalRowID, or as broad as yardiPersonRowID / unit / property.
2) Ensure dbo.tblAttorneys has AttorneyID referenced by tblLegalRepresentation (DisplayName used for Attorney column).
3) Ensure dbo.tblAttorneysLawFirms links AttorneyID -> LawFirmID with effective dates, and dbo.tblLawFirms has FirmName.

Performance note
- fnAttorneyResolve(@AsOfDate) is materialized once into #AttorneyResolved per execution, indexed, then used via OUTER APPLY.
  This avoids repeated function evaluation per row.
*/

ALTER   PROCEDURE [dbo].[spReport_ArrearsTracker_Daily]
    @AsOfDate                    date,
    @BuildingCode                varchar(20) = NULL,
    @FilterOnlyExcel             bit = 1,
    @FilterIsList_Posting        bit = 0,
    @FilterIsList_Aquinas        bit = 0,
    @FilterIsList_Posting3536    bit = 0
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
       ========================================= */
    IF OBJECT_ID('tempdb..#AttorneyResolved') IS NOT NULL DROP TABLE #AttorneyResolved;

    SELECT
        yardiLegalRowID,
        yardiPersonRowID,
        yardiUnitRowID,
        yardiPropertyRowID,
        AttorneyID,
        AttorneyLabel,
        LawFirmID,
        LawFirmName
    INTO #AttorneyResolved
    FROM dbo.fnAttorneyResolve(@ResolvedAsOfDate);

    /* Lightweight indexes to help per-row matching */
    CREATE NONCLUSTERED INDEX IX_AR_Person   ON #AttorneyResolved(yardiPersonRowID)  INCLUDE (AttorneyLabel, LawFirmName, yardiLegalRowID, yardiUnitRowID, yardiPropertyRowID);
    CREATE NONCLUSTERED INDEX IX_AR_Legal    ON #AttorneyResolved(yardiLegalRowID)   INCLUDE (AttorneyLabel, LawFirmName, yardiPersonRowID, yardiUnitRowID, yardiPropertyRowID);
    CREATE NONCLUSTERED INDEX IX_AR_UnitProp ON #AttorneyResolved(yardiUnitRowID, yardiPropertyRowID) INCLUDE (AttorneyLabel, LawFirmName, yardiPersonRowID, yardiLegalRowID);
    CREATE NONCLUSTERED INDEX IX_AR_Prop     ON #AttorneyResolved(yardiPropertyRowID) INCLUDE (AttorneyLabel, LawFirmName, yardiPersonRowID, yardiLegalRowID, yardiUnitRowID);

    SELECT
        ISNULL(p.portfolioName, '') AS [Portfolio],
        p.buildingCode AS [Property],
        u.AptNumber AS [Unit],
        COALESCE(t.tenantCode, '(unit-only / no tenant)') AS [Tenant Account],
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
        ISNULL(ar.LawFirmName, '')   AS [Law Firm],
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
        u.LeaseEndDate AS [Lease End Date]--,

        -- DEBUG COLUMNS
		-- Extra columns not in the Excel template (kept at the end)
        --u.CurrentTenantYardiID,
        --@RequestedAsOfDate AS RequestedAsOfDate,
        --@ResolvedAsOfDate AS ResolvedSnapshotAsOfDate,
        --CASE WHEN @ResolvedAsOfDate = @RequestedAsOfDate THEN CAST(0 AS bit) ELSE CAST(1 AS bit) END AS IsResolvedFromPriorSnapshot,
        --'DAILY' AS ModeUsed
FROM dbo.tblTenantAR_DailySnapshot s
        INNER JOIN dbo.tblProperties p
            ON p.yardiPropertyRowID = s.yardiPropertyRowID
        LEFT JOIN dbo.tblPropertyUnits u
            ON u.yardiUnitRowID = s.yardiUnitRowID
        LEFT JOIN dbo.tblTenants t
            ON t.yardiPersonRowID = s.yardiPersonRowID
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
                r.LawFirmName
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
      AND (
            @FilterIsList_Posting3536 = 0
            OR p.isInList_Posting = 1
            OR p.buildingCode IN ('3651', '3655')
            OR (TRY_CONVERT(int, p.buildingCode) BETWEEN 3500 AND 3572)
          )
      AND (@FilterOnlyExcel = 0 OR s.endingBalance > 0)
    ORDER BY p.buildingCode, u.AptNumber;

END;
GO