/*
  Deployment: Phase 6 - Route arrears report to persistent daily snapshot
  Notes:
  - Safe to re-run (CREATE OR ALTER).
  - Grants EXECUTE to lemwolffRO (read-only).
*/

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER FUNCTION [dbo].[fnReceivableSummaryByTenant_Range]
(
  @StartDate date,
  @EndDate   date
)
RETURNS TABLE
AS
RETURN
(
  WITH bounds AS (
    SELECT StartME = EOMONTH(@StartDate),
           EndME   = EOMONTH(@EndDate)
  ),
  span AS (
    SELECT a.*
    FROM dbo.tblTenantAR_DailySnapshot a
    CROSS JOIN bounds b
    WHERE a.AsOfDate BETWEEN b.StartME AND b.EndME
  ),
  startBF AS (
    SELECT s.yardiPersonRowID, s.balanceFwd
    FROM span s CROSS JOIN bounds b
    WHERE s.AsOfDate = b.StartME
  ),
  endEB AS (
    SELECT s.yardiPersonRowID, s.endingBalance
    FROM span s CROSS JOIN bounds b
    WHERE s.AsOfDate = b.EndME
  ),
  roll AS (
    SELECT s.yardiPersonRowID,
           SUM(ISNULL(s.charges,0.00))  AS Charges,
           SUM(ISNULL(s.receipts,0.00)) AS Receipts
    FROM span s
    GROUP BY s.yardiPersonRowID
  ),
  namebits AS (
    SELECT t.yardiPersonRowID,
           t.tenantCode AS Tenant,
           (RTRIM(LTRIM(t.lastName)) + ', ' + RTRIM(LTRIM(t.firstName))) AS [Name],
           t.[status] AS [Status],
           t.yardiPropertyRowID,
           t.yardiUnitRowID
    FROM dbo.tblTenants t
  ),
  loc AS (
    SELECT u.yardiUnitRowID, u.AptNumber AS Unit,
           p.yardiPropertyRowID, p.buildingCode AS Property
    FROM dbo.tblPropertyUnits u
    JOIN dbo.tblProperties p ON p.yardiPropertyRowID = u.yardiPropertyRowID
  ),
  legal_at_end AS (
    SELECT s.yardiPersonRowID,
           COALESCE(NULLIF(LTRIM(RTRIM(s.LegalDisplay)),N''), N'Open – status missing') AS [Legal Status]
    FROM dbo.tblTenants_Snapshots s
    CROSS JOIN bounds b
    WHERE b.EndME BETWEEN s.ValidFrom AND ISNULL(s.ValidTo,'9999-12-31')
  )
  SELECT
    l.Property, l.Unit, n.Tenant, n.[Name], n.[Status],
    lg.[Legal Status],
    bf.balanceFwd     AS [Balance Forward],
    r.Charges         AS [Charge],
    r.Receipts        AS [Receipt],
    eb.endingBalance  AS [Ending Balance]
  FROM roll r
  JOIN startBF bf         ON bf.yardiPersonRowID = r.yardiPersonRowID
  JOIN endEB   eb         ON eb.yardiPersonRowID = r.yardiPersonRowID
  JOIN namebits n         ON n.yardiPersonRowID  = r.yardiPersonRowID
  JOIN loc      l         ON l.yardiPropertyRowID = n.yardiPropertyRowID
                          AND l.yardiUnitRowID    = n.yardiUnitRowID
  LEFT JOIN legal_at_end lg ON lg.yardiPersonRowID = r.yardiPersonRowID
);
GO
CREATE OR ALTER PROCEDURE [dbo].[spReport_ArrearsTracker]
      @AsOfDate           date = NULL,
      @BuildingCode       varchar(20) = NULL,
      @FilterOnlyExcel    bit = 1,   -- 1 = return ONLY rows that qualify for the Excel report
      @FilterIsList_Posting bit = 0,  -- 1 = include ONLY buildings in Posting list
      @FilterIsList_Aquinas bit = 0   -- 1 = include ONLY buildings in Posting list
AS
BEGIN
    SET NOCOUNT ON;

    -------------------------------------------------------------------------------------
    -- 0. STANDARDIZE AsOfDate
    -- If @AsOfDate is NULL, default to today; otherwise use the supplied date.
    -------------------------------------------------------------------------------------
    IF @AsOfDate IS NULL
        SET @AsOfDate = CAST(GETDATE() AS date);


    -------------------------------------------------------------------------------------
    -- 1. ATTORNEY + LAW FIRM LOGIC  (From old ufn_AttorneyOrFirm_AsOf)
    --
    -- This logic determines:
    --   • The correct attorney for a tenant as of @AsOfDate
    --   • The correct law firm associated with that attorney
    --
    -- Notes:
    --   • tblLegalRepresentation does NOT contain LawFirmID directly
    --   • We must use AttorneysLawFirms to map Attorney > Law Firm
    --   • We pick the SINGLE best record per tenant using ROW_NUMBER()
    -------------------------------------------------------------------------------------

    ;WITH
    -------------------------------------------------------------------------------------
    -- (1A) Pick all Eligible LegalRepresentation rows with non-null AttorneyID
    --      that were effective at @AsOfDate, and rank them.
    -------------------------------------------------------------------------------------
    AttorneyPick AS (
        SELECT
            lr.yardiPersonRowID,
            lr.AttorneyID,
            lr.EffectiveFrom,
            lr.EffectiveTo,
            lr.RepresentationID,
            rn = ROW_NUMBER() OVER (
                     PARTITION BY lr.yardiPersonRowID
                     ORDER BY
                         lr.EffectiveFrom DESC,
                         ISNULL(lr.EffectiveTo, CONVERT(date,'99991231')) DESC,
                         lr.RepresentationID DESC
                 )
        FROM dbo.tblLegalRepresentation lr
        WHERE lr.AttorneyID IS NOT NULL
          AND lr.EffectiveFrom <= @AsOfDate
          AND ISNULL(lr.EffectiveTo, CONVERT(date,'99991231')) >= @AsOfDate
    ),

    -------------------------------------------------------------------------------------
    -- (1B) Choose the single best row per tenant
    -------------------------------------------------------------------------------------
    AttorneyChosen AS (
        SELECT yardiPersonRowID, AttorneyID
        FROM AttorneyPick
        WHERE rn = 1
    ),

    -------------------------------------------------------------------------------------
    -- (1C) Produce final Attorney + LawFirm details
    -------------------------------------------------------------------------------------
    AttorneyFirm AS (
        SELECT
            ac.yardiPersonRowID,
            a.AttorneyID,
            a.DisplayName AS AttorneyName,

            -- OUTER APPLY determines the correct firm mapping
            af.LawFirmID,
            af.FirmName,
            af.LawFirmCode
        FROM AttorneyChosen ac
        LEFT JOIN dbo.tblAttorneys a
               ON a.AttorneyID = ac.AttorneyID

        OUTER APPLY (
             SELECT TOP (1)
                    lf.LawFirmID,
                    lf.FirmName,
                    lf.LawFirmCode
             FROM dbo.tblAttorneysLawFirms alf
             JOIN dbo.tblLawFirms lf
               ON lf.LawFirmID = alf.LawFirmID
             WHERE alf.AttorneyID = ac.AttorneyID
               AND alf.EffectiveFrom <= @AsOfDate
             ORDER BY
                CASE WHEN ISNULL(alf.EffectiveTo, CONVERT(date,'99991231')) >= @AsOfDate THEN 0 ELSE 1 END,
                alf.EffectiveFrom DESC,
                alf.AttorneysLawFirmsID DESC
        ) af
    ),


    -------------------------------------------------------------------------------------
    -- 2. SNAPSHOT FOR THE MONTH-END
    -------------------------------------------------------------------------------------
    snap AS (
        SELECT sn.*, p.portfolioName
        FROM dbo.tblTenants_Snapshots sn
			left join tblProperties p on sn.yardiPropertyRowID = p.yardiPropertyRowID
        WHERE ValidFrom = @AsOfDate
    ),


    -------------------------------------------------------------------------------------
    -- 3. BASE AR DATA (merged old fnReport_ArrearsTracker)
    --
    -- Includes LeaseStartDate and LeaseEndDate from tblPropertyUnits
    -------------------------------------------------------------------------------------
    base_raw AS (
        SELECT
            s.portfolioName AS Portfolio,
            p.buildingCode  AS Property,
            u.AptNumber     AS Unit,
            t.tenantCode    AS Tenant,
            t.lastName + ', ' + t.firstName AS [Name],
            s.endingBalance,
            COALESCE(NULLIF(LTRIM(RTRIM(s.LegalDisplay)), N''), N'Open – status missing') AS CurrentLegalStatus,
            s.lastLegalNoteDate AS LastLegalNote,
            s.dayCounter,
            s.yardiPersonRowID,
            s.yardiUnitRowID,
            s.yardiPropertyRowID,

            -- Attorney / Law Firm (from our AttorneyFirm CTE)
            af.AttorneyName,
            af.LawFirmCode,

            -- Lease dates from tblPropertyUnits
            u.LeaseStartDate,
            u.LeaseEndDate

        FROM snap s
        JOIN dbo.tblTenants       t ON t.yardiPersonRowID   = s.yardiPersonRowID
        JOIN dbo.tblProperties    p ON p.yardiPropertyRowID = s.yardiPropertyRowID
        JOIN dbo.tblPropertyUnits u ON u.yardiUnitRowID     = s.yardiUnitRowID

        LEFT JOIN AttorneyFirm af
               ON af.yardiPersonRowID = s.yardiPersonRowID
    ),


    -------------------------------------------------------------------------------------
    -- 4. ATTACH TENANT STATUS, PROPERTY FLAGS, UNIT FLAGS, and SNAPSHOT ROW
    -------------------------------------------------------------------------------------
    base AS (
        SELECT
            r.*,
            t.[status]  AS TenantStatus,
            --t.moveInDate,
            t.moveOutDate,
            p.isInactive AS Property_IsInactive_raw,
            u.isExcluded AS Unit_IsExcluded_raw,

            -- Snapshot unit row for presence check
            su.yardiUnitRowID AS UnitRowAtAsOf,

            -- Posting List flag
            p.isInList_Posting,
			p.isInList_Aquinas
        FROM base_raw r
        JOIN dbo.tblTenants       t ON t.yardiPersonRowID = r.yardiPersonRowID
        JOIN dbo.tblProperties    p ON p.buildingCode     = r.Property

        OUTER APPLY (
            SELECT TOP (1) s2.yardiUnitRowID
            FROM dbo.tblTenants_Snapshots s2
            WHERE s2.yardiPersonRowID = r.yardiPersonRowID
              AND @AsOfDate BETWEEN s2.ValidFrom AND ISNULL(s2.ValidTo, '9999-12-31')
        ) su

        LEFT JOIN dbo.tblPropertyUnits u ON u.yardiUnitRowID = su.yardiUnitRowID

        WHERE (@BuildingCode IS NULL OR r.Property = @BuildingCode)
          AND (@FilterIsList_Posting = 0 OR p.isInList_Posting = 1)
		  AND (@FilterIsList_Aquinas = 0 OR p.isInList_Aquinas = 1)
    ),


    -------------------------------------------------------------------------------------
    -- 5. DIAGNOSTIC FLAGS
    -------------------------------------------------------------------------------------
    flags AS (
        SELECT
            b.*,

            -- RULE #4: EXCLUDE UNIT if excluded
            CAST(CASE WHEN UPPER(LTRIM(RTRIM(CONVERT(varchar(10), b.Unit_IsExcluded_raw))))
                        IN ('1','Y','YES','TRUE','T') THEN 1 ELSE 0 END AS bit) AS Unit_IsExcluded_bit,

            -- RULE #3: EXCLUDE PROPERTY if inactive
            CAST(CASE WHEN UPPER(LTRIM(RTRIM(CONVERT(varchar(10), b.Property_IsInactive_raw))))
                        IN ('1','Y','YES','TRUE','T') THEN 1 ELSE 0 END AS bit) AS Property_IsInactive_bit,

            -- RULE #1: Negative balance required (positive = 1)
            CAST(CASE WHEN b.endingBalance > 0 THEN 1 ELSE 0 END AS bit) AS Balance_Positive_bit,

            -- Active / Open legal status?
            CAST(CASE 
                   WHEN NULLIF(b.CurrentLegalStatus,N'') IS NOT NULL
                     AND LOWER(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(b.CurrentLegalStatus, NCHAR(8211), '-'),'–','-'),'  ',' '))))
                         NOT LIKE 'open%status missing%'
                 THEN 1 ELSE 0 END AS bit) AS Legal_ActiveOpen_bit,

            -- RULE #2: Must be present in snapshot
            CAST(CASE WHEN b.UnitRowAtAsOf IS NOT NULL THEN 1 ELSE 0 END AS bit) AS PresentAtAsOf_bit
        FROM base b
    ),


    -------------------------------------------------------------------------------------
    -- 6. FINAL INCLUDE/EXCLUDE LOGIC
    --
    -- A tenant appears in the Excel report ONLY IF ALL of these are true:
    --   (1) Balance is NEGATIVE
    --   (2) Present at snapshot (@AsOfDate)
    --   (3) Unit is NOT excluded
    --   (4) Property is NOT inactive
    -------------------------------------------------------------------------------------
    include_rule AS (
        SELECT
            f.*,
            CAST(CASE 
                    WHEN PresentAtAsOf_bit = 1   -- RULE #2
                     AND Balance_Positive_bit = 1 -- RULE #1
                     AND Unit_IsExcluded_bit = 0  -- RULE #4
                     AND Property_IsInactive_bit = 0 -- RULE #3
                    THEN 1 ELSE 0 END AS bit) AS IncludeInExcel_bit
        FROM flags f
    )


    -------------------------------------------------------------------------------------
    -- 7. FINAL OUTPUT
    -------------------------------------------------------------------------------------
    SELECT
        Portfolio,
        Property,
        Unit,
        Tenant,
        [Name],
        endingBalance,

        CASE WHEN ISNULL(CurrentLegalStatus, N'') = N'Open – status missing'
             THEN N'' ELSE CurrentLegalStatus END AS CurrentLegalStatus,

        CASE WHEN ISNULL(LastLegalNote,N'') IN (N'',N'1900-01-01 00:00:00.000')
             THEN N'' ELSE CONVERT(varchar(20), LastLegalNote, 120) END AS LastLegalNote,

        dayCounter,
        ISNULL(AttorneyName, '') AS Attorney,
        ISNULL(LawFirmCode, '')  AS LawFirmCode,
		CASE WHEN Legal_ActiveOpen_bit = 1 THEN 'Yes' ELSE 'No' END AS Legal_Active,   -- LEGAL ACTIVE
		CASE WHEN PresentAtAsOf_bit    = 1 THEN 'Yes' ELSE 'No' END AS PresentAsOf,

        STUFF(CONCAT(
              CASE WHEN Balance_Positive_bit    = 0 THEN '; non-positive balance'  ELSE '' END,
              CASE WHEN Legal_ActiveOpen_bit    = 0 THEN '; no active/open legal'  ELSE '' END,
              CASE WHEN Unit_IsExcluded_bit     = 1 THEN '; unit excluded'         ELSE '' END,
              CASE WHEN Property_IsInactive_bit = 1 THEN '; property inactive'     ELSE '' END,
              CASE WHEN PresentAtAsOf_bit       = 0 THEN '; not present in snapshot as-of' ELSE '' END
        ), 1, 2, '') AS ExclusionReason,
		
		TenantStatus,
		--moveInDate,
        LeaseStartDate,
        LeaseEndDate

        -- DIAGNOSTIC FLAGS
        --CASE WHEN Balance_Positive_bit     = 1 THEN 'Yes' ELSE 'No' END AS Balance_Positive_YN,
        --CASE WHEN Legal_ActiveOpen_bit     = 1 THEN 'Yes' ELSE 'No' END AS Legal_ActiveOpen_YN,
        --CASE WHEN Unit_IsExcluded_bit      = 1 THEN 'Yes' ELSE 'No' END AS Unit_Excluded_YN,
        --CASE WHEN Property_IsInactive_bit  = 1 THEN 'Yes' ELSE 'No' END AS Property_Inactive_YN,
        --CASE WHEN PresentAtAsOf_bit        = 1 THEN 'Yes' ELSE 'No' END AS PresentAtAsOf_YN,

    FROM include_rule
    WHERE (@FilterOnlyExcel = 0 OR IncludeInExcel_bit = 1)
    ORDER BY Property, Unit;

END;
GO
GRANT EXECUTE ON OBJECT::dbo.spReport_ArrearsTracker TO [lemwolffRO];
GO
