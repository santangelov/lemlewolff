/*
Hotfix script for:
System.Data.SqlClient.SqlException:
'@FilterIsList_Posting3536 is not a parameter for procedure spReport_ArrearsTracker.'

Run this script in the target database to ensure the procedure signature includes
@FilterIsList_Posting3536 and returns the expected arrears report shape.
*/

CREATE OR ALTER PROCEDURE [dbo].[spReport_ArrearsTracker]
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

    SELECT
        ISNULL(p.portfolioName, '') AS Portfolio,
        p.buildingCode AS Property,
        u.AptNumber AS Unit,
        t.tenantCode AS Tenant,
        CONCAT(ISNULL(t.lastName, ''), CASE WHEN t.lastName IS NOT NULL AND t.firstName IS NOT NULL THEN ', ' ELSE '' END, ISNULL(t.firstName, '')) AS [Name],
        s.endingBalance,
        ISNULL(NULLIF(LTRIM(RTRIM(s.LegalDisplay)), ''), '') AS CurrentLegalStatus,
        CASE
            WHEN s.lastLegalNoteDate IS NULL OR s.lastLegalNoteDate = '19000101' THEN ''
            ELSE CONVERT(varchar(20), s.lastLegalNoteDate, 120)
        END AS LastLegalNote,
        s.dayCounter,
        '' AS Attorney,
        '' AS LawFirmCode,
        CASE WHEN ISNULL(NULLIF(LTRIM(RTRIM(s.LegalDisplay)), ''), '') = '' THEN 'No' ELSE 'Yes' END AS Legal_Active,
        CASE WHEN @ResolvedSnapshotAsOfDate = @RequestedAsOfDate THEN 'Yes' ELSE 'Resolved' END AS PresentAsOf,
        '' AS ExclusionReason,
        t.[status] AS TenantStatus,
        u.LeaseStartDate,
        u.LeaseEndDate,
        @RequestedAsOfDate AS RequestedAsOfDate,
        @ResolvedSnapshotAsOfDate AS ResolvedSnapshotAsOfDate,
        CASE WHEN @ResolvedSnapshotAsOfDate = @RequestedAsOfDate THEN CAST(0 AS bit) ELSE CAST(1 AS bit) END AS IsResolvedFromPriorSnapshot,
        'MONTH-END' AS ModeUsed
    FROM dbo.tblTenants_Snapshots s
    INNER JOIN dbo.tblProperties p
        ON p.yardiPropertyRowID = s.yardiPropertyRowID
    LEFT JOIN dbo.tblPropertyUnits u
        ON u.yardiUnitRowID = s.yardiUnitRowID
    LEFT JOIN dbo.tblTenants t
        ON t.yardiPersonRowID = s.yardiPersonRowID
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

GRANT EXECUTE ON OBJECT::dbo.spReport_ArrearsTracker TO [lemwolffRO];
GO
