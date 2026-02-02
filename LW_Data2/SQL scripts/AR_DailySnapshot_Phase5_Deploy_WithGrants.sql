/*
  Deployment: Phase 5 - Update sp_Snapshot_Tenants_SCD_Range to use persistent snapshot
  Notes:
  - Safe to re-run (CREATE OR ALTER).
  - Grants EXECUTE to lemwolffRW only.
*/

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[sp_Snapshot_Tenants_SCD_Range]
  @StartDate      date = NULL,
  @EndDate        date = NULL,
  @MonthsBack     int  = NULL,
  @DeleteExisting bit  = 1
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  /* =========================
     1) Normalize the date range
     ========================= */
  DECLARE @AsOfEnd  date = COALESCE(@EndDate,    EOMONTH(DATEADD(month,-1,CAST(GETDATE() AS date))));
  DECLARE @Months   int  = COALESCE(@MonthsBack, 3);
  DECLARE @AsOfBeg  date = COALESCE(@StartDate,  DATEADD(day,1,EOMONTH(DATEADD(month,-@Months,@AsOfEnd))));
  IF @AsOfEnd < @AsOfBeg SET @AsOfEnd = @AsOfBeg;

  BEGIN TRY
    BEGIN TRAN;

    /* =========================
       2) Build months to process
       ========================= */
    IF OBJECT_ID('tempdb..#months') IS NOT NULL DROP TABLE #months;
    ;WITH m AS (
      SELECT EOMONTH(@AsOfBeg) AS AsOfDate
      UNION ALL
      SELECT EOMONTH(DATEADD(month,1,AsOfDate)) FROM m WHERE AsOfDate < @AsOfEnd
    )
    SELECT AsOfDate INTO #months FROM m OPTION (MAXRECURSION 200);

    /* Track tenants we touch for IsCurrent recalculation */
    IF OBJECT_ID('tempdb..#affected') IS NOT NULL DROP TABLE #affected;
    CREATE TABLE #affected (yardiPersonRowID int PRIMARY KEY);

    /* Optional wipe of snapshots in range */
    IF (@DeleteExisting = 1)
      DELETE dbo.tblTenants_Snapshots
      WHERE ValidFrom BETWEEN @AsOfBeg AND @AsOfEnd;

    /* =========================
       3) Latest legal per tenant (prefer OPEN, else CLOSED)
       ========================= */
    -- Latest OPEN
    IF OBJECT_ID('tempdb..#legal_open') IS NOT NULL DROP TABLE #legal_open;
    SELECT o.yardiPersonRowID,o.yardiLegalRowID,o.legalStatus,o.legalFlasher,
           o.legalDisplay,o.unpaidCharges,o.createdDate,o.modifiedDate
    INTO #legal_open
    FROM (
      SELECT lc.*,
             rn = ROW_NUMBER() OVER (
                    PARTITION BY lc.yardiPersonRowID
                    ORDER BY ISNULL(lc.modifiedDate, lc.createdDate) DESC, lc.yardiLegalRowID DESC
                  )
      FROM dbo.tblLegalCases lc
      WHERE lc.isClosed = 0
    ) o
    WHERE o.rn = 1;
    CREATE CLUSTERED INDEX CX_legal_open ON #legal_open(yardiPersonRowID);

    -- Latest CLOSED
    IF OBJECT_ID('tempdb..#legal_closed') IS NOT NULL DROP TABLE #legal_closed;
    SELECT c.yardiPersonRowID,c.yardiLegalRowID,c.legalStatus,c.legalFlasher,
           c.legalDisplay,c.unpaidCharges,c.createdDate,c.modifiedDate
    INTO #legal_closed
    FROM (
      SELECT lc.*,
             rn = ROW_NUMBER() OVER (
                    PARTITION BY lc.yardiPersonRowID
                    ORDER BY ISNULL(lc.modifiedDate, lc.createdDate) DESC, lc.yardiLegalRowID DESC
                  )
      FROM dbo.tblLegalCases lc
      WHERE lc.isClosed = 1
    ) c
    WHERE c.rn = 1;
    CREATE CLUSTERED INDEX CX_legal_closed ON #legal_closed(yardiPersonRowID);

    -- Coalesce OPEN else CLOSED
    IF OBJECT_ID('tempdb..#legal_latest') IS NOT NULL DROP TABLE #legal_latest;
    SELECT
      COALESCE(o.yardiPersonRowID, c.yardiPersonRowID) AS yardiPersonRowID,
      COALESCE(o.yardiLegalRowID , c.yardiLegalRowID ) AS yardiLegalRowID,
      COALESCE(o.legalStatus     , c.legalStatus     ) AS legalStatus,
      COALESCE(o.legalFlasher    , c.legalFlasher    ) AS legalFlasher,
      COALESCE(o.legalDisplay    , c.legalDisplay    ) AS legalDisplay,
      COALESCE(o.unpaidCharges   , c.unpaidCharges   ) AS unpaidCharges,
      COALESCE(o.createdDate     , c.createdDate     ) AS createdDate,
      COALESCE(o.modifiedDate    , c.modifiedDate    ) AS modifiedDate
    INTO #legal_latest
    FROM #legal_open o
    FULL JOIN #legal_closed c ON c.yardiPersonRowID = o.yardiPersonRowID;
    CREATE CLUSTERED INDEX CX_legal_latest ON #legal_latest(yardiPersonRowID);

    /* =========================
       4) Month loop
       ========================= */
    DECLARE @ThisAsOf date;
    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
      SELECT AsOfDate FROM #months ORDER BY AsOfDate;
    OPEN cur;

    FETCH NEXT FROM cur INTO @ThisAsOf;
    WHILE @@FETCH_STATUS = 0
    BEGIN
      /* A/R seed for this month */
      IF OBJECT_ID('tempdb..#ar') IS NOT NULL DROP TABLE #ar;
      SELECT s.yardiPersonRowID,
             s.yardiPropertyRowID,
             s.yardiUnitRowID,
             s.endingBalance
      INTO #ar
      FROM dbo.tblTenantAR_DailySnapshot s
      WHERE s.AsOfDate = @ThisAsOf;
      CREATE CLUSTERED INDEX CX_ar ON #ar(yardiPersonRowID);

      /* Static entities + portfolio (live map) */
      IF OBJECT_ID('tempdb..#base') IS NOT NULL DROP TABLE #base;
      SELECT
        t.yardiPersonRowID,
        p.yardiPropertyRowID,
        u.yardiUnitRowID,
        p.buildingCode,
        u.AptNumber,
        t.tenantCode,
        (isnull(t.lastName,'') + ', ' + isnull(t.firstName,'')) AS tenantName
      INTO #base
      FROM #ar a
		  JOIN dbo.tblTenants       t ON t.yardiPersonRowID   = a.yardiPersonRowID
		  JOIN dbo.tblProperties    p ON p.yardiPropertyRowID = a.yardiPropertyRowID
		  JOIN dbo.tblPropertyUnits u ON u.yardiUnitRowID     = a.yardiUnitRowID

      /* Last legal action date as-of THIS month (no future dates) */
      IF OBJECT_ID('tempdb..#last_action') IS NOT NULL DROP TABLE #last_action;
      SELECT
        a.yardiLegalRowID,
        lastLegalNoteDate = MAX(
          TRY_CONVERT(date, COALESCE(a.dtLastModified, a.dtCreated, a.dtBegin, a.dtDue))
        )
      INTO #last_action
      FROM dbo.tblLegalCasesActions AS a
      WHERE TRY_CONVERT(date, COALESCE(a.dtLastModified, a.dtCreated, a.dtBegin, a.dtDue)) <= @ThisAsOf
      GROUP BY a.yardiLegalRowID;
      CREATE UNIQUE CLUSTERED INDEX CX_last_action ON #last_action(yardiLegalRowID);

      /* Compose rows */
      IF OBJECT_ID('tempdb..#joined') IS NOT NULL DROP TABLE #joined;
      SELECT
        b.yardiPersonRowID,
        b.yardiPropertyRowID,
        b.yardiUnitRowID,
        b.buildingCode,
        b.AptNumber,
        b.tenantCode,
        b.tenantName,
        a.endingBalance,
        L.yardiLegalRowID AS legalID_yardi,
        L.legalStatus,
        L.legalFlasher,
        L.legalDisplay,
        la.lastLegalNoteDate
      INTO #joined
      FROM #base b
		  LEFT JOIN #ar a ON a.yardiPersonRowID = b.yardiPersonRowID
		  LEFT JOIN #legal_latest L ON L.yardiPersonRowID = b.yardiPersonRowID
		  LEFT JOIN #last_action la ON la.yardiLegalRowID = L.yardiLegalRowID;   -- join by LEGAL
      
	  CREATE CLUSTERED INDEX CX_joined ON #joined(yardiPersonRowID);

      /* De-dup: keep ONE row per tenant for this AsOf */
      IF OBJECT_ID('tempdb..#joined_one') IS NOT NULL DROP TABLE #joined_one;
      WITH ranked AS (
        SELECT j.*,
               rn = ROW_NUMBER() OVER (
                      PARTITION BY j.yardiPersonRowID
                      ORDER BY 
                        CASE WHEN j.endingBalance IS NULL THEN 1 ELSE 0 END, -- prefer non-null
                        ABS(COALESCE(j.endingBalance,0.0)) DESC,             -- larger magnitude first
                        j.yardiPropertyRowID DESC,
                        j.yardiUnitRowID DESC
                    )
        FROM #joined j
      )
      SELECT * INTO #joined_one FROM ranked WHERE rn = 1;
      CREATE CLUSTERED INDEX CX_joined_one ON #joined_one(yardiPersonRowID);

      /* MERGE into snapshots */
      ;WITH ToWrite AS (
        SELECT
          j.yardiPersonRowID,
          ValidFrom      = @ThisAsOf,
          ValidTo        = NULL,
          IsCurrent      = CAST(0 AS bit),
          j.yardiPropertyRowID,
          j.yardiUnitRowID,
          j.buildingCode,
          j.AptNumber,
          j.tenantCode,
          j.tenantName,
          j.endingBalance,
          j.legalID_yardi,
          j.legalStatus,
          j.legalFlasher,
          unpaidChargesHeader = CAST(NULL AS decimal(12,2)),
          lastLegalNoteDate   = j.lastLegalNoteDate,
          dayCounter          = CASE WHEN j.lastLegalNoteDate IS NULL THEN NULL
                                     ELSE DATEDIFF(DAY, j.lastLegalNoteDate, @ThisAsOf) END,
          attorneyLabel       = NULL,
          LegalDisplay        = NULLIF(LTRIM(RTRIM(j.legalDisplay)),''),
          RowHash             = HASHBYTES('SHA2_256',
                               CONCAT(
                                 j.yardiPersonRowID,'|',@ThisAsOf,'|',
                                 j.yardiPropertyRowID,'|',j.yardiUnitRowID,'|',
                                 j.endingBalance,'|',ISNULL(j.legalID_yardi,0),'|',
                                 ISNULL(j.legalStatus,''),
                                 '|',ISNULL(j.legalFlasher,''),
                                 '|',ISNULL(NULLIF(LTRIM(RTRIM(j.legalDisplay)),''),''),
                                 '|',ISNULL(CONVERT(varchar(10), j.lastLegalNoteDate, 23),'')
                               ))
        FROM #joined_one j
      )
      MERGE dbo.tblTenants_Snapshots WITH (HOLDLOCK) AS T
      USING ToWrite S
        ON T.yardiPersonRowID = S.yardiPersonRowID
       AND T.ValidFrom        = S.ValidFrom
      WHEN MATCHED AND ISNULL(T.RowHash,0x00) <> ISNULL(S.RowHash,0x00)
        THEN UPDATE SET
          T.ValidTo             = S.ValidTo,
          T.IsCurrent           = S.IsCurrent,
          T.yardiPropertyRowID  = S.yardiPropertyRowID,
          T.yardiUnitRowID      = S.yardiUnitRowID,
          T.buildingCode        = S.buildingCode,
          T.AptNumber           = S.AptNumber,
          T.tenantCode          = S.tenantCode,
          T.tenantName          = S.tenantName,
          T.endingBalance       = S.endingBalance,
          T.legalID_yardi       = S.legalID_yardi,
          T.legalStatus         = S.legalStatus,
          T.legalFlasher        = S.legalFlasher,
          T.unpaidChargesHeader = S.unpaidChargesHeader,
          T.lastLegalNoteDate   = S.lastLegalNoteDate,
          T.dayCounter          = S.dayCounter,
          T.attorneyLabel       = S.attorneyLabel,
          T.LegalDisplay        = S.LegalDisplay,
          T.RowHash             = S.RowHash
      WHEN NOT MATCHED BY TARGET
        THEN INSERT (
          yardiPersonRowID, ValidFrom, ValidTo, IsCurrent,
          yardiPropertyRowID, yardiUnitRowID, buildingCode, AptNumber,
          tenantCode, tenantName, endingBalance,
          legalID_yardi, legalStatus, legalFlasher, unpaidChargesHeader,
          lastLegalNoteDate, dayCounter, attorneyLabel, 
          RowHash, LegalDisplay
        ) VALUES (
          S.yardiPersonRowID, S.ValidFrom, S.ValidTo, S.IsCurrent,
          S.yardiPropertyRowID, S.yardiUnitRowID, S.buildingCode, S.AptNumber,
          S.tenantCode, S.tenantName, S.endingBalance,
          S.legalID_yardi, S.legalStatus, S.legalFlasher, S.unpaidChargesHeader,
          S.lastLegalNoteDate, S.dayCounter, S.attorneyLabel, 
          S.RowHash, S.LegalDisplay
        );

      /* Mark affected tenants */
      INSERT INTO #affected(yardiPersonRowID)
      SELECT yardiPersonRowID FROM #joined_one
      EXCEPT
      SELECT yardiPersonRowID FROM #affected;

      FETCH NEXT FROM cur INTO @ThisAsOf;
    END
    CLOSE cur; DEALLOCATE cur;

	/* =========================
	   5a) Recompute ValidTo ranges (SCD)
	   ========================= */
	;WITH x AS (
		SELECT
			s.yardiPersonRowID,
			s.ValidFrom,
			NextValidFrom = LEAD(s.ValidFrom) OVER (
				PARTITION BY s.yardiPersonRowID
				ORDER BY s.ValidFrom
			)
		FROM dbo.tblTenants_Snapshots s
		JOIN #affected a ON a.yardiPersonRowID = s.yardiPersonRowID
	)
	UPDATE s
	SET ValidTo =
		CASE
			WHEN x.NextValidFrom IS NULL THEN NULL
			ELSE DATEADD(day, -1, x.NextValidFrom)
		END
	FROM dbo.tblTenants_Snapshots s
	JOIN x
	  ON x.yardiPersonRowID = s.yardiPersonRowID
	 AND x.ValidFrom        = s.ValidFrom;


    /* =========================
       5) Recompute IsCurrent (one per tenant)
       ========================= */
    UPDATE s SET IsCurrent = 0
    FROM dbo.tblTenants_Snapshots s
    JOIN #affected a ON a.yardiPersonRowID = s.yardiPersonRowID;

    ;WITH picks AS (
      SELECT s.yardiPersonRowID, s.ValidFrom,
             rn = ROW_NUMBER() OVER (
                    PARTITION BY s.yardiPersonRowID
                    ORDER BY s.ValidFrom DESC, s.yardiPropertyRowID DESC, s.yardiUnitRowID DESC
                  )
      FROM dbo.tblTenants_Snapshots s
      JOIN #affected a ON a.yardiPersonRowID = s.yardiPersonRowID
    )
    UPDATE s SET IsCurrent = 1
    FROM dbo.tblTenants_Snapshots s
    JOIN picks p
      ON p.yardiPersonRowID = s.yardiPersonRowID
     AND p.ValidFrom        = s.ValidFrom
    WHERE p.rn = 1;

    COMMIT;
  END TRY
  BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK;
    THROW;
  END CATCH
END
GO
GRANT EXECUTE ON OBJECT::dbo.sp_Snapshot_Tenants_SCD_Range TO [lemwolffRW];
GO
