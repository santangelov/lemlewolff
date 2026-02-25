/*
Daily-mode Legal Arrears report (rolling 90-day window).
Uses tblTenantAR_DailySnapshot for ending balance resolution and preserves existing report filters.
*/

CREATE OR ALTER PROCEDURE [dbo].[spReport_ArrearsTracker_Daily]
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

    SELECT @ResolvedAsOfDate = MAX(s.AsOfDate)
    FROM dbo.tblTenantAR_DailySnapshot s
    WHERE s.AsOfDate <= @RequestedAsOfDate
      AND s.AsOfDate >= @Cutoff90;

    IF @ResolvedAsOfDate IS NULL
    BEGIN
        RAISERROR('spReport_ArrearsTracker_Daily: No daily snapshot exists on or before requested AsOfDate within the rolling 90-day window.', 16, 1);
        RETURN;
    END

    SELECT @TenantSnapAsOf_Resolved = MAX(CAST(ts.ValidFrom AS date))
    FROM dbo.tblTenants_Snapshots ts
    WHERE CAST(ts.ValidFrom AS date) <= @RequestedAsOfDate;

    SELECT
        ISNULL(p.portfolioName, '') AS Portfolio,
        p.buildingCode AS Property,
        u.AptNumber AS Unit,
        t.tenantCode AS Tenant,
        CONCAT(ISNULL(t.lastName, ''), CASE WHEN t.lastName IS NOT NULL AND t.firstName IS NOT NULL THEN ', ' ELSE '' END, ISNULL(t.firstName, '')) AS [Name],
        s.endingBalance,
        ISNULL(NULLIF(LTRIM(RTRIM(ts.LegalDisplay)), ''), '') AS CurrentLegalStatus,
        CASE
            WHEN ts.lastLegalNoteDate IS NULL OR ts.lastLegalNoteDate = '19000101' THEN ''
            ELSE CONVERT(varchar(20), ts.lastLegalNoteDate, 120)
        END AS LastLegalNote,
        ts.dayCounter,
        '' AS Attorney,
        '' AS LawFirmCode,
        CASE WHEN ISNULL(NULLIF(LTRIM(RTRIM(ts.LegalDisplay)), ''), '') = '' THEN 'No' ELSE 'Yes' END AS Legal_Active,
        CASE WHEN @ResolvedAsOfDate = @RequestedAsOfDate THEN 'Yes' ELSE 'Resolved' END AS PresentAsOf,
        '' AS ExclusionReason,
        t.[status] AS TenantStatus,
        u.LeaseStartDate,
        u.LeaseEndDate,
        @RequestedAsOfDate AS RequestedAsOfDate,
        @ResolvedAsOfDate AS ResolvedSnapshotAsOfDate,
        CASE WHEN @ResolvedAsOfDate = @RequestedAsOfDate THEN CAST(0 AS bit) ELSE CAST(1 AS bit) END AS IsResolvedFromPriorSnapshot,
        'DAILY' AS ModeUsed
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

GRANT EXECUTE ON OBJECT::dbo.spReport_ArrearsTracker_Daily TO [lemwolffRO];
GO
