USE [lemlewolff]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
Month-end Legal Arrears report (monthly snapshot mode).

High-level behavior
- Reports balances using dbo.tblTenants_Snapshots (month-end SCD snapshot rows).
- Requested @AsOfDate is resolved to the closest snapshot ValidFrom <= @AsOfDate.
- This mode is intended for dates older than the rolling 90-day daily window (app routes to this proc for older dates).

Data sources (what each column is coming from)
- Ending Balance / Legal status / last legal note / day counter:
    dbo.tblTenants_Snapshots (month-end snapshot; ValidFrom is month-end)
- Property / unit / lease / portfolio fields:
    dbo.tblProperties (portfolioName, buildingCode, list flags)
    dbo.tblPropertyUnits (AptNumber, LeaseStartDate, LeaseEndDate, CurrentTenantYardiID)
- Tenant display fields:
    dbo.tblTenants (tenantCode, first/last name, status)
    NOTE: tenants can be missing from imports; those rows are preserved and flagged as unit-only/no-tenant.
- Attorney / Law Firm:
    Resolved from dbo.tblLegalRepresentation via dbo.fnAttorneyResolve(@AsOfDate):
      - dbo.tblLegalRepresentation (effective-dated representation assignments)
      - dbo.tblAttorneys (AttorneyID -> DisplayName)
      - dbo.tblAttorneysLawFirms + dbo.tblLawFirms (effective-dated firm assignment)
    IMPORTANT: This report does NOT rely on tblTenants_Snapshots.attorneyLabel (it may be blank). Attorney/LawFirm are resolved
    directly from tblLegalRepresentation through fnAttorneyResolve.

If Attorney / Law Firm are blank
- No effective representation exists for the row’s scope as of the resolved snapshot date, OR no effective firm assignment exists.
To populate:
1) Insert/maintain dbo.tblLegalRepresentation rows with correct scope and effective dates.
2) Ensure dbo.tblAttorneys has AttorneyID referenced by tblLegalRepresentation (DisplayName used for Attorney column).
3) Ensure dbo.tblAttorneysLawFirms links AttorneyID -> LawFirmID with effective dates, and dbo.tblLawFirms has FirmName.

Performance note
- fnAttorneyResolve(@AsOfDate) is materialized once into #AttorneyResolved per execution, indexed, then used via OUTER APPLY.
  This avoids repeated function evaluation per row.
*/

ALTER   PROCEDURE [dbo].[spReport_ArrearsTracker]
    @AsOfDate                    date,
    @BuildingCode                varchar(20) = NULL,
    @FilterOnlyExcel             bit = 1,
    @FilterIsList_Posting        bit = 0,
    @FilterIsList_Aquinas        bit = 0,
    @FilterIsList_Posting3536    bit = 0
AS
BEGIN
    SET NOCOUNT ON;

	--SET @FilterOnlyExcel=0;

    DECLARE @RequestedAsOfDate date;
    DECLARE @ResolvedSnapshotAsOfDate date;

    IF @AsOfDate IS NULL
    BEGIN
        RAISERROR('spReport_ArrearsTracker: AsOfDate is required.', 16, 1);
        RETURN;
    END

    IF @AsOfDate < '2000-01-01' OR @AsOfDate > DATEADD(DAY, 1, CAST(GETDATE() AS date))
    BEGIN
        RAISERROR('spReport_ArrearsTracker: AsOfDate is outside the supported range.', 16, 1);
        RETURN;
    END

    SET @RequestedAsOfDate = @AsOfDate;

    -- Resolve to closest available tenant snapshot date at or before request.
    SELECT @ResolvedSnapshotAsOfDate = MAX(CAST(ValidFrom AS date))
    FROM dbo.tblTenants_Snapshots
    WHERE CAST(ValidFrom AS date) <= @RequestedAsOfDate;

    IF @ResolvedSnapshotAsOfDate IS NULL
    BEGIN
        RAISERROR('spReport_ArrearsTracker: No snapshot exists on or before requested AsOfDate.', 16, 1);
        RETURN;
    END

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
    FROM dbo.fnAttorneyResolve(@ResolvedSnapshotAsOfDate);

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
        ISNULL(NULLIF(LTRIM(RTRIM(s.LegalDisplay)), ''), '') AS [Current Legal Status],
        CASE
            WHEN s.lastLegalNoteDate IS NULL OR s.lastLegalNoteDate = '19000101' THEN ''
            ELSE CONVERT(varchar(20), s.lastLegalNoteDate, 120)
        END AS [Last Legal Note],
        s.dayCounter AS [Day Counter],
        ISNULL(ar.AttorneyLabel, '') AS [Attorney],
        ISNULL(ar.LawFirmName, '')   AS [Law Firm],
        CASE WHEN ISNULL(NULLIF(LTRIM(RTRIM(s.LegalDisplay)), ''), '') = '' THEN 'No' ELSE 'Yes' END AS [Legal Active],
        CASE WHEN @ResolvedSnapshotAsOfDate = @RequestedAsOfDate THEN 'Present' ELSE 'Resolved' END AS [Present As Of],
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
		-- Extra columns not in the Excel template (kept at the end)
        ,u.CurrentTenantYardiID
        ,@RequestedAsOfDate AS RequestedAsOfDate
        ,@ResolvedSnapshotAsOfDate AS ResolvedSnapshotAsOfDate
        ,CASE WHEN @ResolvedSnapshotAsOfDate = @RequestedAsOfDate THEN CAST(0 AS bit) ELSE CAST(1 AS bit) END AS IsResolvedFromPriorSnapshot
        ,'MONTH-END' AS ModeUsed 
FROM dbo.tblTenants_Snapshots s
        INNER JOIN dbo.tblProperties p ON p.yardiPropertyRowID = s.yardiPropertyRowID
        LEFT JOIN dbo.tblPropertyUnits u ON u.yardiUnitRowID = s.yardiUnitRowID
        LEFT JOIN dbo.tblTenants t ON t.yardiPersonRowID = s.yardiPersonRowID

        /* Attorney/LawFirm resolution match preference (best match per row):
           1) legal match (s.legalID_yardi)
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
                   (r.yardiLegalRowID  IS NOT NULL AND s.legalID_yardi IS NOT NULL AND r.yardiLegalRowID = s.legalID_yardi)
                OR (r.yardiPersonRowID IS NOT NULL AND r.yardiPersonRowID = s.yardiPersonRowID)
                OR (r.yardiUnitRowID   IS NOT NULL AND r.yardiPropertyRowID IS NOT NULL
                    AND r.yardiUnitRowID = s.yardiUnitRowID AND r.yardiPropertyRowID = s.yardiPropertyRowID)
                OR (r.yardiPropertyRowID IS NOT NULL AND r.yardiPropertyRowID = s.yardiPropertyRowID)
            ORDER BY
                CASE
                    WHEN r.yardiLegalRowID  IS NOT NULL AND s.legalID_yardi IS NOT NULL AND r.yardiLegalRowID = s.legalID_yardi THEN 1
                    WHEN r.yardiPersonRowID IS NOT NULL AND r.yardiPersonRowID = s.yardiPersonRowID THEN 2
                    WHEN r.yardiUnitRowID   IS NOT NULL AND r.yardiPropertyRowID IS NOT NULL
                         AND r.yardiUnitRowID = s.yardiUnitRowID AND r.yardiPropertyRowID = s.yardiPropertyRowID THEN 3
                    WHEN r.yardiPropertyRowID IS NOT NULL AND r.yardiPropertyRowID = s.yardiPropertyRowID THEN 4
                    ELSE 99
                END
        ) ar

    WHERE CAST(s.ValidFrom AS date) = @ResolvedSnapshotAsOfDate
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