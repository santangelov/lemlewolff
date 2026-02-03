/*
  Deployment: Tenant AR Daily Snapshot (Phase 2 + Phase 3 + Phase 4)
  Notes:
  - Safe to re-run (idempotent).
  - Creates snapshot table, indexes, builder/retention procs, snapshot maintenance procs,
    and grants permissions to lemwolffRW/lemwolffRO.
*/

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.tblTenantAR_DailySnapshot', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[tblTenantAR_DailySnapshot](
        [AsOfDate] [date] NOT NULL,
        [yardiPersonRowID] [int] NOT NULL,
        [yardiPropertyRowID] [int] NOT NULL,
        [yardiUnitRowID] [int] NOT NULL,
        [balanceFwd] [decimal](12, 2) NULL,
        [charges] [decimal](12, 2) NULL,
        [receipts] [decimal](12, 2) NULL,
        [endingBalance] [decimal](12, 2) NULL,
        [SnapshotCreatedUtc] [datetime2](7) NOT NULL,
        [SnapshotUpdatedUtc] [datetime2](7) NULL,
     CONSTRAINT [PK_tblTenantAR_DailySnapshot] PRIMARY KEY CLUSTERED
    (
        [AsOfDate] ASC,
        [yardiPropertyRowID] ASC,
        [yardiUnitRowID] ASC,
        [yardiPersonRowID] ASC
    )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
    ) ON [PRIMARY];
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_tblTenantAR_DailySnapshot_AsOfDate'
      AND object_id = OBJECT_ID(N'dbo.tblTenantAR_DailySnapshot')
)
BEGIN
    CREATE NONCLUSTERED INDEX [IX_tblTenantAR_DailySnapshot_AsOfDate]
    ON [dbo].[tblTenantAR_DailySnapshot] ([AsOfDate] ASC);
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_tblTenantAR_DailySnapshot_Tenant_AsOfDate'
      AND object_id = OBJECT_ID(N'dbo.tblTenantAR_DailySnapshot')
)
BEGIN
    CREATE NONCLUSTERED INDEX [IX_tblTenantAR_DailySnapshot_Tenant_AsOfDate]
    ON [dbo].[tblTenantAR_DailySnapshot] ([yardiPersonRowID] ASC, [AsOfDate] ASC)
    INCLUDE ([yardiPropertyRowID], [yardiUnitRowID], [endingBalance]);
END
GO

CREATE OR ALTER PROCEDURE [dbo].[spRptBuilder_AR_DailySnapshot_Build]
    @AsOfDate date,
    @Rebuild bit = 0
AS
BEGIN
    SET NOCOUNT ON;

    IF @AsOfDate IS NULL
    BEGIN
        RAISERROR('AsOfDate is required.',16,1);
        RETURN;
    END

    IF OBJECT_ID(N'dbo.tblTenantARSummary', N'U') IS NULL
    BEGIN
        RAISERROR('Persistent source table dbo.tblTenantARSummary is missing.',16,1);
        RETURN;
    END

    IF OBJECT_ID(N'dbo.tblTenantAR_DailySnapshot', N'U') IS NULL
    BEGIN
        RAISERROR('Snapshot table dbo.tblTenantAR_DailySnapshot is missing.',16,1);
        RETURN;
    END

    IF @Rebuild = 1
    BEGIN
        DELETE FROM dbo.tblTenantAR_DailySnapshot
        WHERE AsOfDate = @AsOfDate;
    END

    ;WITH source_data AS
    (
        SELECT
            s.AsOfDate,
            s.yardiPersonRowID,
            s.yardiPropertyRowID,
            s.yardiUnitRowID,
            s.balanceFwd,
            s.charges,
            s.receipts,
            s.endingBalance
        FROM dbo.tblTenantARSummary s
        JOIN dbo.tblProperties p
            ON p.yardiPropertyRowID = s.yardiPropertyRowID
        JOIN dbo.tblPropertyUnits u
            ON u.yardiUnitRowID = s.yardiUnitRowID
            AND u.yardiPropertyRowID = s.yardiPropertyRowID
        WHERE s.AsOfDate = @AsOfDate
          AND ISNULL(p.isInactive, 0) = 0
          AND ISNULL(u.isExcluded, 0) = 0
    )
    MERGE dbo.tblTenantAR_DailySnapshot WITH (HOLDLOCK) AS tgt
    USING source_data AS src
        ON tgt.AsOfDate = src.AsOfDate
        AND tgt.yardiPropertyRowID = src.yardiPropertyRowID
        AND tgt.yardiUnitRowID = src.yardiUnitRowID
        AND tgt.yardiPersonRowID = src.yardiPersonRowID
    WHEN MATCHED THEN
        UPDATE SET
            tgt.balanceFwd = src.balanceFwd,
            tgt.charges = src.charges,
            tgt.receipts = src.receipts,
            tgt.endingBalance = src.endingBalance,
            tgt.SnapshotUpdatedUtc = sysutcdatetime()
    WHEN NOT MATCHED THEN
        INSERT (
            AsOfDate,
            yardiPersonRowID,
            yardiPropertyRowID,
            yardiUnitRowID,
            balanceFwd,
            charges,
            receipts,
            endingBalance,
            SnapshotCreatedUtc,
            SnapshotUpdatedUtc
        )
        VALUES (
            src.AsOfDate,
            src.yardiPersonRowID,
            src.yardiPropertyRowID,
            src.yardiUnitRowID,
            src.balanceFwd,
            src.charges,
            src.receipts,
            src.endingBalance,
            sysutcdatetime(),
            sysutcdatetime()
        );
END
GO

CREATE OR ALTER PROCEDURE [dbo].[spTenantAR_DailySnapshot_RetentionCleanup]
    @RetentionMonths int = 18
AS
BEGIN
    SET NOCOUNT ON;

    IF @RetentionMonths IS NULL OR @RetentionMonths <= 0
    BEGIN
        SET @RetentionMonths = 18;
    END

    DECLARE @CutoffDate date = DATEADD(month, -@RetentionMonths, CAST(GETDATE() AS date));

    DELETE FROM dbo.tblTenantAR_DailySnapshot
    WHERE AsOfDate < @CutoffDate;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[spAR_Snapshots_UpsertFromStaging]
    @StartDate date,
    @EndDate date
AS
BEGIN
    SET NOCOUNT ON;

    IF @StartDate IS NULL OR @EndDate IS NULL
    BEGIN
        RAISERROR('StartDate and EndDate are required.',16,1);
        RETURN;
    END

    IF @StartDate > @EndDate
    BEGIN
        RAISERROR('StartDate must be on or before EndDate.',16,1);
        RETURN;
    END

    IF OBJECT_ID(N'dbo.tblTenantARSummary', N'U') IS NULL
    BEGIN
        RAISERROR('Persistent source table dbo.tblTenantARSummary is missing.',16,1);
        RETURN;
    END

    IF OBJECT_ID(N'dbo.tblTenantAR_DailySnapshot', N'U') IS NULL
    BEGIN
        RAISERROR('Snapshot table dbo.tblTenantAR_DailySnapshot is missing.',16,1);
        RETURN;
    END

    DELETE FROM dbo.tblTenantAR_DailySnapshot
    WHERE AsOfDate BETWEEN @StartDate AND @EndDate;

    INSERT INTO dbo.tblTenantAR_DailySnapshot
    (
        AsOfDate,
        yardiPersonRowID,
        yardiPropertyRowID,
        yardiUnitRowID,
        balanceFwd,
        charges,
        receipts,
        endingBalance,
        SnapshotCreatedUtc,
        SnapshotUpdatedUtc
    )
    SELECT
        s.AsOfDate,
        s.yardiPersonRowID,
        s.yardiPropertyRowID,
        s.yardiUnitRowID,
        s.balanceFwd,
        s.charges,
        s.receipts,
        s.endingBalance,
        sysutcdatetime(),
        sysutcdatetime()
    FROM dbo.tblTenantARSummary s
    JOIN dbo.tblProperties p
        ON p.yardiPropertyRowID = s.yardiPropertyRowID
    JOIN dbo.tblPropertyUnits u
        ON u.yardiUnitRowID = s.yardiUnitRowID
        AND u.yardiPropertyRowID = s.yardiPropertyRowID
    WHERE s.AsOfDate BETWEEN @StartDate AND @EndDate
      AND ISNULL(p.isInactive, 0) = 0
      AND ISNULL(u.isExcluded, 0) = 0;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[spAR_Snapshots_Cleanup]
    @RetentionMonths int = 18
AS
BEGIN
    SET NOCOUNT ON;

    IF @RetentionMonths IS NULL OR @RetentionMonths <= 0
    BEGIN
        SET @RetentionMonths = 18;
    END

    DECLARE @CutoffDate date = DATEADD(month, -@RetentionMonths, CAST(GETDATE() AS date));

    DELETE FROM dbo.tblTenantAR_DailySnapshot
    WHERE AsOfDate < @CutoffDate
      AND AsOfDate <> EOMONTH(AsOfDate);
END
GO

CREATE OR ALTER PROCEDURE [dbo].[spAR_Snapshots_GetLatestAsOfDate]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT MAX(AsOfDate) AS LatestAsOfDate
    FROM dbo.tblTenantAR_DailySnapshot;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[spAR_Snapshots_GetNearestPriorAsOfDate]
    @AsOfDate date
AS
BEGIN
    SET NOCOUNT ON;

    IF @AsOfDate IS NULL
    BEGIN
        RAISERROR('AsOfDate is required.',16,1);
        RETURN;
    END

    SELECT MAX(AsOfDate) AS NearestPriorAsOfDate
    FROM dbo.tblTenantAR_DailySnapshot
    WHERE AsOfDate < @AsOfDate;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[spAR_Snapshots_RunNightly]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartDate date;
    DECLARE @EndDate date;

    SELECT
        @StartDate = MIN(AsOfDate),
        @EndDate = MAX(AsOfDate)
    FROM dbo.tblTenantARSummary;

    IF @StartDate IS NULL OR @EndDate IS NULL
    BEGIN
        RAISERROR('No AsOfDate values found in dbo.tblTenantARSummary.',16,1);
        RETURN;
    END

    EXEC dbo.spAR_Snapshots_UpsertFromStaging @StartDate = @StartDate, @EndDate = @EndDate;

    IF DAY(GETDATE()) = 1
    BEGIN
        EXEC dbo.spAR_Snapshots_Cleanup;
    END

    DECLARE @me1 date = EOMONTH(GETDATE(), -1);
    DECLARE @me2 date = EOMONTH(GETDATE(), -2);
    DECLARE @me3 date = EOMONTH(GETDATE(), -3);

    IF NOT EXISTS (SELECT 1 FROM dbo.tblTenantAR_DailySnapshot WHERE AsOfDate = @me1)
        OR NOT EXISTS (SELECT 1 FROM dbo.tblTenantAR_DailySnapshot WHERE AsOfDate = @me2)
        OR NOT EXISTS (SELECT 1 FROM dbo.tblTenantAR_DailySnapshot WHERE AsOfDate = @me3)
    BEGIN
        RAISERROR('Snapshot guardrail failed: missing one or more of the last three closed month-ends.',16,1);
        RETURN;
    END
END
GO

/* Grants */
GRANT SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.tblTenantAR_DailySnapshot TO [lemwolffRW];
GRANT SELECT ON OBJECT::dbo.tblTenantAR_DailySnapshot TO [lemwolffRO];
GO

GRANT EXECUTE ON OBJECT::dbo.spRptBuilder_AR_DailySnapshot_Build TO [lemwolffRW];
GRANT EXECUTE ON OBJECT::dbo.spTenantAR_DailySnapshot_RetentionCleanup TO [lemwolffRW];
GRANT EXECUTE ON OBJECT::dbo.spAR_Snapshots_UpsertFromStaging TO [lemwolffRW];
GRANT EXECUTE ON OBJECT::dbo.spAR_Snapshots_Cleanup TO [lemwolffRW];
GRANT EXECUTE ON OBJECT::dbo.spAR_Snapshots_RunNightly TO [lemwolffRW];
GRANT EXECUTE ON OBJECT::dbo.spAR_Snapshots_GetLatestAsOfDate TO [lemwolffRO];
GRANT EXECUTE ON OBJECT::dbo.spAR_Snapshots_GetNearestPriorAsOfDate TO [lemwolffRO];
GO
