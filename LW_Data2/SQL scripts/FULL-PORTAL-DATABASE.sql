USE [master]
GO
/****** Object:  Database [lemlewolff]    Script Date: 2/27/2026 9:28:20 PM ******/
CREATE DATABASE [lemlewolff]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'lemlewolff', FILENAME = N'F:\Microsoft SQL Server\MSSQL14.PMSQL\MSSQL\DATA\lemlewolff_dev2.mdf' , SIZE = 477632KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'lemlewolff_log', FILENAME = N'F:\Microsoft SQL Server\MSSQL14.PMSQL\MSSQL\DATA\lemlewolff_dev2_log.ldf' , SIZE = 1187840KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
GO
ALTER DATABASE [lemlewolff] SET COMPATIBILITY_LEVEL = 140
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [lemlewolff].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [lemlewolff] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [lemlewolff] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [lemlewolff] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [lemlewolff] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [lemlewolff] SET ARITHABORT OFF 
GO
ALTER DATABASE [lemlewolff] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [lemlewolff] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [lemlewolff] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [lemlewolff] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [lemlewolff] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [lemlewolff] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [lemlewolff] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [lemlewolff] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [lemlewolff] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [lemlewolff] SET  DISABLE_BROKER 
GO
ALTER DATABASE [lemlewolff] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [lemlewolff] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [lemlewolff] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [lemlewolff] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [lemlewolff] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [lemlewolff] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [lemlewolff] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [lemlewolff] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [lemlewolff] SET  MULTI_USER 
GO
ALTER DATABASE [lemlewolff] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [lemlewolff] SET DB_CHAINING OFF 
GO
ALTER DATABASE [lemlewolff] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [lemlewolff] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [lemlewolff] SET DELAYED_DURABILITY = DISABLED 
GO
ALTER DATABASE [lemlewolff] SET QUERY_STORE = OFF
GO
USE [lemlewolff]
GO
/****** Object:  User [lemwolffRW]    Script Date: 2/27/2026 9:28:22 PM ******/
CREATE USER [lemwolffRW] FOR LOGIN [lemwolffRW] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [lemwolffRO]    Script Date: 2/27/2026 9:28:22 PM ******/
CREATE USER [lemwolffRO] FOR LOGIN [lemwolffRO] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [lempbiondo]    Script Date: 2/27/2026 9:28:22 PM ******/
CREATE USER [lempbiondo] FOR LOGIN [lempbiondo] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  DatabaseRole [report_reader]    Script Date: 2/27/2026 9:28:23 PM ******/
CREATE ROLE [report_reader]
GO
/****** Object:  DatabaseRole [etl_loader]    Script Date: 2/27/2026 9:28:23 PM ******/
CREATE ROLE [etl_loader]
GO
ALTER ROLE [db_owner] ADD MEMBER [lemwolffRW]
GO
ALTER ROLE [db_datareader] ADD MEMBER [lempbiondo]
GO
/****** Object:  UserDefinedTableType [dbo].[TT_ADPImportKeys]    Script Date: 2/27/2026 9:28:24 PM ******/
CREATE TYPE [dbo].[TT_ADPImportKeys] AS TABLE(
	[PayrollName] [varchar](100) NOT NULL,
	[PayDate] [datetime] NOT NULL,
	[WONumber] [varchar](10) NOT NULL
)
GO
/****** Object:  Table [dbo].[tblAttorneys]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblAttorneys](
	[AttorneyID] [int] IDENTITY(1,1) NOT NULL,
	[FirstName] [varchar](60) NULL,
	[LastName] [varchar](60) NULL,
	[DisplayName] [varchar](128) NOT NULL,
	[Email] [varchar](160) NULL,
	[Phone] [varchar](40) NULL,
	[BarNumber] [varchar](60) NULL,
	[Active] [bit] NOT NULL,
	[CreateDate] [datetime] NOT NULL,
	[ModifyDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[AttorneyID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tblAttorneysLawFirms]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblAttorneysLawFirms](
	[AttorneysLawFirmsID] [int] IDENTITY(1,1) NOT NULL,
	[AttorneyID] [int] NOT NULL,
	[LawFirmID] [int] NOT NULL,
	[EffectiveFrom] [date] NOT NULL,
	[EffectiveTo] [date] NULL,
	[Notes] [varchar](200) NULL,
PRIMARY KEY CLUSTERED 
(
	[AttorneysLawFirmsID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tblLegalRepresentation]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblLegalRepresentation](
	[RepresentationID] [int] IDENTITY(1,1) NOT NULL,
	[AttorneyID] [int] NOT NULL,
	[yardiLegalRowID] [int] NULL,
	[yardiPersonRowID] [int] NULL,
	[yardiUnitRowID] [int] NULL,
	[yardiPropertyRowID] [int] NULL,
	[EffectiveFrom] [date] NOT NULL,
	[EffectiveTo] [date] NULL,
	[Source] [varchar](32) NULL,
	[Notes] [varchar](200) NULL,
	[ScopeCount]  AS (((case when [yardiLegalRowID] IS NULL then (0) else (1) end+case when [yardiPersonRowID] IS NULL then (0) else (1) end)+case when [yardiUnitRowID] IS NULL then (0) else (1) end)+case when [yardiPropertyRowID] IS NULL then (0) else (1) end) PERSISTED,
PRIMARY KEY CLUSTERED 
(
	[RepresentationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tblLawFirms]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblLawFirms](
	[LawFirmID] [int] IDENTITY(1,1) NOT NULL,
	[FirmName] [varchar](160) NOT NULL,
	[LawFirmCode] [varchar](20) NULL,
	[Phone] [varchar](40) NULL,
	[Email] [varchar](160) NULL,
	[Address1] [varchar](120) NULL,
	[Address2] [varchar](120) NULL,
	[City] [varchar](60) NULL,
	[StateProv] [varchar](40) NULL,
	[PostalCode] [varchar](20) NULL,
	[Active] [bit] NOT NULL,
	[CreateDate] [datetime] NOT NULL,
	[ModDate] [datetime] NULL,
 CONSTRAINT [PK__tblLawFi__350E222F52B142D2] PRIMARY KEY CLUSTERED 
(
	[LawFirmID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tblTenants]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblTenants](
	[yardiPersonRowID] [int] NOT NULL,
	[tenantCode] [varchar](20) NOT NULL,
	[yardiPropertyRowID] [int] NOT NULL,
	[yardiUnitRowID] [int] NOT NULL,
	[firstName] [varchar](100) NULL,
	[lastName] [varchar](100) NULL,
	[statusCode] [int] NULL,
	[moveInDate] [date] NULL,
	[moveOutDate] [date] NULL,
	[email] [varchar](160) NULL,
	[modDate] [datetime] NOT NULL,
	[status] [varchar](32) NULL,
PRIMARY KEY CLUSTERED 
(
	[yardiPersonRowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[tenantCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[ufn_AttorneyOrFirm_AsOf]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   FUNCTION [dbo].[ufn_AttorneyOrFirm_AsOf] (@AsOfDate date)
RETURNS TABLE
AS
RETURN
(
  WITH Pick AS (
    SELECT
      lr.yardiPersonRowID, lr.AttorneyID, lr.EffectiveFrom, lr.EffectiveTo,
      rn = ROW_NUMBER() OVER (
             PARTITION BY lr.yardiPersonRowID
             ORDER BY lr.EffectiveFrom DESC,
                      ISNULL(lr.EffectiveTo, CONVERT(date,'99991231')) DESC,
                      lr.RepresentationID DESC
           )
    FROM dbo.tblLegalRepresentation lr
    WHERE lr.AttorneyID IS NOT NULL
      AND lr.EffectiveFrom <= @AsOfDate
      AND ISNULL(lr.EffectiveTo, CONVERT(date,'99991231')) >= @AsOfDate
  ),
  Chosen AS (
    SELECT yardiPersonRowID, AttorneyID, EffectiveFrom
    FROM Pick WHERE rn = 1
  )
  SELECT
      t.yardiPersonRowID,
      t.tenantCode,
      a.AttorneyID,
      AttorneyName =
        CASE WHEN a.DisplayName LIKE '%(placeholder)' THEN NULL ELSE a.DisplayName END,
      af.LawFirmID,
      af.FirmName    AS LawFirmName,
      af.LawFirmCode AS LawFirmCode,
      PartyLabel = COALESCE(
                    CASE WHEN a.DisplayName LIKE '%(placeholder)' THEN NULL ELSE a.DisplayName END,
                    af.FirmName
                  ),
      PartyCode = af.LawFirmCode
  FROM dbo.tblTenants t
  LEFT JOIN Chosen c
    ON c.yardiPersonRowID = t.yardiPersonRowID
  LEFT JOIN dbo.tblAttorneys a
    ON a.AttorneyID = c.AttorneyID
  OUTER APPLY (
     SELECT TOP (1) lf.LawFirmID, lf.FirmName, lf.LawFirmCode
     FROM dbo.tblAttorneysLawFirms alf
     JOIN dbo.tblLawFirms lf ON lf.LawFirmID = alf.LawFirmID
     WHERE alf.AttorneyID = c.AttorneyID
       AND alf.EffectiveFrom <= @AsOfDate
     ORDER BY
       CASE WHEN ISNULL(alf.EffectiveTo, CONVERT(date,'99991231')) >= @AsOfDate THEN 0 ELSE 1 END,
       alf.EffectiveFrom DESC,
       alf.AttorneysLawFirmsID DESC
  ) af
);
GO
/****** Object:  UserDefinedFunction [dbo].[fnAttorneyResolve]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnAttorneyResolve] (@AsOfDate date)
RETURNS TABLE
AS
RETURN
(
  WITH reps AS (
    SELECT
      lr.RepresentationID,
      lr.AttorneyID,
      lr.yardiLegalRowID,
      lr.yardiPersonRowID,
      lr.yardiUnitRowID,
      lr.yardiPropertyRowID,
      CASE
        WHEN lr.yardiLegalRowID    IS NOT NULL THEN 1
        WHEN lr.yardiPersonRowID   IS NOT NULL THEN 2
        WHEN lr.yardiUnitRowID     IS NOT NULL THEN 3
        ELSE 4
      END AS ScopePriority
    FROM dbo.tblLegalRepresentation lr
    WHERE lr.EffectiveFrom <= @AsOfDate
      AND (lr.EffectiveTo IS NULL OR lr.EffectiveTo >= @AsOfDate)
  ),
  att AS (
    SELECT
      r.*,
      a.DisplayName AS AttorneyLabel
    FROM reps r
    JOIN dbo.tblAttorneys a
      ON a.AttorneyID = r.AttorneyID
  ),
  firmNow AS (
    SELECT
      alf.AttorneyID,
      lf.LawFirmID,
      lf.FirmName,
      ROW_NUMBER() OVER (
        PARTITION BY alf.AttorneyID
        ORDER BY alf.EffectiveFrom DESC, alf.AttorneysLawFirmsID DESC
      ) AS rn
    FROM dbo.tblAttorneysLawFirms alf
    JOIN dbo.tblLawFirms lf
      ON lf.LawFirmID = alf.LawFirmID
    WHERE alf.EffectiveFrom <= @AsOfDate
      AND (alf.EffectiveTo IS NULL OR alf.EffectiveTo >= @AsOfDate)
  ),
  picked AS (
    SELECT
      a.yardiLegalRowID,
      a.yardiPersonRowID,
      a.yardiUnitRowID,
      a.yardiPropertyRowID,
      a.AttorneyID,
      a.AttorneyLabel,
      f.LawFirmID,
      f.FirmName AS LawFirmName,
      ROW_NUMBER() OVER (
        PARTITION BY
          COALESCE(a.yardiLegalRowID,0),
          COALESCE(a.yardiPersonRowID,0),
          COALESCE(a.yardiUnitRowID,0),
          COALESCE(a.yardiPropertyRowID,0)
        ORDER BY
          a.ScopePriority ASC,
          a.RepresentationID DESC
      ) AS rn
    FROM att a
    LEFT JOIN firmNow f
      ON f.AttorneyID = a.AttorneyID
     AND f.rn = 1
  )
  SELECT
    yardiLegalRowID,
    yardiPersonRowID,
    yardiUnitRowID,
    yardiPropertyRowID,
    AttorneyID,
    AttorneyLabel,
    LawFirmID,
    LawFirmName
  FROM picked
  WHERE rn = 1
);
GO
/****** Object:  Table [dbo].[tblLegalCasesActions]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblLegalCasesActions](
	[legalActionRowID] [bigint] NOT NULL,
	[yardiLegalRowID] [int] NOT NULL,
	[dtBegin] [datetime] NULL,
	[dtDue] [datetime] NULL,
	[sCheck] [varchar](64) NULL,
	[fAmount] [decimal](12, 2) NULL,
	[sNote] [nvarchar](4000) NULL,
	[dAttourneyFee] [decimal](12, 2) NULL,
	[dtCreated] [datetime] NULL,
	[dtLastModified] [datetime] NULL,
	[ActionTypeDesc] [varchar](50) NULL,
	[EventDesc] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[legalActionRowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tblLegalCases]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblLegalCases](
	[yardiLegalRowID] [int] NOT NULL,
	[yardiPersonRowID] [int] NOT NULL,
	[legalStatusKey] [int] NULL,
	[legalFlasherKey] [int] NULL,
	[unpaidCharges] [decimal](12, 2) NULL,
	[isClosed] [bit] NOT NULL,
	[createdDate] [datetime] NULL,
	[modifiedDate] [datetime] NULL,
	[legalStatus] [nvarchar](100) NULL,
	[legalFlasher] [nvarchar](100) NULL,
	[legalDisplay] [nvarchar](200) NULL,
	[RowHash] [varbinary](32) NULL,
PRIMARY KEY CLUSTERED 
(
	[yardiLegalRowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[vwLegalNoteCounts_ByPerson]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   VIEW [dbo].[vwLegalNoteCounts_ByPerson]
AS
WITH base AS (
    SELECT
        lc.yardiPersonRowID,
        CASE WHEN NULLIF(LTRIM(RTRIM(a.sNote)), '') IS NOT NULL THEN 1 ELSE 0 END AS hasNote
    FROM dbo.tblLegalCasesActions AS a
    JOIN dbo.tblLegalCases       AS lc
        ON lc.yardiLegalRowID = a.yardiLegalRowID
)
SELECT
    yardiPersonRowID,
    SUM(hasNote) AS AllNotesCount
FROM base
GROUP BY yardiPersonRowID;
GO
/****** Object:  View [dbo].[vw_AttorneyOrFirm_Today]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* ============================================================================
   4) VIEW
============================================================================ */
CREATE   VIEW [dbo].[vw_AttorneyOrFirm_Today]
AS
SELECT * FROM dbo.ufn_AttorneyOrFirm_AsOf(CONVERT(date, GETDATE()));
GO
/****** Object:  Table [dbo].[tblTenants_Snapshots]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblTenants_Snapshots](
	[yardiPersonRowID] [int] NOT NULL,
	[ValidFrom] [date] NOT NULL,
	[ValidTo] [date] NULL,
	[IsCurrent] [bit] NOT NULL,
	[yardiPropertyRowID] [int] NOT NULL,
	[yardiUnitRowID] [int] NOT NULL,
	[buildingCode] [varchar](20) NOT NULL,
	[aptNumber] [varchar](25) NULL,
	[tenantCode] [varchar](20) NOT NULL,
	[tenantName] [varchar](210) NOT NULL,
	[endingBalance] [decimal](12, 2) NOT NULL,
	[legalID_yardi] [int] NULL,
	[legalStatus] [varchar](50) NULL,
	[legalFlasher] [varchar](50) NULL,
	[unpaidChargesHeader] [decimal](12, 2) NULL,
	[lastLegalNoteDate] [datetime] NULL,
	[dayCounter] [int] NULL,
	[attorneyLabel] [varchar](64) NULL,
	[RowHash] [varbinary](32) NOT NULL,
	[LegalDisplay] [varchar](100) NULL,
 CONSTRAINT [PK_tblTenants_Snapshots] PRIMARY KEY CLUSTERED 
(
	[yardiPersonRowID] ASC,
	[ValidFrom] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tblPropertyUnits]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblPropertyUnits](
	[yardiUnitRowID] [int] NOT NULL,
	[yardiPropertyRowID] [int] NOT NULL,
	[AptNumber] [varchar](25) NULL,
	[Bedrooms] [int] NULL,
	[rent] [decimal](10, 2) NULL,
	[SqFt] [decimal](10, 2) NULL,
	[UnitStatus] [varchar](50) NULL,
	[LastMoveInDate] [date] NULL,
	[LastMoveOutDate] [date] NULL,
	[modDate] [datetime] NULL,
	[createDate] [datetime] NULL,
	[isExcluded] [bit] NOT NULL,
	[statusBasedOnDates]  AS (case when [LastMoveInDate] IS NOT NULL AND [LastMoveOutDate] IS NULL then 'Occupied' when [LastMoveOutDate] IS NOT NULL AND [LastMoveInDate]<=[LastMoveOutDate] then 'Vacant' else 'Occupied' end) PERSISTED NOT NULL,
	[LastTenantRent] [decimal](10, 2) NULL,
	[unitTypeDesc] [varchar](20) NULL,
	[LeaseStartDate] [datetime] NULL,
	[LeaseEndDate] [datetime] NULL,
	[CurrentTenantYardiID] [bigint] NULL,
 CONSTRAINT [PK_tblPropertyUnits] PRIMARY KEY CLUSTERED 
(
	[yardiUnitRowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tblProperties]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblProperties](
	[yardiPropertyRowID] [int] NOT NULL,
	[buildingCode] [varchar](20) NOT NULL,
	[addr1_Co] [varchar](75) NULL,
	[addr2] [varchar](75) NULL,
	[addr3] [varchar](75) NULL,
	[addr4] [varchar](75) NULL,
	[city] [varchar](75) NULL,
	[stateCode] [varchar](2) NULL,
	[zipCode] [varchar](10) NULL,
	[modDate] [datetime] NOT NULL,
	[isInactive] [bit] NOT NULL,
	[inactiveDate] [datetime] NULL,
	[fullAddress_calc]  AS (Trim(upper(concat(case when isnull([addr2],'')='' then '' else Trim([addr2])+', ' end,case when isnull([addr3],'')='' then '' else Trim([addr3])+', ' end,case when isnull([addr4],'')='' then '' else Trim([addr4])+', ' end,case when isnull([City],'')='' then '' else Trim([City])+', ' end,isnull([stateCode],''),' ',isnull([zipCode],''))))) PERSISTED,
	[isInList_Posting] [bit] NOT NULL,
	[isInList_Aquinas] [bit] NOT NULL,
	[portfolioName] [varchar](50) NULL,
 CONSTRAINT [PK_tblProperties_1] PRIMARY KEY CLUSTERED 
(
	[yardiPropertyRowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [IX_tblProperties] UNIQUE NONCLUSTERED 
(
	[buildingCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tblTenantAR_DailySnapshot]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[fnReceivableSummaryByTenant_Range]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   FUNCTION [dbo].[fnReceivableSummaryByTenant_Range]
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
           COALESCE(NULLIF(LTRIM(RTRIM(s.LegalDisplay)),N''), N'Open â€“ status missing') AS [Legal Status]
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
/****** Object:  Table [dbo].[tblLaborers]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblLaborers](
	[LaborerID] [int] IDENTITY(1,1) NOT NULL,
	[LastName] [varchar](250) NOT NULL,
	[FirstName] [varchar](250) NULL,
	[LWSalariedHourlyRate] [decimal](10, 2) NULL,
	[LWSmJobMinRateAdj] [decimal](10, 2) NULL,
	[LWOTRate] [decimal](10, 2) NULL,
	[LWMaterialRate] [decimal](10, 2) NULL,
	[WageIncrease2022] [decimal](10, 2) NULL,
	[includeForInventory] [bit] NOT NULL,
	[BonusFactor] [decimal](10, 2) NULL,
	[FullName_Calc]  AS (Trim([LastName])+isnull(', '+Trim([FirstName]),'')),
	[isSupervisor] [bit] NOT NULL,
	[isCoopSupplier] [bit] NOT NULL,
 CONSTRAINT [PK_tblLaborers] PRIMARY KEY CLUSTERED 
(
	[LaborerID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tblWorkOrders]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblWorkOrders](
	[MLID] [int] IDENTITY(1,1) NOT NULL,
	[WONumber] [int] NOT NULL,
	[CallDate] [datetime] NULL,
	[BuildingNum] [varchar](50) NULL,
	[AptNum] [varchar](50) NULL,
	[JobStatus] [varchar](50) NULL,
	[ScheduledCompletedDate] [datetime] NULL,
	[BatchID] [bigint] NULL,
	[BatchDate] [datetime] NULL,
	[TransBatchDate] [datetime] NULL,
	[InvoiceDate] [datetime] NULL,
	[PostedMonth] [varchar](10) NULL,
	[BriefDesc] [varchar](max) NULL,
	[Category] [varchar](50) NULL,
	[ExpenseType] [varchar](50) NULL,
	[InitialEstPrice] [decimal](10, 2) NULL,
	[SellingPricing] [decimal](10, 2) NULL,
	[MaterialPricingMarkupDesc] [varchar](250) NULL,
	[JobAssigned_Outside] [varchar](250) NULL,
	[PONumbers] [varchar](500) NULL,
	[POVendors] [varchar](max) NULL,
	[VendorInvoiceAmt] [decimal](10, 2) NULL,
	[MaterialFromInventCost] [decimal](10, 2) NULL,
	[PurchasedMaterialCost] [decimal](10, 2) NULL,
	[TotalMaterialCost] [decimal](20, 2) NULL,
	[TotalMaterialPricing] [decimal](10, 2) NULL,
	[LaborCost_Outside] [decimal](10, 2) NULL,
	[CompletedDate] [date] NULL,
	[DateOfSale] [datetime] NULL,
	[SchedDate] [datetime] NULL,
	[LaborPricing_Outside] [decimal](10, 2) NULL,
	[LaborAdj_OT] [decimal](10, 2) NULL,
	[Labor_Total] [decimal](10, 2) NULL,
	[Labor_MarkUp] [decimal](10, 2) NULL,
	[TotalMaterialsLaborAndOL] [decimal](10, 2) NULL,
	[FinalSalePrice] [decimal](10, 2) NULL,
	[SalesTax] [decimal](10, 2) NULL,
	[InvoicePrice] [decimal](10, 2) NULL,
	[GrossProfit] [decimal](10, 2) NULL,
	[CostPlusOH] [decimal](10, 2) NULL,
	[NetProfit] [decimal](10, 2) NULL,
	[GrossProfitMargin_Pct] [decimal](10, 2) NULL,
	[NetProfitMargin_Pct] [decimal](10, 2) NULL,
	[rowCreateDate] [datetime] NULL,
	[rowUpdateDate] [datetime] NULL,
	[yardiCreateDate] [datetime] NULL,
	[yardiUpdateDate] [datetime] NULL,
 CONSTRAINT [PK_tblMasterWOReview] PRIMARY KEY CLUSTERED 
(
	[MLID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tblADP]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblADP](
	[ADPRowID] [int] IDENTITY(1,1) NOT NULL,
	[CompanyCode] [varchar](50) NULL,
	[LaborerID] [int] NULL,
	[PayrollName] [varchar](100) NULL,
	[FileNumber] [varchar](50) NULL,
	[TimeIn] [datetime] NULL,
	[TimeOut] [datetime] NULL,
	[Location] [varchar](50) NULL,
	[WONumber] [varchar](10) NULL,
	[Department] [varchar](50) NULL,
	[PayDate] [datetime] NULL,
	[PayCode] [varchar](50) NULL,
	[Hours] [decimal](5, 3) NULL,
	[Dollars] [decimal](10, 2) NULL,
	[TimeDescription] [varchar](400) NULL,
	[WODescription] [varchar](400) NULL,
	[Dollars_Calculated] [decimal](10, 2) NULL,
	[CreatedBy] [varchar](20) NULL,
	[CreateDate] [datetime] NOT NULL,
	[isLockedForUpdates] [bit] NOT NULL,
 CONSTRAINT [PK_tblAMCTime] PRIMARY KEY CLUSTERED 
(
	[ADPRowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[vwADPWOHoursByLaborer]    Script Date: 2/27/2026 9:28:24 PM ******/
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
/****** Object:  Table [dbo].[tblLookupValues]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblLookupValues](
	[LookupValueID] [int] IDENTITY(1,1) NOT NULL,
	[Category] [varchar](25) NOT NULL,
	[KeyString] [varchar](50) NULL,
	[KeyString2] [varchar](50) NULL,
	[KeyValue] [decimal](10, 2) NOT NULL,
 CONSTRAINT [PK_tblLookupValues] PRIMARY KEY CLUSTERED 
(
	[LookupValueID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[vwWorkOrderLaborers]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   VIEW [dbo].[vwWorkOrderLaborers]
AS
  SELECT 
    a.WONumber,
    a.LaborerID,
    SUM(CASE WHEN PayCode IN ('REGULAR', 'REGSAL') THEN CAST([Hours] AS decimal(10,2)) ELSE 0 END) AS HrsReg,
    SUM(CASE WHEN PayCode IN ('OVERTIME') THEN CAST([Hours] AS decimal(10,2)) ELSE 0 END) AS HrsOT,
    SUM(CASE WHEN PayCode IN ('REGULAR', 'REGSAL') THEN Dollars_Calculated ELSE 0 END) AS CostReg,
    SUM(CASE WHEN PayCode IN ('OVERTIME') THEN Dollars_Calculated ELSE 0 END) AS CostOT,
    MAX(ISNULL(wo.FinalSalePrice,0)) AS FinalSalePrice,
    wo.TotalMaterialPricing,
    ISNULL(l.BonusFactor,0) AS BonusFactor,
    NULLIF(bfTot.sumBonusFactorsForWO,0) AS SumBonusFactor,
    CAST(
      (MAX(ISNULL(wo.FinalSalePrice,0)) - ISNULL(wo.TotalMaterialPricing,0))
      * (ISNULL(l.BonusFactor,0) / NULLIF(bfTot.sumBonusFactorsForWO,0))
      * (SELECT ISNULL(KeyValue,0) FROM tblLookupValues WHERE Category='Bonus' AND KeyString='PercentOfSalePrice')
      AS decimal(10,2)
    ) AS BonusCalc
  FROM tblADP a
  LEFT JOIN tblWorkOrders wo ON a.WONumber = wo.WONumber
  LEFT JOIN tblLaborers l ON a.LaborerID = l.LaborerID
  LEFT JOIN (
      SELECT l.wonumber, SUM(bonusFactor) AS sumBonusFactorsForWO
      FROM vwADPWOHoursByLaborer l 
      INNER JOIN tblLaborers l2 ON l.laborerid = l2.LaborerID
      GROUP BY l.wonumber
  ) AS bfTot ON a.WONumber = bfTot.WONumber
  WHERE a.LaborerID IS NOT NULL 
    AND ISNULL(a.WONumber,0) > 0
  GROUP BY a.WONumber, a.LaborerID, l.BonusFactor, bfTot.sumBonusFactorsForWO, 
           wo.FinalSalePrice, wo.TotalMaterialPricing, l.BonusFactor, bfTot.sumBonusFactorsForWO;
GO
/****** Object:  Table [dbo].[tblImport_Yardi_POs]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblImport_Yardi_POs](
	[Yardi_POListID] [int] IDENTITY(1,1) NOT NULL,
	[WONumber] [int] NOT NULL,
	[CallDate] [datetime] NULL,
	[PONumber] [int] NULL,
	[VendorCode] [varchar](25) NULL,
	[VendorName] [varchar](250) NULL,
	[InvoiceDate] [datetime] NULL,
	[AcctCode] [varchar](20) NULL,
	[AcctCategory] [varchar](20) NULL,
	[AcctDesc] [varchar](75) NULL,
	[IndivPOTotal] [decimal](10, 2) NOT NULL,
	[POAmount] [decimal](10, 2) NOT NULL,
	[WOAndInvoiceAmt] [decimal](10, 2) NOT NULL,
	[LaborPricingOutside] [decimal](10, 2) NULL,
	[expenseType] [varchar](50) NULL,
	[requestedBy] [varchar](100) NULL,
	[PODate] [datetime] NULL,
	[createdBy] [varchar](25) NULL,
	[createDate] [datetime] NOT NULL,
 CONSTRAINT [PK_tblImport_Yardi_POs] PRIMARY KEY CLUSTERED 
(
	[Yardi_POListID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tblVendors]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblVendors](
	[VendorID] [int] IDENTITY(1,1) NOT NULL,
	[VendorCode] [varchar](20) NULL,
	[VendorName] [varchar](50) NULL,
	[isSubcontractor] [bit] NOT NULL,
	[createDate] [datetime] NULL,
 CONSTRAINT [PK_tblVendors] PRIMARY KEY CLUSTERED 
(
	[VendorID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[vwPO_GroupLaborMaterialsVendor]    Script Date: 2/27/2026 9:28:24 PM ******/
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
/****** Object:  Table [dbo].[tblImport_Yardi_WOList]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblImport_Yardi_WOList](
	[WOListRowID] [int] IDENTITY(1,1) NOT NULL,
	[WODetailRowID] [int] NULL,
	[WONumber] [int] NOT NULL,
	[BuildingNum] [varchar](50) NULL,
	[AptNum] [varchar](50) NULL,
	[JobStatus] [varchar](50) NULL,
	[Category] [varchar](50) NULL,
	[CallDate] [datetime] NULL,
	[xxx_StartDate] [datetime] NULL,
	[SchedDate] [datetime] NULL,
	[BatchID] [bigint] NULL,
	[BatchDate] [datetime] NULL,
	[TransBatchDate] [datetime] NULL,
	[CompleteDate] [datetime] NULL,
	[Employee] [varchar](100) NULL,
	[BriefDesc] [varchar](1000) NULL,
	[Quantity] [decimal](10, 2) NULL,
	[Code] [varchar](50) NULL,
	[FullDesc] [varchar](250) NULL,
	[UnitPrice] [decimal](10, 2) NULL,
	[PayAmt] [decimal](10, 2) NULL,
	[PostedMonth] [varchar](10) NULL,
	[createdBy] [varchar](25) NULL,
	[createDate] [datetime] NULL,
 CONSTRAINT [PK_tblImport_Yardi_MaintWOList_1] PRIMARY KEY CLUSTERED 
(
	[WOListRowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[vwWO_DistinctWOs]    Script Date: 2/27/2026 9:28:24 PM ******/
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
/****** Object:  View [dbo].[vwWorkOrderLaborerNames]    Script Date: 2/27/2026 9:28:24 PM ******/
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
/****** Object:  View [dbo].[vwUnitOccupancy]    Script Date: 2/27/2026 9:28:24 PM ******/
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
/****** Object:  View [dbo].[vwWOTeamGroups]    Script Date: 2/27/2026 9:28:24 PM ******/
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
/****** Object:  View [dbo].[vwPropertyUnitCount]    Script Date: 2/27/2026 9:28:24 PM ******/
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
/****** Object:  Table [dbo].[tblAdminApps]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblAdminApps](
	[AppRowID] [int] IDENTITY(1,1) NOT NULL,
	[AppName] [varchar](50) NOT NULL,
	[URL] [varchar](100) NOT NULL,
	[LogoFilePath] [varchar](250) NULL,
 CONSTRAINT [PK_tblAdminApps] PRIMARY KEY CLUSTERED 
(
	[AppRowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tblChargeCodes]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblChargeCodes](
	[chargeCodeID] [int] IDENTITY(1,1) NOT NULL,
	[ChargeCode] [varchar](10) NOT NULL,
	[CategoryNum] [int] NOT NULL,
 CONSTRAINT [PK_tblChargeCodes] PRIMARY KEY CLUSTERED 
(
	[chargeCodeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tblFileStore]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblFileStore](
	[FileID] [int] IDENTITY(1,1) NOT NULL,
	[FileCategory] [nvarchar](100) NOT NULL,
	[RelatedTable] [nvarchar](100) NULL,
	[RelatedRecordID] [int] NULL,
	[BuildingID] [int] NULL,
	[UnitID] [int] NULL,
	[TenantID] [int] NULL,
	[FilePath] [nvarchar](500) NOT NULL,
	[FileName] [nvarchar](255) NOT NULL,
	[FileExtension] [nvarchar](20) NOT NULL,
	[FileSizeBytes] [bigint] NULL,
	[CreatedDate] [datetime] NOT NULL,
	[CreatedByUser] [nvarchar](100) NOT NULL,
 CONSTRAINT [PK_tblFileStore] PRIMARY KEY CLUSTERED 
(
	[FileID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tblImport_Inv_Yardi_POItems]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblImport_Inv_Yardi_POItems](
	[POItemRowID] [int] IDENTITY(1,1) NOT NULL,
	[YardiMM2PODetID] [bigint] NULL,
	[PONumber] [int] NOT NULL,
	[WONumber] [int] NULL,
	[Vendor] [varchar](250) NULL,
	[QtyOrdered] [decimal](10, 2) NULL,
	[UnitPrice] [decimal](10, 2) NULL,
	[TotalCost] [decimal](10, 2) NULL,
	[OrderDate] [datetime] NULL,
	[ReceivedDate] [datetime] NULL,
	[ItemCode] [varchar](15) NULL,
	[ItemDesc] [varchar](200) NULL,
	[ExpenseType] [varchar](50) NULL,
	[isSeedItem] [bit] NOT NULL,
	[Client] [varchar](150) NULL,
	[VendorCode] [varchar](25) NULL,
	[POAmount] [decimal](10, 2) NULL,
	[WOAndInvoiceAmt] [decimal](10, 2) NULL,
	[AggregateSourceIDs] [varchar](max) NULL,
	[RowCountAggregated] [int] NULL,
	[LastUpdateReason] [varchar](200) NULL,
	[LastUpdateDate] [datetime] NULL,
 CONSTRAINT [PK_tblImport_Inv_Yardi_POItems] PRIMARY KEY CLUSTERED 
(
	[POItemRowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tblImport_Inv_Yardi_WOItems]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblImport_Inv_Yardi_WOItems](
	[WOItemRowID] [int] IDENTITY(1,1) NOT NULL,
	[WONumber] [int] NOT NULL,
	[Category] [varchar](50) NULL,
	[BriefDesc] [varchar](500) NULL,
	[ItemCode] [varchar](15) NULL,
	[ItemDesc] [varchar](250) NULL,
	[Qty] [int] NULL,
	[UnitPrice] [decimal](10, 2) NULL,
	[TotalAmt] [decimal](10, 2) NULL,
	[CompleteDate] [datetime] NULL,
	[isSeedItem] [bit] NOT NULL,
	[Vendor] [varchar](250) NULL,
	[Client] [varchar](250) NULL,
 CONSTRAINT [PK_tblImport_Inv_Yardi_WOItems] PRIMARY KEY CLUSTERED 
(
	[WOItemRowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tblImport_Sortly]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblImport_Sortly](
	[SortlyImportRowID] [int] IDENTITY(1,1) NOT NULL,
	[WONumber_Calc] [int] NULL,
	[xxx_ActivityDate_Calc] [datetime] NULL,
	[SortlyID] [varchar](20) NULL,
	[ItemName] [varchar](100) NULL,
	[Quantity] [int] NULL,
	[UnitPrice] [decimal](10, 2) NULL,
	[TotalValue] [decimal](10, 2) NULL,
	[Notes] [varchar](500) NULL,
	[xxx_Tags] [varchar](100) NULL,
	[PrimaryFolder] [varchar](100) NULL,
	[SubFolderLevel1] [varchar](100) NULL,
	[SubFolderLevel2] [varchar](100) NULL,
	[SubFolderLevel3] [varchar](100) NULL,
	[SubFolderLevel4] [varchar](100) NULL,
	[WODate] [datetime] NULL,
	[xxx_SellPrice] [decimal](10, 2) NULL,
	[xxx_LandedCost] [decimal](10, 2) NULL,
	[createdby] [varchar](50) NULL,
	[createDate] [datetime] NOT NULL,
 CONSTRAINT [PK_tblImport_Sortly] PRIMARY KEY CLUSTERED 
(
	[SortlyImportRowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tblImportDates]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblImportDates](
	[DateKey] [varchar](25) NOT NULL,
	[ExportFileNum] [int] NULL,
	[LatestImportDateRange_Date1] [datetime] NULL,
	[LatestImportDateRange_Date2] [datetime] NOT NULL,
	[UpdateDate] [datetime] NOT NULL,
 CONSTRAINT [PK_tblImportDates] PRIMARY KEY CLUSTERED 
(
	[DateKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tblInvalidPOItems]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblInvalidPOItems](
	[PONumber] [int] NOT NULL,
	[ItemCode] [varchar](50) NOT NULL,
	[Quantity] [decimal](10, 2) NOT NULL,
	[Comment] [varchar](400) NULL,
 CONSTRAINT [PK_tblInvalidPOItems] PRIMARY KEY CLUSTERED 
(
	[PONumber] ASC,
	[ItemCode] ASC,
	[Quantity] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tblInventoryTracking]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblInventoryTracking](
	[MasterInvID] [int] IDENTITY(1,1) NOT NULL,
	[isSeedItem] [bit] NOT NULL,
	[ItemCode] [varchar](50) NOT NULL,
	[ItemDesc] [varchar](250) NULL,
	[WONumber] [int] NULL,
	[PONumber] [int] NULL,
	[Source] [varchar](25) NULL,
	[YardiMM2PODetID] [bigint] NULL,
	[Quantity] [decimal](10, 2) NULL,
	[UnitPrice] [decimal](10, 2) NULL,
	[Total] [decimal](10, 2) NULL,
	[ReceivedDate] [datetime] NULL,
	[DateOfSale] [datetime] NULL,
	[Category] [varchar](50) NULL,
	[ExpenseType] [varchar](50) NULL,
	[Vendor] [varchar](250) NULL,
	[Client] [varchar](250) NULL,
	[ReportingDate_calc]  AS (case when [ReceivedDate] IS NOT NULL then [ReceivedDate] when [DateOfSale] IS NULL OR [Source]='Sortly' then [ReceivedDate] else [DateOfSale] end),
	[ReportingDate_Source] [varchar](50) NULL,
	[ReceivedDate_IsNullAtImport] [bit] NULL,
 CONSTRAINT [PK_tblInventoryTracking] PRIMARY KEY CLUSTERED 
(
	[MasterInvID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tblLegalCases_History]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblLegalCases_History](
	[HistoryID] [bigint] IDENTITY(1,1) NOT NULL,
	[yardiLegalRowID] [int] NOT NULL,
	[yardiPersonRowID] [int] NULL,
	[legalStatus] [nvarchar](100) NULL,
	[legalFlasher] [nvarchar](100) NULL,
	[legalDisplay] [nvarchar](200) NULL,
	[isClosed] [bit] NOT NULL,
	[unpaidCharges] [decimal](12, 2) NULL,
	[createdDate] [datetime] NULL,
	[modifiedDate] [datetime] NULL,
	[validFrom] [datetime2](0) NOT NULL,
	[validTo] [date] NULL,
	[RowHash] [varbinary](32) NULL,
 CONSTRAINT [PK_tblLegalCases_History] PRIMARY KEY CLUSTERED 
(
	[HistoryID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_tblLegalCases_History] UNIQUE NONCLUSTERED 
(
	[yardiLegalRowID] ASC,
	[validFrom] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tblPhysicalInventory]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblPhysicalInventory](
	[PIRowID] [int] IDENTITY(1,1) NOT NULL,
	[AsOfDate] [datetime] NOT NULL,
	[Code] [varchar](10) NULL,
	[Description] [varchar](250) NULL,
	[PhysicalCount] [int] NULL,
	[createDate] [datetime] NOT NULL,
	[createdBy] [varchar](25) NOT NULL,
	[modDate] [datetime] NULL,
	[modBy] [varchar](25) NULL,
 CONSTRAINT [PK_tblPhysicalInventory] PRIMARY KEY CLUSTERED 
(
	[PIRowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tblPrintHistory]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblPrintHistory](
	[PrintHistoryID] [int] IDENTITY(1,1) NOT NULL,
	[PrintType] [nvarchar](100) NOT NULL,
	[BuildingID] [int] NULL,
	[UnitID] [int] NULL,
	[TenantID] [int] NULL,
	[CombinedFileID] [int] NULL,
	[CreatedByUser] [nvarchar](100) NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[UnitCount] [int] NULL,
	[Notes] [nvarchar](500) NULL,
 CONSTRAINT [PK_tblPrintHistory] PRIMARY KEY CLUSTERED 
(
	[PrintHistoryID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tblPurchaseOrders]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblPurchaseOrders](
	[PurchaseOrderID] [int] IDENTITY(1,1) NOT NULL,
	[PONumber] [int] NOT NULL,
	[WONumber] [int] NOT NULL,
	[CallDate] [datetime] NULL,
	[VendorCode] [varchar](25) NULL,
	[VendorName] [varchar](250) NULL,
	[expenseType] [varchar](50) NULL,
	[POAmount] [decimal](10, 2) NOT NULL,
	[WOAndInvoiceAmt] [decimal](10, 2) NOT NULL,
	[OrderDate] [datetime] NULL,
	[ReceivedDate] [datetime] NULL,
	[TotalCostOfItems] [decimal](10, 2) NULL,
 CONSTRAINT [PK_tblPurchaseOrders] PRIMARY KEY CLUSTERED 
(
	[PONumber] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tblPurchaseOrders_Details]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblPurchaseOrders_Details](
	[podetailID] [int] IDENTITY(1,1) NOT NULL,
	[YardiPODetailRowID] [bigint] NULL,
	[PONumber] [int] NOT NULL,
	[QTYOrdered] [decimal](10, 2) NULL,
	[UnitPrice] [decimal](10, 2) NULL,
	[OrderDate] [datetime] NULL,
	[ItemCode] [varchar](15) NULL,
	[ItemDesc] [varchar](200) NULL,
	[ReceivedDate] [datetime] NULL,
 CONSTRAINT [PK_tblPurchaseOrders_Details] PRIMARY KEY CLUSTERED 
(
	[podetailID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_tblPurchaseOrders_Details_YardiPODetailRowID] UNIQUE NONCLUSTERED 
(
	[YardiPODetailRowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tblSortlyInventory]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblSortlyInventory](
	[SortlyInvID] [int] IDENTITY(1,1) NOT NULL,
	[itemCode] [varchar](10) NOT NULL,
	[itemName] [varchar](150) NULL,
	[SortlyID] [varchar](20) NULL,
	[UnitPrice] [decimal](10, 2) NULL,
	[Category] [varchar](50) NULL,
 CONSTRAINT [PK_tblSortlyInventory] PRIMARY KEY CLUSTERED 
(
	[SortlyInvID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tblStg_Attornys]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblStg_Attornys](
	[propertyID] [varchar](50) NULL,
	[UnitName] [varchar](20) NULL,
	[TenantID] [varchar](20) NULL,
	[AttyCode] [varchar](20) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tblStg_LegalCases]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblStg_LegalCases](
	[yardiLegalRowID] [int] NOT NULL,
	[yardiPersonRowID] [int] NOT NULL,
	[legalStatusDesc] [varchar](50) NULL,
	[legalFlash] [varchar](50) NULL,
	[unpaidCharges] [decimal](12, 2) NULL,
	[isClosed] [int] NULL,
	[createdDate] [datetime] NULL,
	[modifiedDate] [datetime] NULL,
	[legalDisplay] [varchar](100) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tblStg_LegalCasesActions]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblStg_LegalCasesActions](
	[legalActionRowID] [bigint] NOT NULL,
	[yardiLegalRowID] [int] NOT NULL,
	[dtBegin] [datetime] NULL,
	[dtDue] [datetime] NULL,
	[ActionTypeDesc] [varchar](50) NULL,
	[EventDesc] [varchar](50) NULL,
	[sCheck] [varchar](64) NULL,
	[fAmount] [decimal](12, 2) NULL,
	[sNote] [varchar](max) NULL,
	[dAttourneyFee] [decimal](12, 2) NULL,
	[dtCreated] [datetime] NULL,
	[dtLastModified] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tblStg_PropertyPortfolio]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblStg_PropertyPortfolio](
	[buildingCode] [varchar](20) NOT NULL,
	[portfolioName] [varchar](64) NOT NULL,
	[ownerName] [varchar](128) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tblStg_TenantARSummary]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblStg_TenantARSummary](
	[AsOfDate] [date] NOT NULL,
	[yardiPersonRowID] [int] NOT NULL,
	[yardiPropertyRowID] [int] NOT NULL,
	[yardiUnitRowID] [int] NOT NULL,
	[balanceFwd] [decimal](12, 2) NULL,
	[charges] [decimal](12, 2) NULL,
	[receipts] [decimal](12, 2) NULL,
	[endingBalance] [decimal](12, 2) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tblStg_Tenants]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblStg_Tenants](
	[yardiPersonRowID] [int] NOT NULL,
	[tenantCode] [varchar](20) NOT NULL,
	[yardiPropertyRowID] [int] NOT NULL,
	[yardiUnitRowID] [int] NOT NULL,
	[firstName] [varchar](100) NULL,
	[lastName] [varchar](100) NULL,
	[status] [varchar](20) NULL,
	[moveInDate] [date] NULL,
	[moveOutDate] [date] NULL,
	[email] [varchar](400) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tblTenantARSummary]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblTenantARSummary](
	[AsOfDate] [date] NOT NULL,
	[yardiPersonRowID] [int] NOT NULL,
	[yardiPropertyRowID] [int] NOT NULL,
	[yardiUnitRowID] [int] NOT NULL,
	[balanceFwd] [decimal](12, 2) NULL,
	[charges] [decimal](12, 2) NULL,
	[receipts] [decimal](12, 2) NULL,
	[endingBalance] [decimal](12, 2) NULL,
	[ImportCreatedUtc] [datetime2](7) NOT NULL,
	[ImportUpdatedUtc] [datetime2](7) NULL,
 CONSTRAINT [PK_tblTenantARSummary] PRIMARY KEY CLUSTERED 
(
	[AsOfDate] ASC,
	[yardiPropertyRowID] ASC,
	[yardiUnitRowID] ASC,
	[yardiPersonRowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tblUsers]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblUsers](
	[UserID] [int] IDENTITY(1,1) NOT NULL,
	[emailAddress] [varchar](200) NOT NULL,
	[FirstName] [varchar](50) NOT NULL,
	[LastName] [varchar](50) NOT NULL,
	[password_enc] [varchar](500) NOT NULL,
	[tempPassword_enc] [varchar](500) NULL,
	[isAdmin] [bit] NOT NULL,
	[isSuperAdmin] [bit] NOT NULL,
	[isProjectManager] [bit] NOT NULL,
	[isLegalTeam] [bit] NOT NULL,
	[isDisabled] [bit] NOT NULL,
	[createDate] [datetime] NOT NULL,
 CONSTRAINT [PK_tblUsers] PRIMARY KEY CLUSTERED 
(
	[UserID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tblWorkOrderItems]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblWorkOrderItems](
	[WOItemRowID] [int] IDENTITY(1,1) NOT NULL,
	[YardiWODetailRowID] [int] NOT NULL,
	[WONumber] [int] NOT NULL,
	[ItemCode] [varchar](50) NOT NULL,
	[Quantity] [int] NULL,
	[PayAmount] [decimal](10, 2) NULL,
	[FullDescription] [varchar](250) NULL,
 CONSTRAINT [PK_tblWorkOrderItems] PRIMARY KEY CLUSTERED 
(
	[WOItemRowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tmp_POBackfill]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tmp_POBackfill](
	[YardiMM2PODetID] [bigint] NOT NULL,
	[PONumber] [int] NOT NULL,
	[WONumber] [int] NULL,
	[Vendor] [varchar](250) NULL,
	[QtyOrdered] [decimal](18, 2) NOT NULL,
	[UnitPrice] [decimal](18, 2) NOT NULL,
	[ReceivedDate] [datetime] NULL,
	[OrderDate] [datetime] NULL,
	[ItemCode] [varchar](50) NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Index [IX_tblAttorneysLawFirms_Attorney_Current]    Script Date: 2/27/2026 9:28:24 PM ******/
CREATE NONCLUSTERED INDEX [IX_tblAttorneysLawFirms_Attorney_Current] ON [dbo].[tblAttorneysLawFirms]
(
	[AttorneyID] ASC,
	[EffectiveFrom] ASC,
	[EffectiveTo] ASC
)
INCLUDE([LawFirmID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [UX_tblAttorneysLawFirms_AttorneyFirmStart]    Script Date: 2/27/2026 9:28:24 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_tblAttorneysLawFirms_AttorneyFirmStart] ON [dbo].[tblAttorneysLawFirms]
(
	[AttorneyID] ASC,
	[LawFirmID] ASC,
	[EffectiveFrom] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_tblFileStore_BuildingID]    Script Date: 2/27/2026 9:28:24 PM ******/
CREATE NONCLUSTERED INDEX [IX_tblFileStore_BuildingID] ON [dbo].[tblFileStore]
(
	[BuildingID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_tblFileStore_CreatedDate]    Script Date: 2/27/2026 9:28:24 PM ******/
CREATE NONCLUSTERED INDEX [IX_tblFileStore_CreatedDate] ON [dbo].[tblFileStore]
(
	[CreatedDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_tblFileStore_TenantID]    Script Date: 2/27/2026 9:28:24 PM ******/
CREATE NONCLUSTERED INDEX [IX_tblFileStore_TenantID] ON [dbo].[tblFileStore]
(
	[TenantID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_tblFileStore_UnitID]    Script Date: 2/27/2026 9:28:24 PM ******/
CREATE NONCLUSTERED INDEX [IX_tblFileStore_UnitID] ON [dbo].[tblFileStore]
(
	[UnitID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_tblImport_Yardi_POs]    Script Date: 2/27/2026 9:28:24 PM ******/
CREATE NONCLUSTERED INDEX [IX_tblImport_Yardi_POs] ON [dbo].[tblImport_Yardi_POs]
(
	[WONumber] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_tblInventoryTracking_YardiDetailID]    Script Date: 2/27/2026 9:28:24 PM ******/
CREATE NONCLUSTERED INDEX [IX_tblInventoryTracking_YardiDetailID] ON [dbo].[tblInventoryTracking]
(
	[YardiMM2PODetID] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_tblLaborers]    Script Date: 2/27/2026 9:28:24 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_tblLaborers] ON [dbo].[tblLaborers]
(
	[FirstName] ASC,
	[LastName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_tblLegalCases_Open_ByPerson_Mod]    Script Date: 2/27/2026 9:28:24 PM ******/
CREATE NONCLUSTERED INDEX [IX_tblLegalCases_Open_ByPerson_Mod] ON [dbo].[tblLegalCases]
(
	[yardiPersonRowID] ASC,
	[modifiedDate] DESC,
	[yardiLegalRowID] DESC
)
INCLUDE([legalStatus],[legalFlasher],[legalDisplay],[unpaidCharges],[createdDate]) 
WHERE ([isClosed]=(0))
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_tblLegalCases_RowHash]    Script Date: 2/27/2026 9:28:24 PM ******/
CREATE NONCLUSTERED INDEX [IX_tblLegalCases_RowHash] ON [dbo].[tblLegalCases]
(
	[RowHash] ASC
)
INCLUDE([yardiLegalRowID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_tblLegalCases_Tenant]    Script Date: 2/27/2026 9:28:24 PM ******/
CREATE NONCLUSTERED INDEX [IX_tblLegalCases_Tenant] ON [dbo].[tblLegalCases]
(
	[yardiPersonRowID] ASC,
	[yardiLegalRowID] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_tblLegalCases_History_Open]    Script Date: 2/27/2026 9:28:24 PM ******/
CREATE NONCLUSTERED INDEX [IX_tblLegalCases_History_Open] ON [dbo].[tblLegalCases_History]
(
	[yardiLegalRowID] ASC
)
INCLUDE([validFrom],[validTo]) 
WHERE ([validTo] IS NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_tblLegalRep_CurrentByCase]    Script Date: 2/27/2026 9:28:24 PM ******/
CREATE NONCLUSTERED INDEX [IX_tblLegalRep_CurrentByCase] ON [dbo].[tblLegalRepresentation]
(
	[yardiLegalRowID] ASC,
	[EffectiveFrom] ASC,
	[EffectiveTo] ASC,
	[AttorneyID] ASC
)
WHERE ([yardiLegalRowID] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_tblLegalRep_CurrentByPerson]    Script Date: 2/27/2026 9:28:24 PM ******/
CREATE NONCLUSTERED INDEX [IX_tblLegalRep_CurrentByPerson] ON [dbo].[tblLegalRepresentation]
(
	[yardiPersonRowID] ASC,
	[EffectiveFrom] ASC,
	[EffectiveTo] ASC,
	[AttorneyID] ASC
)
WHERE ([yardiPersonRowID] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_tblLegalRep_CurrentByProperty]    Script Date: 2/27/2026 9:28:24 PM ******/
CREATE NONCLUSTERED INDEX [IX_tblLegalRep_CurrentByProperty] ON [dbo].[tblLegalRepresentation]
(
	[yardiPropertyRowID] ASC,
	[EffectiveFrom] ASC,
	[EffectiveTo] ASC,
	[AttorneyID] ASC
)
WHERE ([yardiPropertyRowID] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_tblLegalRep_CurrentByUnit]    Script Date: 2/27/2026 9:28:24 PM ******/
CREATE NONCLUSTERED INDEX [IX_tblLegalRep_CurrentByUnit] ON [dbo].[tblLegalRepresentation]
(
	[yardiUnitRowID] ASC,
	[EffectiveFrom] ASC,
	[EffectiveTo] ASC,
	[AttorneyID] ASC
)
WHERE ([yardiUnitRowID] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [UX_tblLegalRep_Case]    Script Date: 2/27/2026 9:28:24 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_tblLegalRep_Case] ON [dbo].[tblLegalRepresentation]
(
	[yardiLegalRowID] ASC,
	[EffectiveFrom] ASC
)
WHERE ([yardiLegalRowID] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [UX_tblLegalRep_Person]    Script Date: 2/27/2026 9:28:24 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_tblLegalRep_Person] ON [dbo].[tblLegalRepresentation]
(
	[yardiPersonRowID] ASC,
	[EffectiveFrom] ASC
)
WHERE ([yardiPersonRowID] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [UX_tblLegalRep_Property]    Script Date: 2/27/2026 9:28:24 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_tblLegalRep_Property] ON [dbo].[tblLegalRepresentation]
(
	[yardiPropertyRowID] ASC,
	[EffectiveFrom] ASC
)
WHERE ([yardiPropertyRowID] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [UX_tblLegalRep_Unit]    Script Date: 2/27/2026 9:28:24 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_tblLegalRep_Unit] ON [dbo].[tblLegalRepresentation]
(
	[yardiUnitRowID] ASC,
	[EffectiveFrom] ASC
)
WHERE ([yardiUnitRowID] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_tblSeedInventory]    Script Date: 2/27/2026 9:28:24 PM ******/
CREATE NONCLUSTERED INDEX [IX_tblSeedInventory] ON [dbo].[tblPhysicalInventory]
(
	[AsOfDate] ASC,
	[Code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_tblPrintHistory_BuildingID]    Script Date: 2/27/2026 9:28:24 PM ******/
CREATE NONCLUSTERED INDEX [IX_tblPrintHistory_BuildingID] ON [dbo].[tblPrintHistory]
(
	[BuildingID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_tblPrintHistory_CreatedDate]    Script Date: 2/27/2026 9:28:24 PM ******/
CREATE NONCLUSTERED INDEX [IX_tblPrintHistory_CreatedDate] ON [dbo].[tblPrintHistory]
(
	[CreatedDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_tblPrintHistory_UnitID]    Script Date: 2/27/2026 9:28:24 PM ******/
CREATE NONCLUSTERED INDEX [IX_tblPrintHistory_UnitID] ON [dbo].[tblPrintHistory]
(
	[UnitID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_tblPropertyUnits]    Script Date: 2/27/2026 9:28:24 PM ******/
CREATE NONCLUSTERED INDEX [IX_tblPropertyUnits] ON [dbo].[tblPropertyUnits]
(
	[yardiPropertyRowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_tblPropertyUnits_1]    Script Date: 2/27/2026 9:28:24 PM ******/
CREATE NONCLUSTERED INDEX [IX_tblPropertyUnits_1] ON [dbo].[tblPropertyUnits]
(
	[yardiPropertyRowID] ASC,
	[yardiUnitRowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_tblPropertyUnits_yUnit]    Script Date: 2/27/2026 9:28:24 PM ******/
CREATE NONCLUSTERED INDEX [IX_tblPropertyUnits_yUnit] ON [dbo].[tblPropertyUnits]
(
	[yardiUnitRowID] ASC
)
INCLUDE([AptNumber],[isExcluded]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_tblSortlyInventory_ItemCode]    Script Date: 2/27/2026 9:28:24 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_tblSortlyInventory_ItemCode] ON [dbo].[tblSortlyInventory]
(
	[itemCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_tblTenantAR_DailySnapshot_AsOfDate]    Script Date: 2/27/2026 9:28:24 PM ******/
CREATE NONCLUSTERED INDEX [IX_tblTenantAR_DailySnapshot_AsOfDate] ON [dbo].[tblTenantAR_DailySnapshot]
(
	[AsOfDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_tblTenantAR_DailySnapshot_Tenant_AsOfDate]    Script Date: 2/27/2026 9:28:24 PM ******/
CREATE NONCLUSTERED INDEX [IX_tblTenantAR_DailySnapshot_Tenant_AsOfDate] ON [dbo].[tblTenantAR_DailySnapshot]
(
	[yardiPersonRowID] ASC,
	[AsOfDate] ASC
)
INCLUDE([yardiPropertyRowID],[yardiUnitRowID],[endingBalance]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_tblTenantARSummary_Property_AsOfDate]    Script Date: 2/27/2026 9:28:24 PM ******/
CREATE NONCLUSTERED INDEX [IX_tblTenantARSummary_Property_AsOfDate] ON [dbo].[tblTenantARSummary]
(
	[yardiPropertyRowID] ASC,
	[AsOfDate] ASC
)
INCLUDE([yardiUnitRowID],[yardiPersonRowID],[balanceFwd],[charges],[receipts],[endingBalance]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_Tenants_Person]    Script Date: 2/27/2026 9:28:24 PM ******/
CREATE NONCLUSTERED INDEX [IX_Tenants_Person] ON [dbo].[tblTenants]
(
	[yardiPersonRowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_tblWorkOrderItems]    Script Date: 2/27/2026 9:28:24 PM ******/
CREATE NONCLUSTERED INDEX [IX_tblWorkOrderItems] ON [dbo].[tblWorkOrderItems]
(
	[WONumber] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_tblWorkOrderItems_1]    Script Date: 2/27/2026 9:28:24 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_tblWorkOrderItems_1] ON [dbo].[tblWorkOrderItems]
(
	[YardiWODetailRowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_tblMasterWOReview]    Script Date: 2/27/2026 9:28:24 PM ******/
CREATE NONCLUSTERED INDEX [IX_tblMasterWOReview] ON [dbo].[tblWorkOrders]
(
	[WONumber] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tblADP] ADD  CONSTRAINT [DF_tblImport_ADP_Dollars_Calculated]  DEFAULT ((0)) FOR [Dollars_Calculated]
GO
ALTER TABLE [dbo].[tblADP] ADD  CONSTRAINT [DF_tblImport_ADP_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO
ALTER TABLE [dbo].[tblADP] ADD  CONSTRAINT [DF_tblADP_isLockedForUpdates]  DEFAULT ((0)) FOR [isLockedForUpdates]
GO
ALTER TABLE [dbo].[tblFileStore] ADD  CONSTRAINT [DF_tblFileStore_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[tblImport_Inv_Yardi_POItems] ADD  CONSTRAINT [DF_tblImport_Inv_Yardi_POItems_isSeedItem]  DEFAULT ((0)) FOR [isSeedItem]
GO
ALTER TABLE [dbo].[tblImport_Inv_Yardi_WOItems] ADD  CONSTRAINT [DF_tblImport_Inv_Yardi_WOItems_isSeedItem]  DEFAULT ((0)) FOR [isSeedItem]
GO
ALTER TABLE [dbo].[tblImport_Sortly] ADD  CONSTRAINT [DF_tblImport_Sortly_createDate]  DEFAULT (getdate()) FOR [createDate]
GO
ALTER TABLE [dbo].[tblImport_Yardi_POs] ADD  CONSTRAINT [DF_tblImport_Yardi_POs_IndivPOTotal]  DEFAULT ((0.00)) FOR [IndivPOTotal]
GO
ALTER TABLE [dbo].[tblImport_Yardi_POs] ADD  CONSTRAINT [DF_tblImport_Yardi_POs_POAmount]  DEFAULT ((0.00)) FOR [POAmount]
GO
ALTER TABLE [dbo].[tblImport_Yardi_POs] ADD  CONSTRAINT [DF_tblImport_Yardi_POs_WOAndInvoiceAmt]  DEFAULT ((0.00)) FOR [WOAndInvoiceAmt]
GO
ALTER TABLE [dbo].[tblImport_Yardi_POs] ADD  CONSTRAINT [DF_tblImport_Yardi_POs_createDate]  DEFAULT (getdate()) FOR [createDate]
GO
ALTER TABLE [dbo].[tblImport_Yardi_WOList] ADD  CONSTRAINT [DF_tblImport_Yardi_MaintWOList_createDate]  DEFAULT (getdate()) FOR [createDate]
GO
ALTER TABLE [dbo].[tblImportDates] ADD  CONSTRAINT [DF_tblImportDates_UpdateDate]  DEFAULT (getdate()) FOR [UpdateDate]
GO
ALTER TABLE [dbo].[tblInventoryTracking] ADD  CONSTRAINT [DF_tblInventoryTracking_isSeedItem]  DEFAULT ((0)) FOR [isSeedItem]
GO
ALTER TABLE [dbo].[tblLaborers] ADD  CONSTRAINT [DF_tblLaborers_includeForInventory]  DEFAULT ((1)) FOR [includeForInventory]
GO
ALTER TABLE [dbo].[tblLaborers] ADD  CONSTRAINT [DF_tblLaborers_BonusFactor]  DEFAULT ((0)) FOR [BonusFactor]
GO
ALTER TABLE [dbo].[tblLaborers] ADD  CONSTRAINT [DF_tblLaborers_isSupervisor]  DEFAULT ((0)) FOR [isSupervisor]
GO
ALTER TABLE [dbo].[tblLaborers] ADD  CONSTRAINT [DF_tblLaborers_isCoopSupplier]  DEFAULT ((0)) FOR [isCoopSupplier]
GO
ALTER TABLE [dbo].[tblLegalCases] ADD  DEFAULT ((0)) FOR [isClosed]
GO
ALTER TABLE [dbo].[tblLegalCases_History] ADD  CONSTRAINT [DF_tblLegalCases_History_isClosed]  DEFAULT ((0)) FOR [isClosed]
GO
ALTER TABLE [dbo].[tblPhysicalInventory] ADD  CONSTRAINT [DF_tblSeedInventory_AsOfDate]  DEFAULT (getdate()) FOR [AsOfDate]
GO
ALTER TABLE [dbo].[tblPhysicalInventory] ADD  CONSTRAINT [DF_tblPhysicalInventory_createDate]  DEFAULT (getdate()) FOR [createDate]
GO
ALTER TABLE [dbo].[tblPrintHistory] ADD  CONSTRAINT [DF_tblPrintHistory_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[tblProperties] ADD  CONSTRAINT [DF_tblProperties_modDate]  DEFAULT (getdate()) FOR [modDate]
GO
ALTER TABLE [dbo].[tblProperties] ADD  CONSTRAINT [DF_tblProperties_isInactive]  DEFAULT ((0)) FOR [isInactive]
GO
ALTER TABLE [dbo].[tblProperties] ADD  CONSTRAINT [DF_tblProperties_isInList_Posting]  DEFAULT ((0)) FOR [isInList_Posting]
GO
ALTER TABLE [dbo].[tblProperties] ADD  CONSTRAINT [DF_tblProperties_isInList_Aquinas]  DEFAULT ((0)) FOR [isInList_Aquinas]
GO
ALTER TABLE [dbo].[tblPropertyUnits] ADD  CONSTRAINT [DF_tblPropertyUnits_isExcluded]  DEFAULT ((0)) FOR [isExcluded]
GO
ALTER TABLE [dbo].[tblPurchaseOrders] ADD  CONSTRAINT [DF_tblPurchaseOrders_POAmount]  DEFAULT ((0.00)) FOR [POAmount]
GO
ALTER TABLE [dbo].[tblPurchaseOrders] ADD  CONSTRAINT [DF_tblPurchaseOrders_WOAndInvoiceAmt]  DEFAULT ((0.00)) FOR [WOAndInvoiceAmt]
GO
ALTER TABLE [dbo].[tblTenantARSummary] ADD  DEFAULT (sysutcdatetime()) FOR [ImportCreatedUtc]
GO
ALTER TABLE [dbo].[tblTenants] ADD  DEFAULT (getdate()) FOR [modDate]
GO
ALTER TABLE [dbo].[tblTenants_Snapshots] ADD  CONSTRAINT [DF__tblTenant__IsCur__1B7E091A]  DEFAULT ((1)) FOR [IsCurrent]
GO
ALTER TABLE [dbo].[tblUsers] ADD  CONSTRAINT [DF_tblUsers_isAdmin]  DEFAULT ((0)) FOR [isAdmin]
GO
ALTER TABLE [dbo].[tblUsers] ADD  CONSTRAINT [DF_tblUsers_isSuperAdmin]  DEFAULT ((0)) FOR [isSuperAdmin]
GO
ALTER TABLE [dbo].[tblUsers] ADD  CONSTRAINT [DF_tblUsers_isProjectManager]  DEFAULT ((0)) FOR [isProjectManager]
GO
ALTER TABLE [dbo].[tblUsers] ADD  CONSTRAINT [DF_tblUsers_isLegalTeam]  DEFAULT ((0)) FOR [isLegalTeam]
GO
ALTER TABLE [dbo].[tblUsers] ADD  CONSTRAINT [DF_tblUsers_isDisabled]  DEFAULT ((0)) FOR [isDisabled]
GO
ALTER TABLE [dbo].[tblUsers] ADD  CONSTRAINT [DF_tblUsers_createDate]  DEFAULT (getdate()) FOR [createDate]
GO
ALTER TABLE [dbo].[tblVendors] ADD  CONSTRAINT [DF_tblVendors_isSubcontractor]  DEFAULT ((0)) FOR [isSubcontractor]
GO
ALTER TABLE [dbo].[tblVendors] ADD  CONSTRAINT [DF_tblVendors_createDate]  DEFAULT (getdate()) FOR [createDate]
GO
ALTER TABLE [dbo].[tblWorkOrders] ADD  CONSTRAINT [DF_tblWorkOrders_rowCreateDate]  DEFAULT (getdate()) FOR [rowCreateDate]
GO
/****** Object:  StoredProcedure [dbo].[sp_AttorneyAssignments_LoadFromStg]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- TRUNCATE TABLE tblStg_Attornys;

CREATE   PROCEDURE [dbo].[sp_AttorneyAssignments_LoadFromStg]
  @EffectiveFrom date = NULL,                       -- NULL => 1900-01-01
  @Source        varchar(64) = 'Staging: tblStg_Attornys'
AS
BEGIN
  SET NOCOUNT ON; 
  SET XACT_ABORT ON;

  IF NOT EXISTS (SELECT TOP 1 * FROM dbo.tblStg_Attornys) RETURN

  DECLARE @Eff date = COALESCE(@EffectiveFrom, CONVERT(date,'19000101'));

  /* Normalize staging rows */
  IF OBJECT_ID('tempdb..#Norm') IS NOT NULL DROP TABLE #Norm;
  SELECT
    TenantAccount = LTRIM(RTRIM(TenantID)),
    Code          = COALESCE(NULLIF(LTRIM(RTRIM(AttyCode)) ,''), 'Other'),
    propertyID    = LTRIM(RTRIM(propertyID)),
    UnitName      = LTRIM(RTRIM(UnitName))
  INTO #Norm
  FROM dbo.tblStg_Attornys;

  /* Choose one code per tenant (prefer any non-Other) and gather diagnostics */
  IF OBJECT_ID('tempdb..#Agg') IS NOT NULL DROP TABLE #Agg;
  SELECT
    TenantAccount,
    ChosenCode       = COALESCE(MAX(CASE WHEN Code <> 'Other' THEN Code END), 'Other'),
    DistinctNonOther = COUNT(DISTINCT CASE WHEN Code <> 'Other' THEN Code END),
    AnyProp          = MAX(propertyID),
    AnyUnit          = MAX(UnitName)
  INTO #Agg
  FROM #Norm
  GROUP BY TenantAccount;

  IF OBJECT_ID('tempdb..#Conflicts') IS NOT NULL DROP TABLE #Conflicts;
  SELECT *
  INTO #Conflicts
  FROM #Agg
  WHERE DistinctNonOther > 1; -- FYI only

  /* Resolve Tenant > Person */
  IF OBJECT_ID('tempdb..#Tenants') IS NOT NULL DROP TABLE #Tenants;
  SELECT a.TenantAccount, a.ChosenCode, a.AnyProp, a.AnyUnit, t.yardiPersonRowID
  INTO #Tenants
  FROM #Agg a
  LEFT JOIN dbo.tblTenants t ON t.tenantCode = a.TenantAccount;

  IF OBJECT_ID('tempdb..#MissingTenants') IS NOT NULL DROP TABLE #MissingTenants;
  SELECT TenantAccount, AnyProp AS propertyID, AnyUnit AS UnitName
  INTO #MissingTenants
  FROM #Tenants
  WHERE yardiPersonRowID IS NULL;

  /* Map code > placeholder attorney id */
  IF OBJECT_ID('tempdb..#CodeToAtty') IS NOT NULL DROP TABLE #CodeToAtty;
  SELECT DISTINCT
         Code,
         AttorneyID = a.AttorneyID
  INTO #CodeToAtty
  FROM (SELECT DISTINCT ChosenCode AS Code FROM #Tenants) c
  JOIN dbo.tblAttorneys a ON a.DisplayName = c.Code + ' (placeholder)';

  /* Insert tenant-scope representation (idempotent) */
  INSERT dbo.tblLegalRepresentation
    (AttorneyID, yardiPersonRowID, yardiLegalRowID, yardiUnitRowID, yardiPropertyRowID,
     EffectiveFrom, EffectiveTo, Source, Notes)
  SELECT m.AttorneyID,
         t.yardiPersonRowID,
         NULL, NULL, NULL,
         @Eff, NULL,
         @Source,
         CONCAT('From staging. Tenant=', t.TenantAccount,
                ' Property=', ISNULL(t.AnyProp,''), ' Unit=', ISNULL(t.AnyUnit,''))
  FROM #Tenants t
  JOIN #CodeToAtty m ON m.Code = t.ChosenCode
  LEFT JOIN dbo.tblLegalRepresentation lr
         ON lr.AttorneyID       = m.AttorneyID
        AND lr.yardiPersonRowID = t.yardiPersonRowID
        AND lr.EffectiveFrom    = @Eff
  WHERE t.yardiPersonRowID IS NOT NULL
    AND lr.RepresentationID IS NULL;

  /* Quick diagnostics */
  --SELECT InsertedRows = @@ROWCOUNT;
  --SELECT TOP 100 * FROM #Conflicts ORDER BY TenantAccount;      -- tenants with >1 non-Other code
  --SELECT TOP 100 * FROM #MissingTenants ORDER BY TenantAccount; -- TenantIDs not in dbo.tblTenants
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_AttorneyMaster_SyncFromStg]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[sp_AttorneyMaster_SyncFromStg]
  @EffectiveFrom date = NULL
AS
BEGIN
  SET NOCOUNT ON; SET XACT_ABORT ON;
  DECLARE @Eff date = COALESCE(@EffectiveFrom, CONVERT(date,'19000101'));

  IF OBJECT_ID('dbo.tblStg_Attornys','U') IS NULL
  BEGIN
    RAISERROR('sp_AttorneyMaster_SyncFromStg: missing dbo.tblStg_Attornys.',16,1);
    RETURN;
  END

  MERGE dbo.tblRef_AttorneyCodeMap AS tgt
  USING (VALUES
    ('Other','Other 3rd Parties'),
    ('LKEM','LKEM Law Firm'),
    ('Horing','Horing Law Firm')
  ) AS src(Code,LawFirmName)
  ON tgt.Code = src.Code
  WHEN NOT MATCHED THEN INSERT(Code,LawFirmName) VALUES(src.Code,src.LawFirmName)
  WHEN MATCHED AND tgt.LawFirmName <> src.LawFirmName THEN
    UPDATE SET LawFirmName = src.LawFirmName;

  IF OBJECT_ID('tempdb..#Codes','U') IS NOT NULL DROP TABLE #Codes;
  SELECT DISTINCT Code = COALESCE(NULLIF(LTRIM(RTRIM(AttyCode)) ,''), 'Other')
  INTO #Codes
  FROM dbo.tblStg_Attornys;

  IF OBJECT_ID('tempdb..#CodeFirm','U') IS NOT NULL DROP TABLE #CodeFirm;
  SELECT
    c.Code,
    FirmName             = COALESCE(m.LawFirmName, 'Other 3rd Parties'),
    AttorneyDisplayName  = c.Code + ' (placeholder)'
  INTO #CodeFirm
  FROM #Codes c
  LEFT JOIN dbo.tblRef_AttorneyCodeMap m ON m.Code = c.Code;

  INSERT dbo.tblLawFirms (FirmName)
  SELECT DISTINCT cf.FirmName
  FROM #CodeFirm cf
  LEFT JOIN dbo.tblLawFirms lf ON lf.FirmName = cf.FirmName
  WHERE lf.LawFirmID IS NULL;

  INSERT dbo.tblAttorneys (DisplayName, Active, CreateDate)
  SELECT DISTINCT cf.AttorneyDisplayName, 1, GETDATE()
  FROM #CodeFirm cf
  LEFT JOIN dbo.tblAttorneys a ON a.DisplayName = cf.AttorneyDisplayName
  WHERE a.AttorneyID IS NULL;

  INSERT dbo.tblAttorneysLawFirms (AttorneyID, LawFirmID, EffectiveFrom, Notes)
  SELECT a.AttorneyID, lf.LawFirmID, @Eff, 'Seeded from code map'
  FROM #CodeFirm cf
  JOIN dbo.tblAttorneys a ON a.DisplayName = cf.AttorneyDisplayName
  JOIN dbo.tblLawFirms  lf ON lf.FirmName   = cf.FirmName
  LEFT JOIN dbo.tblAttorneysLawFirms x
         ON x.AttorneyID = a.AttorneyID AND x.LawFirmID = lf.LawFirmID AND x.EffectiveFrom = @Eff
  WHERE x.AttorneysLawFirmsID IS NULL;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_Load_LegalActions_FromStaging]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_Load_LegalActions_FromStaging]
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  BEGIN TRY
    BEGIN TRAN;

    /* Stage -> normalize + trim */
    ;WITH s0 AS (
      SELECT
        s.legalActionRowID,
        s.yardiLegalRowID,
        s.dtBegin,
        s.dtDue,
        ActionTypeDesc = NULLIF(LTRIM(RTRIM(s.ActionTypeDesc)), ''),
        EventDesc      = NULLIF(LTRIM(RTRIM(s.EventDesc)), ''),
        s.sCheck,
        s.fAmount,
        s.sNote,            -- keep note text as-is (target is NVARCHAR(4000))
        s.dAttourneyFee,
        s.dtCreated,
        s.dtLastModified
      FROM dbo.tblStg_LegalCasesActions s
    ),
    /* De-dupe: one “best” row per legalActionRowID */
    S AS (
      SELECT d.*
      FROM (
        SELECT
          s0.*,
          rn = ROW_NUMBER() OVER (
                 PARTITION BY s0.legalActionRowID
                 ORDER BY
                   COALESCE(s0.dtLastModified, s0.dtCreated, s0.dtBegin, s0.dtDue, '19000101') DESC,
                   CASE WHEN s0.EventDesc      IS NOT NULL THEN 0 ELSE 1 END,
                   CASE WHEN s0.ActionTypeDesc IS NOT NULL THEN 0 ELSE 1 END
               )
        FROM s0
      ) d
      WHERE d.rn = 1
    )

    MERGE dbo.tblLegalCasesActions WITH (HOLDLOCK) AS T
    USING S
      ON T.legalActionRowID = S.legalActionRowID

    WHEN MATCHED AND (
           ISNULL(T.yardiLegalRowID,0)           <> ISNULL(S.yardiLegalRowID,0)
        OR ISNULL(T.dtBegin,'1900-01-01')        <> ISNULL(S.dtBegin,'1900-01-01')
        OR ISNULL(T.dtDue,'1900-01-01')          <> ISNULL(S.dtDue,'1900-01-01')
        OR (S.ActionTypeDesc IS NOT NULL AND ISNULL(T.ActionTypeDesc,'') <> S.ActionTypeDesc)
        OR (S.EventDesc      IS NOT NULL AND ISNULL(T.EventDesc,'')      <> S.EventDesc)
        OR ISNULL(T.sCheck,'')                   <> ISNULL(S.sCheck,'')
        OR ISNULL(T.fAmount,0.00)                <> ISNULL(S.fAmount,0.00)
        OR ISNULL(T.sNote,'')                    <> ISNULL(S.sNote,'')
        OR ISNULL(T.dAttourneyFee,0.00)          <> ISNULL(S.dAttourneyFee,0.00)
        OR ISNULL(T.dtCreated,'1900-01-01')      <> ISNULL(S.dtCreated,'1900-01-01')
        OR ISNULL(T.dtLastModified,'1900-01-01') <> ISNULL(S.dtLastModified,'1900-01-01')
    )
      THEN UPDATE SET
        T.yardiLegalRowID  = S.yardiLegalRowID,
        T.dtBegin          = S.dtBegin,
        T.dtDue            = S.dtDue,
        T.ActionTypeDesc   = CASE WHEN S.ActionTypeDesc IS NOT NULL THEN S.ActionTypeDesc ELSE T.ActionTypeDesc END,
        T.EventDesc        = CASE WHEN S.EventDesc      IS NOT NULL THEN S.EventDesc      ELSE T.EventDesc      END,
        T.sCheck           = S.sCheck,
        T.fAmount          = S.fAmount,
        T.sNote            = S.sNote,
        T.dAttourneyFee    = S.dAttourneyFee,
        T.dtCreated        = S.dtCreated,
        T.dtLastModified   = S.dtLastModified

    WHEN NOT MATCHED BY TARGET
      THEN INSERT (
        legalActionRowID, yardiLegalRowID, dtBegin, dtDue,
        ActionTypeDesc, EventDesc,
        sCheck, fAmount, sNote, dAttourneyFee, dtCreated, dtLastModified
      )
      VALUES (
        S.legalActionRowID, S.yardiLegalRowID, S.dtBegin, S.dtDue,
        S.ActionTypeDesc, S.EventDesc,
        S.sCheck, S.fAmount, S.sNote, S.dAttourneyFee, S.dtCreated, S.dtLastModified
      );

    COMMIT;
  END TRY
  BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK;
    THROW;
  END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[sp_Load_LegalCases_FromStaging]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE [dbo].[sp_Load_LegalCases_FromStaging]
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  BEGIN TRY
    BEGIN TRAN;

    /* 1) Normalize / de-dupe staging by key (keep latest modified/created) */
    IF OBJECT_ID('tempdb..#src') IS NOT NULL DROP TABLE #src;
    ;WITH s AS
    (
      SELECT
          sc.yardiLegalRowID
        , sc.yardiPersonRowID
        , sc.legalStatusDesc  AS legalStatus
        , sc.legalFlash       AS legalFlasher
        , sc.legalDisplay
        , CAST(ISNULL(sc.isClosed,0) AS bit) AS isClosed
        , sc.unpaidCharges
        , sc.createdDate
        , sc.modifiedDate
        , rn = ROW_NUMBER() OVER (
                PARTITION BY sc.yardiLegalRowID
                ORDER BY ISNULL(sc.modifiedDate, sc.createdDate) DESC, sc.yardiLegalRowID DESC
              )
      FROM dbo.tblStg_LegalCases sc
    )
    SELECT *
    INTO #src
    FROM s
    WHERE rn = 1;

    CREATE UNIQUE CLUSTERED INDEX CX_src ON #src(yardiLegalRowID);

    /* 2) Change-capture sink for MERGE */
    IF OBJECT_ID('tempdb..#chg') IS NOT NULL DROP TABLE #chg;
    CREATE TABLE #chg
    (
        action           nvarchar(10)  NOT NULL,  -- $action = INSERT/UPDATE
        yardiLegalRowID  int           NOT NULL,
        yardiPersonRowID int           NULL,
        legalStatus      nvarchar(100) NULL,
        legalFlasher     nvarchar(100) NULL,
        legalDisplay     nvarchar(200) NULL,
        isClosed         bit           NOT NULL,
        unpaidCharges    decimal(12,2) NULL,
        createdDate      datetime      NULL,
        modifiedDate     datetime      NULL,
        ChangeDate       datetime2(0)  NOT NULL
    );

    /* 3) MERGE current table (ignore modifiedDate in the trigger condition) */
    MERGE dbo.tblLegalCases AS T
    USING #src AS S
      ON T.yardiLegalRowID = S.yardiLegalRowID
    WHEN MATCHED AND
         (
              ISNULL(T.legalStatus ,'') <> ISNULL(S.legalStatus ,'')
           OR ISNULL(T.legalFlasher,'') <> ISNULL(S.legalFlasher,'')
           OR ISNULL(T.legalDisplay,'') <> ISNULL(S.legalDisplay,'')
           OR ISNULL(T.isClosed,0)       <> ISNULL(S.isClosed,0)
           OR ISNULL(T.unpaidCharges,0)  <> ISNULL(S.unpaidCharges,0)
           OR ISNULL(T.yardiPersonRowID,0) <> ISNULL(S.yardiPersonRowID,0)
           -- NOTE: intentionally NOT comparing modifiedDate here
         )
      THEN UPDATE SET
           T.yardiPersonRowID = S.yardiPersonRowID,
           T.legalStatus      = S.legalStatus,
           T.legalFlasher     = S.legalFlasher,
           T.legalDisplay     = S.legalDisplay,
           T.isClosed         = S.isClosed,
           T.unpaidCharges    = S.unpaidCharges,
           T.createdDate      = S.createdDate,
           T.modifiedDate     = S.modifiedDate
    WHEN NOT MATCHED BY TARGET
      THEN INSERT
      (
          yardiLegalRowID, yardiPersonRowID,
          legalStatus, legalFlasher, legalDisplay,
          isClosed, unpaidCharges, createdDate, modifiedDate
      )
      VALUES
      (
          S.yardiLegalRowID, S.yardiPersonRowID,
          S.legalStatus, S.legalFlasher, S.legalDisplay,
          S.isClosed, S.unpaidCharges, S.createdDate, S.modifiedDate
      )
    OUTPUT
        $action                              AS action,
        inserted.yardiLegalRowID,
        inserted.yardiPersonRowID,
        inserted.legalStatus,
        inserted.legalFlasher,
        inserted.legalDisplay,
        inserted.isClosed,
        inserted.unpaidCharges,
        inserted.createdDate,
        inserted.modifiedDate,
        SYSUTCDATETIME()                     AS ChangeDate
    INTO #chg
    ;
    /* -------- end MERGE -------- */

    /* 4) INSERTS -> open a new history slice */
    INSERT dbo.tblLegalCases_History
    (
        yardiLegalRowID, yardiPersonRowID,
        legalStatus, legalFlasher, legalDisplay, isClosed,
        unpaidCharges, createdDate, modifiedDate,
        validFrom, validTo
    )
    SELECT
        c.yardiLegalRowID, c.yardiPersonRowID,
        c.legalStatus, c.legalFlasher, c.legalDisplay, c.isClosed,
        c.unpaidCharges, c.createdDate, c.modifiedDate,
        c.ChangeDate AS validFrom,
        NULL AS validTo
    FROM #chg c
    WHERE c.action = 'INSERT';

    /* 5) For UPDATEs: only create a new slice when HEADER fields changed */
    IF OBJECT_ID('tempdb..#upd_headers') IS NOT NULL DROP TABLE #upd_headers;
    SELECT c.*
    INTO #upd_headers
    FROM #chg c
    JOIN dbo.tblLegalCases_History h
      ON h.yardiLegalRowID = c.yardiLegalRowID
     AND h.validTo IS NULL
    WHERE c.action = 'UPDATE'
      AND (
            ISNULL(h.legalStatus ,'') <> ISNULL(c.legalStatus ,'')
         OR ISNULL(h.legalFlasher,'') <> ISNULL(c.legalFlasher,'')
         OR ISNULL(h.legalDisplay,'') <> ISNULL(c.legalDisplay,'')
         OR ISNULL(h.isClosed,0)      <> ISNULL(c.isClosed,0)
      );

    /* 5a) End-date the prior open slice for those header changes */
    UPDATE h
    SET h.validTo = DATEADD(day, -1, u.ChangeDate)
    FROM dbo.tblLegalCases_History h
    JOIN #upd_headers u
      ON u.yardiLegalRowID = h.yardiLegalRowID
    WHERE h.validTo IS NULL;

    /* 5b) Start new slice for those header changes */
    INSERT dbo.tblLegalCases_History
    (
        yardiLegalRowID, yardiPersonRowID,
        legalStatus, legalFlasher, legalDisplay, isClosed,
        unpaidCharges, createdDate, modifiedDate,
        validFrom, validTo
    )
    SELECT
        u.yardiLegalRowID, u.yardiPersonRowID,
        u.legalStatus, u.legalFlasher, u.legalDisplay, u.isClosed,
        u.unpaidCharges, u.createdDate, u.modifiedDate,
        u.ChangeDate AS validFrom,
        NULL
    FROM #upd_headers u;

    /* 6) If only unpaidCharges changed (headers same), update the open slice in place */
    UPDATE h
    SET h.unpaidCharges = c.unpaidCharges
    FROM dbo.tblLegalCases_History h
    JOIN #chg c
      ON c.action = 'UPDATE'
     AND c.yardiLegalRowID = h.yardiLegalRowID
    WHERE h.validTo IS NULL
      AND (
            ISNULL(h.legalStatus ,'') = ISNULL(c.legalStatus ,'')
        AND ISNULL(h.legalFlasher,'') = ISNULL(c.legalFlasher,'')
        AND ISNULL(h.legalDisplay,'') = ISNULL(c.legalDisplay,'')
        AND ISNULL(h.isClosed,0)      = ISNULL(c.isClosed,0)
        AND ISNULL(h.unpaidCharges,0) <> ISNULL(c.unpaidCharges,0)
      );

    COMMIT;
  END TRY
  BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK;
    THROW;
  END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[sp_Load_TenantARSummary_FromStaging]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* 2) Idempotent loader from staging */
CREATE   PROCEDURE [dbo].[sp_Load_TenantARSummary_FromStaging]
  @AsOfDate date = NULL
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  IF OBJECT_ID(N'dbo.tblStg_TenantARSummary', N'U') IS NULL
  BEGIN
    RAISERROR('Loader: staging table dbo.tblStg_TenantARSummary is missing.',16,1);
    RETURN;
  END

  IF OBJECT_ID(N'dbo.tblTenantARSummary', N'U') IS NULL
  BEGIN
    RAISERROR('Loader: persistent table dbo.tblTenantARSummary is missing.',16,1);
    RETURN;
  END

  DECLARE @chg TABLE([Action] nvarchar(10) NOT NULL);

  BEGIN TRY
    BEGIN TRAN;

    ;WITH src AS (
      SELECT
        s.AsOfDate,
        s.yardiPersonRowID,
        s.yardiPropertyRowID,
        s.yardiUnitRowID,
        s.balanceFwd,
        s.charges,
        s.receipts,
        s.endingBalance
      FROM dbo.tblStg_TenantARSummary s
      WHERE (@AsOfDate IS NULL OR s.AsOfDate = @AsOfDate)
    )
    MERGE dbo.tblTenantARSummary WITH (HOLDLOCK) AS tgt
    USING src AS src
      ON  tgt.AsOfDate = src.AsOfDate
      AND tgt.yardiPropertyRowID = src.yardiPropertyRowID
      AND tgt.yardiUnitRowID     = src.yardiUnitRowID
      AND tgt.yardiPersonRowID   = src.yardiPersonRowID
    WHEN MATCHED AND (
         (tgt.balanceFwd    <> src.balanceFwd    OR (tgt.balanceFwd IS NULL    AND src.balanceFwd IS NOT NULL)    OR (tgt.balanceFwd IS NOT NULL    AND src.balanceFwd IS NULL))
      OR (tgt.charges       <> src.charges       OR (tgt.charges IS NULL       AND src.charges IS NOT NULL)       OR (tgt.charges IS NOT NULL       AND src.charges IS NULL))
      OR (tgt.receipts      <> src.receipts      OR (tgt.receipts IS NULL      AND src.receipts IS NOT NULL)      OR (tgt.receipts IS NOT NULL      AND src.receipts IS NULL))
      OR (tgt.endingBalance <> src.endingBalance OR (tgt.endingBalance IS NULL AND src.endingBalance IS NOT NULL) OR (tgt.endingBalance IS NOT NULL AND src.endingBalance IS NULL))
    )
      THEN UPDATE SET
        tgt.balanceFwd = src.balanceFwd,
        tgt.charges = src.charges,
        tgt.receipts = src.receipts,
        tgt.endingBalance = src.endingBalance,
        tgt.ImportUpdatedUtc = SYSUTCDATETIME()
    WHEN NOT MATCHED BY TARGET
      THEN INSERT (
        AsOfDate, yardiPersonRowID, yardiPropertyRowID, yardiUnitRowID,
        balanceFwd, charges, receipts, endingBalance,
        ImportCreatedUtc, ImportUpdatedUtc
      )
      VALUES (
        src.AsOfDate, src.yardiPersonRowID, src.yardiPropertyRowID, src.yardiUnitRowID,
        src.balanceFwd, src.charges, src.receipts, src.endingBalance,
        SYSUTCDATETIME(), NULL
      )
    OUTPUT $action INTO @chg([Action]);

    COMMIT;

    DECLARE @Inserted int = (SELECT COUNT(*) FROM @chg WHERE [Action] = 'INSERT');
    DECLARE @Updated  int = (SELECT COUNT(*) FROM @chg WHERE [Action] = 'UPDATE');

    PRINT CONCAT('sp_Load_TenantARSummary_FromStaging complete. Inserted=', @Inserted, ', Updated=', @Updated, '.');
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    THROW;
  END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[sp_Load_Tenants_FromStaging]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[sp_Load_Tenants_FromStaging]
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  BEGIN TRY
    BEGIN TRAN;

    ;WITH S AS (
      SELECT
          s.yardiPersonRowID,
          s.tenantCode,
          s.yardiPropertyRowID,
          s.yardiUnitRowID,
          s.firstName,
          s.lastName,
          s.[status],            -- varchar in staging (keep as-is in core)
          s.moveInDate,
          s.moveOutDate,
          s.email
      FROM dbo.tblStg_Tenants s
    )
    MERGE dbo.tblTenants WITH (HOLDLOCK) AS T
    USING S
      ON T.yardiPersonRowID = S.yardiPersonRowID
    WHEN MATCHED AND (
           ISNULL(T.tenantCode,'')            <> ISNULL(S.tenantCode,'')
        OR ISNULL(T.yardiPropertyRowID,0)     <> ISNULL(S.yardiPropertyRowID,0)
        OR ISNULL(T.yardiUnitRowID,0)         <> ISNULL(S.yardiUnitRowID,0)
        OR ISNULL(T.firstName,'')             <> ISNULL(S.firstName,'')
        OR ISNULL(T.lastName,'')              <> ISNULL(S.lastName,'')
        OR ISNULL(T.[status],'')              <> ISNULL(S.[status],'')
        OR ISNULL(T.moveInDate,'1900-01-01')  <> ISNULL(S.moveInDate,'1900-01-01')
        OR ISNULL(T.moveOutDate,'1900-01-01') <> ISNULL(S.moveOutDate,'1900-01-01')
        OR ISNULL(T.email,'')                 <> ISNULL(S.email,'')
    )
      THEN UPDATE SET
        T.tenantCode         = S.tenantCode,
        T.yardiPropertyRowID = S.yardiPropertyRowID,
        T.yardiUnitRowID     = S.yardiUnitRowID,
        T.firstName          = S.firstName,
        T.lastName           = S.lastName,
        T.[status]           = S.[status],
        T.moveInDate         = S.moveInDate,
        T.moveOutDate        = S.moveOutDate,
        T.email              = S.email,
        T.modDate            = GETDATE()
    WHEN NOT MATCHED BY TARGET
      THEN INSERT (
        yardiPersonRowID, tenantCode, yardiPropertyRowID, yardiUnitRowID,
        firstName, lastName, [status], moveInDate, moveOutDate, email, modDate
      )
      VALUES (
        S.yardiPersonRowID, S.tenantCode, S.yardiPropertyRowID, S.yardiUnitRowID,
        S.firstName, S.lastName, S.[status], S.moveInDate, S.moveOutDate, S.email, GETDATE()
      );

    COMMIT;
  END TRY
  BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK;
    THROW;
  END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[sp_Snapshot_Tenants_SCD_Range]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[sp_Snapshot_Tenants_SCD_Range]
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
/****** Object:  StoredProcedure [dbo].[spADP]    Script Date: 2/27/2026 9:28:24 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spADP_DeletionsBeforeImport]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[spADP_DeletionsBeforeImport]
    @Keys TT_ADPImportKeys READONLY  -- (PayrollName varchar(100), PayDate DATETIME, WONumber VARCHAR(10))
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH 
	
		K AS (
			SELECT DISTINCT
				PayrollName,
				WONumber,
				PayDateOnly = CONVERT(date, PayDate)
			FROM @Keys
		),

		ProtectedTriplets AS (  -- any locked row protects the whole triplet
			SELECT DISTINCT
				k.PayrollName,
				k.WONumber,
				k.PayDateOnly
			FROM K
			JOIN dbo.tblADP a
			  ON  a.PayrollName = k.PayrollName
			  AND a.WONumber  = k.WONumber
			  AND CONVERT(date, a.PayDate) = k.PayDateOnly
			WHERE ISNULL(a.isLockedForUpdates, 0) = 1
		),

		DeletableTriplets AS (
			SELECT k.PayrollName, k.WONumber, k.PayDateOnly
			FROM K
			EXCEPT
			SELECT PayrollName, WONumber, PayDateOnly
			FROM ProtectedTriplets
		)

    DELETE a
    FROM dbo.tblADP a
    JOIN DeletableTriplets d
      ON  a.PayrollName = d.PayrollName
      AND a.WONumber  = d.WONumber
      AND CONVERT(date, a.PayDate) = d.PayDateOnly;
END
GO
/****** Object:  StoredProcedure [dbo].[spADP_MissingFromAnalysisReport]    Script Date: 2/27/2026 9:28:24 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spADPUpdate]    Script Date: 2/27/2026 9:28:24 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spAR_Snapshots_Cleanup]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[spAR_Snapshots_Cleanup]
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
/****** Object:  StoredProcedure [dbo].[spAR_Snapshots_GetLatestAsOfDate]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[spAR_Snapshots_GetLatestAsOfDate]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT MAX(AsOfDate) AS LatestAsOfDate
    FROM dbo.tblTenantAR_DailySnapshot;
END
GO
/****** Object:  StoredProcedure [dbo].[spAR_Snapshots_GetNearestPriorAsOfDate]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[spAR_Snapshots_GetNearestPriorAsOfDate]
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
/****** Object:  StoredProcedure [dbo].[spAR_Snapshots_RunNightly]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[spAR_Snapshots_RunNightly]
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
/****** Object:  StoredProcedure [dbo].[spAR_Snapshots_UpsertFromStaging]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[spAR_Snapshots_UpsertFromStaging]
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
/****** Object:  StoredProcedure [dbo].[spBonusReport]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--  spBonusReport '1/1/2025', '2/1/2025'

CREATE PROCEDURE [dbo].[spBonusReport]
    @Date1 AS DATETIME = NULL,
    @Date2 AS DATETIME = NULL
AS
BEGIN
    IF OBJECT_ID('tempdb..#tmpJobs', 'U') IS NOT NULL DROP TABLE #tmpJobs;

    /* Make alterations & corrections */
    -- update tblWorkOrders set Category='APH-Plumbing' where WONumber in (490659, 489572)

    /* DO SELECTION */
    SELECT 
        xl.WONumber,
        w2.PostedMonth,
        w2.Category,                     -- << ADDED: include Category
        l.FullName_Calc AS LaborerName, 
        CASE 
            WHEN ISNULL(xl.FinalSalePrice,0) - ISNULL(xl.TotalMaterialPricing,0) = 0 THEN 0.00 
            ELSE CAST((Laborer_Bonus / (xl.FinalSalePrice - ISNULL(xl.TotalMaterialPricing,0)) * 100) AS DECIMAL(10,2)) 
        END AS ThePercentage,
        Laborer_Bonus,
        ISNULL(xl.FinalSalePrice,0) AS FinalSalePrice,
        CAST(
            xl.FinalSalePrice *
                (
                    CASE WHEN ISNULL(xl.FinalSalePrice,0) - ISNULL(xl.TotalMaterialPricing,0) = 0 THEN 0.00 
                         ELSE CAST((Laborer_Bonus / (xl.FinalSalePrice - ISNULL(xl.TotalMaterialPricing,0)) * 100) AS DECIMAL(10,2)) 
                    END
                ) / 100
            AS DECIMAL(10,2)
        ) AS CheckCalc, 
        ISNULL(xl.TotalMaterialPricing,0) AS TotalMaterialPricing
    INTO #tmpJobs
    FROM (
            SELECT wo.WONumber, LaborerID, BonusCalc AS Laborer_Bonus, wol.FinalSalePrice, wol.TotalMaterialPricing 
            FROM tblWorkOrders wo 
            INNER JOIN vwWorkOrderLaborers wol ON wo.WONumber = wol.WONumber
         ) AS xl
    LEFT JOIN tblLaborers   l  ON xl.LaborerID = l.LaborerID
    LEFT JOIN tblWorkOrders w2 ON xl.WONumber  = w2.WONumber
    WHERE 
        ISNULL(l.BonusFactor,0) > 0 
        AND xl.WONumber IN 
        (
            SELECT DISTINCT wo.WONumber 
            FROM tblWorkOrders wo
            INNER JOIN vwWorkOrderLaborers wol ON wo.WONumber = wol.WONumber
            WHERE (@Date1 IS NULL 
                   OR (@Date1 IS NOT NULL 
                       AND (PostedMonth >= FORMAT(CAST(@Date1 AS DATETIME), 'yyyy-MM') 
                        AND  PostedMonth <= FORMAT(CAST(@Date2 AS DATETIME), 'yyyy-MM'))))
        )
        AND (
             (ISNULL(l.LaborerID,0) IN (71) AND w2.CompletedDate > '4/14/2025') 
             OR ISNULL(l.LaborerID,0) NOT IN (71)
        ); -- exclude Moya, Luis before 4/14/2025

    /* Bonus Results Table (now includes Category) */
    SELECT * 
    FROM #tmpJobs j
    ORDER BY WONumber, LaborerName;

    /* Totals Table (unchanged shape) */
    SELECT 
        LaborerName, 
        SUM(Laborer_Bonus)        AS LaborerBonus, 
        SUM(FinalSalePrice)       AS SumFinalSalePrice, 
        SUM(TotalMaterialPricing) AS SumTotalMaterialPricing,
        SUM(Laborer_Bonus) * 
        (
            1 - 
            CASE 
                WHEN SUM(FinalSalePrice) = 0 THEN 0
                ELSE SUM(TotalMaterialPricing) / SUM(FinalSalePrice)   -- Guard against DIV/0 errors
            END
        ) AS Invoice_x_Material
    FROM #tmpJobs j
    GROUP BY LaborerName
    ORDER BY LaborerName;

    /* Clean up */
    DROP TABLE #tmpJobs;
END
GO
/****** Object:  StoredProcedure [dbo].[spImport_Delete]    Script Date: 2/27/2026 9:28:24 PM ******/
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
	ELSE IF @FileType = 'YardiWO'		DELETE FROM tblImport_Yardi_WOList
	ELSE IF @FileType = 'YardiPO'		DELETE FROM tblImport_Yardi_POs
	ELSE IF @FileType in ('YardiWO2','InventoryWO')	DELETE FROM tblImport_Inv_Yardi_WOItems
	ELSE IF @FileType in ('YardiPO2','InventoryPO')	DELETE FROM tblImport_Inv_Yardi_POItems
	
	ELSE IF @FileType in ('Tenants')	DELETE FROM tblStg_Tenants
	ELSE IF @FileType in ('LegalCasesActions')	DELETE FROM tblStg_LegalCasesActions
	ELSE IF @FileType in ('LegalCaseHeaders')	DELETE FROM tblStg_LegalCases
	ELSE IF @FileType in ('TenantARSummary')	DELETE FROM tblStg_TenantARSummary

END
GO
/****** Object:  StoredProcedure [dbo].[spImportDates]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE procedure [dbo].[spImportDates]
	@DateKey varchar(25) = NULL,
	@ExportFileNum int = NULL
AS

SELECT * FROM
	(select * from tblImportDates

	UNION

	select 
		'ADP' as DateKey, 
		0 as ExportFileNum,
		min(PayDate) as LatestImportDateRage_Date1,
		max(PayDate) as LatestImportDateRage_Date2,
		max(CreateDate) as UpdateDate
	FROM tblADP) as importDates
WHERE 
	(@DateKey is null or (@DateKey is not null and DateKey = @DateKey))
	AND (@ExportFileNum is null or (@ExportFileNum is not null and ExportFileNum = @ExportFileNum))

GO
/****** Object:  StoredProcedure [dbo].[spImportDatesUpdate]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE procedure [dbo].[spImportDatesUpdate]
	@DateKey varchar(25),
	@LatestImportDateRange_Date1 DateTime = null,
	@LatestImportDateRange_Date2 DateTime,
	@ExportFileNum int = NULL
AS

IF (SELECT COUNT(*) FROM tblImportDates WHERE DateKey = @DateKey) = 1 
	BEGIN
		UPDATE tblImportDates Set
			DateKey = @DateKey,
			LatestImportDateRange_Date1 = @LatestImportDateRange_Date1,
			LatestImportDateRange_Date2 = @LatestImportDateRange_Date2,
			UpdateDate = getdate()
		WHERE 
			(@DateKey is null or (@DateKey is not null and DateKey = @DateKey))
			and LatestImportDateRange_Date2 < @LatestImportDateRange_Date2
			and (@ExportFileNum is null or (@ExportFileNum is not null and ExportFileNum = @ExportFileNum))
	END
ELSE
	BEGIN
		INSERT INTO tblImportDates(DateKey, LatestImportDateRange_Date1, LatestImportDateRange_Date2, UpdateDate)
		VALUES(@DateKey, @LatestImportDateRange_Date1, @LatestImportDateRange_Date2, getdate())
	END

SELECT * FROM tblImportDates WHERE DateKey = @DateKey
GO
/****** Object:  StoredProcedure [dbo].[spPagesTranslations_ExportJson]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[spPagesTranslations_ExportJson]
    @BatchSize INT,
    @Offset INT,
    @TargetLanguageCode NVARCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @BatchSize IS NULL OR @BatchSize <= 0
    BEGIN
        RAISERROR('BatchSize must be greater than zero.', 16, 1);
        RETURN;
    END;

    IF @Offset IS NULL OR @Offset < 0
    BEGIN
        RAISERROR('Offset must be zero or greater.', 16, 1);
        RETURN;
    END;

    SELECT
        SourceLanguage = N'en',
        TargetLanguage = ISNULL(NULLIF(LTRIM(RTRIM(@TargetLanguageCode)), N''), N''),
        BatchSize = @BatchSize,
        [Offset] = @Offset,
        ExportedAt = SYSUTCDATETIME(),
        [rows] = JSON_QUERY((
            SELECT
                p.PageID,
                p.CanonicalSlug,
                p.AreaKey,
                p.PageType,
                en.UrlSlug,
                en.Title,
                en.ContentHtml,
                en.Summary,
                en.SeoMeta
            FROM dbo.Pages p
            LEFT JOIN dbo.PagesTranslations en
                ON en.PageID = p.PageID
               AND en.LanguageCode = N'en'
            ORDER BY p.PageID
            OFFSET @Offset ROWS FETCH NEXT @BatchSize ROWS ONLY
            FOR JSON PATH
        ))
    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER;
END
GO
/****** Object:  StoredProcedure [dbo].[spPhysicalInventoryUpdate]    Script Date: 2/27/2026 9:28:24 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spPOInventoryItemReport]    Script Date: 2/27/2026 9:28:24 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spPropertyUnitUpdate]    Script Date: 2/27/2026 9:28:24 PM ******/
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
	@unitTypeDesc varchar(20) = NULL,
	@LeaseStartDate DateTime = NULL,
	@LeaseEndDate DateTime = NULL,
	@CurrentTenantYardiID int = NULL
AS
BEGIN
	IF (@yardiPropertyRowID is null or @yardiUnitRowID is null) return -1  -- these are required

	IF NOT EXISTS (SELECT 1 FROM tblPropertyUnits WHERE yardiUnitRowID = @yardiUnitRowID)
		BEGIN
			INSERT INTO tblPropertyUnits
			(yardiPropertyRowID, yardiUnitRowID, AptNumber, Bedrooms, rent, SqFt, UnitStatus, LastMoveInDate, LastMoveOutDate, 
				modDate, createDate, isExcluded, LastTenantRent, unitTypeDesc, LeaseStartDate, LeaseEndDate, CurrentTenantYardiID )
			VALUES(@yardiPropertyRowID, @yardiUnitRowID, @AptNumber, @Bedrooms, @rent, @SqFt, @UnitStatus, @LastMoveInDate, @LastMoveOutDate, 
				getdate(), getdate(), @isExcluded, @LastTenantRent, @unitTypeDesc, @LeaseStartDate, @LeaseEndDate, @CurrentTenantYardiID)
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
				unitTypeDesc = @unitTypeDesc,
				LeaseStartDate = @LeaseStartDate,
				LeaseEndDate = @LeaseEndDate,
				CurrentTenantYardiID = @CurrentTenantYardiID
		
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
					or isnull(LeaseStartDate,'1/1/1900') <> isnull(@LeaseStartDate,'1/1/1900')
					or isnull(LeaseEndDate,'1/1/1900') <> isnull(@LeaseEndDate,'1/1/1900')
					or isnull(CurrentTenantYardiID,0) <> isnull(@CurrentTenantYardiID, 0)
				)

		END

END
GO
/****** Object:  StoredProcedure [dbo].[spPropertyUpdate]    Script Date: 2/27/2026 9:28:24 PM ******/
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
	@inactiveDate datetime = NULL,
	@isInList_Posting bit = 0,
	@isInList_Aquinas bit = 0
AS
BEGIN

	IF @buildingCode is null return -1
	if @yardiPropertyRowID is null return -1

	IF @yardiPropertyRowID not in (SELECT yardiPropertyRowID FROM tblProperties)
		BEGIN
			INSERT INTO tblProperties
			( yardiPropertyRowID, buildingCode, addr1_Co, addr2, addr3, addr4, city, stateCode, zipCode, isInactive, inactiveDate, isInList_Posting, isInList_Aquinas )
			VALUES( @yardiPropertyRowID, @buildingCode, @addr1_Co, @addr2, @addr3, @addr4, @city, @stateCode, @zipCode, @isInactive, @inactiveDate, @isInList_Posting,  @isInList_Aquinas)

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
				inactiveDate = @inactiveDate,
				isInList_Posting = @isInList_Posting,
				isInList_Aquinas = @isInList_Aquinas
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
					or isInList_Posting <> @isInList_Posting
					or isInList_Aquinas <> @isInList_Aquinas
				)
		END

END
GO
/****** Object:  StoredProcedure [dbo].[spPurchaseOrders_Import]    Script Date: 2/27/2026 9:28:24 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spQA_ArrearsTracker_DateResolution]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[spQA_ArrearsTracker_DateResolution]
    @RequestedAsOfDate date = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @RequestedAsOfDate IS NULL
        SET @RequestedAsOfDate = CONVERT(date, GETDATE());

    DECLARE @LatestDaily date =
    (
        SELECT MAX(AsOfDate)
        FROM dbo.tblTenantAR_DailySnapshot
    );

    IF @LatestDaily IS NULL
    BEGIN
        SELECT
            @RequestedAsOfDate AS RequestedAsOfDate,
            CAST(NULL AS date) AS LatestDaily,
            CAST(NULL AS date) AS Cutoff90,
            CAST(NULL AS varchar(50)) AS ResolutionMode,
            CAST(NULL AS date) AS RequestedMonthEnd,
            CAST(NULL AS date) AS ARAsOf_Resolved,
            0 AS ARRows_ResolvedDate,
            CAST(NULL AS date) AS TenantSnapAsOf_Resolved,
            0 AS TenantSnapRows_ResolvedDate,
            CAST(0 AS bit) AS Pass,
            'No rows exist in tblTenantAR_DailySnapshot (LatestDaily is NULL).' AS FailReason;
        RETURN;
    END

    DECLARE @Cutoff90 date = DATEADD(day, -90, @LatestDaily);

    DECLARE @ResolutionMode varchar(50);
    DECLARE @RequestedMonthEnd date = EOMONTH(@RequestedAsOfDate);

    DECLARE @ARAsOf_Resolved date;
    DECLARE @TenantSnapAsOf_Resolved date;

    -- Resolution logic:
    -- <= 90 days => DAILY mode (resolve to nearest AR <= Requested)
    -- > 90 days  => MONTH-END mode (resolve to nearest AR <= RequestedMonthEnd)
    IF @RequestedAsOfDate >= @Cutoff90
    BEGIN
        SET @ResolutionMode = 'DAILY (<=90)';

        SELECT @ARAsOf_Resolved = MAX(AsOfDate)
        FROM dbo.tblTenantAR_DailySnapshot
        WHERE AsOfDate <= @RequestedAsOfDate;

        SELECT @TenantSnapAsOf_Resolved = MAX(ValidFrom)
        FROM dbo.tblTenants_Snapshots
        WHERE ValidFrom <= @RequestedAsOfDate;
    END
    ELSE
    BEGIN
        SET @ResolutionMode = 'MONTH-END (>90)';

        SELECT @ARAsOf_Resolved = MAX(AsOfDate)
        FROM dbo.tblTenantAR_DailySnapshot
        WHERE AsOfDate <= @RequestedMonthEnd;

        SELECT @TenantSnapAsOf_Resolved = MAX(ValidFrom)
        FROM dbo.tblTenants_Snapshots
        WHERE ValidFrom <= @RequestedMonthEnd;
    END

    DECLARE @ARRows int = 0;
    DECLARE @TenantRows int = 0;

    IF @ARAsOf_Resolved IS NOT NULL
    BEGIN
        SELECT @ARRows = COUNT(*)
        FROM dbo.tblTenantAR_DailySnapshot
        WHERE AsOfDate = @ARAsOf_Resolved;
    END

    IF @TenantSnapAsOf_Resolved IS NOT NULL
    BEGIN
        SELECT @TenantRows = COUNT(*)
        FROM dbo.tblTenants_Snapshots
        WHERE ValidFrom = @TenantSnapAsOf_Resolved;
    END

    DECLARE @Pass bit = 1;
    DECLARE @FailReason varchar(4000) = NULL;

    IF @ARAsOf_Resolved IS NULL
    BEGIN
        SET @Pass = 0;
        SET @FailReason = 'No AR snapshot exists on or before the resolved date.';
    END
    ELSE IF @TenantSnapAsOf_Resolved IS NULL
    BEGIN
        SET @Pass = 0;
        SET @FailReason = 'No Tenant snapshot exists on or before the resolved date.';
    END
    ELSE IF @ARRows = 0
    BEGIN
        SET @Pass = 0;
        SET @FailReason = 'Resolved ARAsOf_Resolved has 0 rows.';
    END
    ELSE IF @TenantRows = 0
    BEGIN
        SET @Pass = 0;
        SET @FailReason = 'Resolved TenantSnapAsOf_Resolved has 0 rows.';
    END

    -- Extra strict checks for MONTH-END mode (this is what catches “out of whack” history)
    IF @Pass = 1 AND @ResolutionMode LIKE 'MONTH-END%'
    BEGIN
        IF @ARAsOf_Resolved <> @RequestedMonthEnd
        BEGIN
            SET @Pass = 0;
            SET @FailReason = CONCAT('MONTH-END mode: ARAsOf_Resolved (', CONVERT(varchar(10), @ARAsOf_Resolved, 120),
                                     ') is not the requested month-end (', CONVERT(varchar(10), @RequestedMonthEnd, 120), ').');
        END
        ELSE IF EOMONTH(@ARAsOf_Resolved) <> @ARAsOf_Resolved
        BEGIN
            SET @Pass = 0;
            SET @FailReason = CONCAT('MONTH-END mode: ARAsOf_Resolved (', CONVERT(varchar(10), @ARAsOf_Resolved, 120),
                                     ') is not a true month-end.');
        END
        ELSE IF @TenantSnapAsOf_Resolved <> @RequestedMonthEnd
        BEGIN
            SET @Pass = 0;
            SET @FailReason = CONCAT('MONTH-END mode: TenantSnapAsOf_Resolved (', CONVERT(varchar(10), @TenantSnapAsOf_Resolved, 120),
                                     ') is not the requested month-end (', CONVERT(varchar(10), @RequestedMonthEnd, 120), ').');
        END
    END

    SELECT
        @RequestedAsOfDate        AS RequestedAsOfDate,
        @LatestDaily              AS LatestDaily,
        @Cutoff90                 AS Cutoff90,
        @ResolutionMode           AS ResolutionMode,
        @RequestedMonthEnd        AS RequestedMonthEnd,
        @ARAsOf_Resolved          AS ARAsOf_Resolved,
        @ARRows                   AS ARRows_ResolvedDate,
        @TenantSnapAsOf_Resolved  AS TenantSnapAsOf_Resolved,
        @TenantRows               AS TenantSnapRows_ResolvedDate,
        @Pass                     AS Pass,
        @FailReason               AS FailReason;
END
GO
/****** Object:  StoredProcedure [dbo].[spReceivableSummaryByTenant_Range]    Script Date: 2/27/2026 9:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[spReceivableSummaryByTenant_Range]
  @DateFrom     date,
  @DateTo       date,
  @BuildingCode varchar(20) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @StartME date = EOMONTH(@DateFrom);
  DECLARE @EndME   date = EOMONTH(@DateTo);

  IF OBJECT_ID('dbo.tblTenantARSummary','U') IS NULL
  BEGIN
    RAISERROR('Receivable summary: persistent AR table dbo.tblTenantARSummary is missing.',16,1);
    RETURN;
  END

  IF NOT EXISTS (SELECT 1 FROM dbo.tblTenantARSummary WHERE AsOfDate = @StartME)
     OR NOT EXISTS (SELECT 1 FROM dbo.tblTenantARSummary WHERE AsOfDate = @EndME)
  BEGIN
    RAISERROR('Requested month-end(s) not loaded. Load persistent tblTenantARSummary for the date range first (run sp_Load_TenantARSummary_FromStaging).',16,1);
    RETURN;
  END

  SELECT *
  FROM dbo.fnReceivableSummaryByTenant_Range(@StartME, @EndME) r
  WHERE (@BuildingCode IS NULL OR r.Property = @BuildingCode)
  ORDER BY r.Property, r.Unit, r.Tenant;
END
GO
/****** Object:  StoredProcedure [dbo].[spReport_ArrearsTracker]    Script Date: 2/27/2026 9:28:24 PM ******/
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

CREATE   PROCEDURE [dbo].[spReport_ArrearsTracker]
    @AsOfDate                    date,
    @BuildingCode                varchar(20) = NULL,
    @FilterOnlyExcel             bit = 1,
    @FilterIsList_Posting        bit = 0,
    @FilterIsList_Aquinas        bit = 0
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
      AND (@FilterOnlyExcel = 0 OR s.endingBalance > 0)
    ORDER BY p.buildingCode, u.AptNumber;

END;

GO
/****** Object:  StoredProcedure [dbo].[spReport_ArrearsTracker_Daily]    Script Date: 2/27/2026 9:28:25 PM ******/
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

CREATE   PROCEDURE [dbo].[spReport_ArrearsTracker_Daily]
    @AsOfDate                    date,
    @BuildingCode                varchar(20) = NULL,
    @FilterOnlyExcel             bit = 1,
    @FilterIsList_Posting        bit = 0,
    @FilterIsList_Aquinas        bit = 0
AS
BEGIN
    SET NOCOUNT ON;

	--SET @FilterOnlyExcel=1;

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
        u.LeaseEndDate AS [Lease End Date]

        -- DEBUG COLUMNS
		-- Extra columns not in the Excel template (kept at the end)
        ,u.CurrentTenantYardiID
        ,@RequestedAsOfDate AS RequestedAsOfDate
        ,@ResolvedAsOfDate AS ResolvedSnapshotAsOfDate
        ,CASE WHEN @ResolvedAsOfDate = @RequestedAsOfDate THEN CAST(0 AS bit) ELSE CAST(1 AS bit) END AS IsResolvedFromPriorSnapshot
        ,'DAILY' AS ModeUsed 
FROM dbo.tblTenantAR_DailySnapshot s
        INNER JOIN dbo.tblProperties p ON p.yardiPropertyRowID = s.yardiPropertyRowID
        LEFT JOIN dbo.tblPropertyUnits u ON u.yardiUnitRowID = s.yardiUnitRowID
        LEFT JOIN dbo.tblTenants t ON t.yardiPersonRowID = s.yardiPersonRowID
        LEFT JOIN dbo.tblTenants_Snapshots ts ON ts.yardiPersonRowID = s.yardiPersonRowID AND CAST(ts.ValidFrom AS date) = @TenantSnapAsOf_Resolved

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
      AND (@FilterOnlyExcel = 0 OR s.endingBalance > 0)
    ORDER BY p.buildingCode, u.AptNumber;

END;

GO
/****** Object:  StoredProcedure [dbo].[spRptBuilder_AR_DailySnapshot_Build]    Script Date: 2/27/2026 9:28:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[spRptBuilder_AR_DailySnapshot_Build]
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
/****** Object:  StoredProcedure [dbo].[spRptBuilder_Inventory_01_Import]    Script Date: 2/27/2026 9:28:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



/* ====================================== 
   spRptBuilder_Inventory_01_Import

   CHANGES:
     • Preserve ReceivedDate as imported from Yardi
       (may remain NULL if not provided).
     • Use ISNULL(ReceivedDate, OrderDate) for DateOfSale
       so reporting has a usable date even when ReceivedDate is NULL.
     • PO UPDATE logic compares:
         - it.ReceivedDate  vs imp.ReceivedDate
         - it.DateOfSale    vs ISNULL(imp.ReceivedDate, imp.OrderDate)
     • PO HEADERS now UPSERT into tblPurchaseOrders:
         - Aggregate from tblImport_Inv_Yardi_POItems (POAgg CTE)
         - UPDATE existing rows when any header fields change
         - INSERT new rows for PONumbers not present yet
 ====================================== */

CREATE PROCEDURE [dbo].[spRptBuilder_Inventory_01_Import]
AS
BEGIN
    SET NOCOUNT ON;

    /* Update Sortly inventory table */
    EXEC spSortlyFillInventoryTable;


    /* ======================================
       PO ITEMS > INSERT
       ====================================== */

    INSERT INTO tblInventoryTracking 
        ([Source], [ItemCode], [ItemDesc], WONumber, PONumber, Quantity, UnitPrice, Total, 
         ReceivedDate, Category, ExpenseType, Vendor, Client, DateOfSale)

    SELECT 
        'PO' AS [Source], 
        po.ItemCode, 
        LEFT(po.ItemDesc, 75) AS ItemDesc, 
        po.WONumber, 
        po.PONumber, 
        po.QtyOrdered AS Quantity, 
        po.UnitPrice, 
        po.TotalCost AS Total,

        -- Preserve raw ReceivedDate from Yardi (may be NULL)
        po.ReceivedDate AS ReceivedDate,

        wo.Category, 
        po.ExpenseType,
        po.Vendor,
        po.Client,

        -- DateOfSale: fallback to OrderDate when ReceivedDate is NULL
        ISNULL(po.ReceivedDate, po.OrderDate) AS DateOfSale

    FROM tblImport_Inv_Yardi_POItems po
        LEFT JOIN (
            SELECT WONumber, MIN(Category) AS Category 
            FROM tblImport_Inv_Yardi_WOItems
            GROUP BY WONumber
        ) wo ON po.WONumber = wo.WONumber
        LEFT JOIN tblInventoryTracking t ON 
               po.ItemCode = t.ItemCode 
           AND ISNULL(po.PONumber,-1) = ISNULL(t.PONumber,-1)
           AND ISNULL(po.WONumber,-1) = ISNULL(t.WONumber,-1)
           AND t.Source = 'PO'
    WHERE 
        po.ItemCode IS NOT NULL 
        AND po.ItemCode LIKE ('__-%')
        AND t.ItemCode IS NULL;



    /* ======================================
       PO ITEMS > UPDATE
       ====================================== */

    UPDATE it
        SET 
            Quantity     = imp.QtyOrdered,
            Total        = imp.TotalCost,

            -- Preserve raw ReceivedDate (may be NULL)
            ReceivedDate = imp.ReceivedDate,

            -- DateOfSale with fallback to OrderDate
            DateOfSale   = ISNULL(imp.ReceivedDate, imp.OrderDate),

            ExpenseType  = imp.ExpenseType,
            Vendor       = imp.Vendor,
            Client       = imp.Client
    FROM tblInventoryTracking it
    INNER JOIN tblImport_Inv_Yardi_POItems imp 
            ON it.PONumber = imp.PONumber 
           AND it.ItemCode = imp.ItemCode
    WHERE 
        it.Source = 'PO'
        AND (
               it.Quantity <> imp.QtyOrdered
            OR it.Total    <> imp.TotalCost

            -- Compare to raw ReceivedDate only
            OR ISNULL(it.ReceivedDate,'1900-01-01')
                  <> ISNULL(imp.ReceivedDate,'1900-01-01')

            -- Compare DateOfSale to fallback(ReceivedDate, OrderDate)
            OR ISNULL(it.DateOfSale,'1900-01-01')
                  <> ISNULL(ISNULL(imp.ReceivedDate,imp.OrderDate),'1900-01-01')

            OR ISNULL(it.ExpenseType,'') <> ISNULL(imp.ExpenseType,'')
            OR ISNULL(it.Vendor,'')      <> ISNULL(imp.Vendor,'')
            OR ISNULL(it.Client,'')      <> ISNULL(imp.Client,'')
        );


    /* ======================================
       UPSERT tblPurchaseOrders (PO HEADERS)
       ====================================== */

    IF OBJECT_ID('tempdb..#POAgg') IS NOT NULL
        DROP TABLE #POAgg;

    SELECT 
        i.PONumber, 
        i.WONumber,
        Vendors      = v.Vendors,
        MinOrderDate = MIN(i.OrderDate),

        -- For PO header: use earliest of (ReceivedDate, OrderDate)
        MinRecvDate  = MIN(ISNULL(i.ReceivedDate, i.OrderDate)),

        i.ExpenseType,
        TotalCostsOfItems = SUM(i.TotalCost)
    INTO #POAgg
    FROM tblImport_Inv_Yardi_POItems i
    INNER JOIN (
        SELECT 
            PONumber, 
            STRING_AGG(Vendor, ' / ') AS Vendors 
        FROM (
            SELECT DISTINCT PONumber, Vendor 
            FROM tblImport_Inv_Yardi_POItems
        ) a 
        GROUP BY PONumber
    ) v ON i.PONumber = v.PONumber
    GROUP BY 
        i.PONumber, i.WONumber, v.Vendors, i.ExpenseType;


    -- 1) UPDATE existing PO headers when anything has changed
    UPDATE po
        SET 
            po.WONumber         = a.WONumber,
            po.VendorName       = a.Vendors,
            po.OrderDate        = a.MinOrderDate,
            po.ReceivedDate     = a.MinRecvDate,
            po.ExpenseType      = a.ExpenseType,
            po.TotalCostOfItems = a.TotalCostsOfItems
    FROM tblPurchaseOrders po
    INNER JOIN #POAgg a
            ON po.PONumber = a.PONumber
    WHERE 
           ISNULL(po.WONumber,       -1)           <> ISNULL(a.WONumber,       -1)
        OR ISNULL(po.VendorName,     '')           <> ISNULL(a.Vendors,        '')
        OR ISNULL(po.OrderDate,      '19000101')   <> ISNULL(a.MinOrderDate,   '19000101')
        OR ISNULL(po.ReceivedDate,   '19000101')   <> ISNULL(a.MinRecvDate,    '19000101')
        OR ISNULL(po.ExpenseType,    '')           <> ISNULL(a.ExpenseType,    '')
        OR ISNULL(po.TotalCostOfItems, 0.00)       <> ISNULL(a.TotalCostsOfItems, 0.00);


    -- 2) INSERT new PO headers that don’t exist yet
    INSERT INTO tblPurchaseOrders
        (PONumber, WONumber, VendorName, OrderDate, ReceivedDate, ExpenseType, TotalCostOfItems)
    SELECT 
        a.PONumber,
        a.WONumber,
        a.Vendors,
        a.MinOrderDate,
        a.MinRecvDate,
        a.ExpenseType,
        a.TotalCostsOfItems
    FROM #POAgg a
    WHERE NOT EXISTS 
    (
        SELECT 1 
        FROM tblPurchaseOrders po 
        WHERE po.PONumber = a.PONumber
    );


    /* ======================================
       WO ITEMS
       ====================================== */

    INSERT INTO tblInventoryTracking 
        ([Source], [ItemCode], [ItemDesc], WONumber, Quantity, Category, Vendor, Client, DateOfSale)

    SELECT 
        'WO', 
        i.ItemCode, 
        LEFT(i.ItemDesc,75), 
        i.WONumber,
        (ISNULL(i.Qty,0) * -1),
        i.Category,
        i.Vendor,
        i.Client,
        i.CompleteDate
    FROM tblImport_Inv_Yardi_WOItems i
    LEFT JOIN tblInventoryTracking t ON 
           i.ItemCode = t.ItemCode
       AND ISNULL(i.WONumber,-1) = ISNULL(t.WONumber,-1)
       AND ISNULL(i.Vendor,'')  = ISNULL(t.Vendor,'')
       AND t.Source='WO'
    WHERE 
        i.ItemCode IS NOT NULL
        AND i.ItemCode LIKE ('__-%')
        AND t.ItemCode IS NULL
        AND LEFT(i.ItemCode,3) <> '01-';



    UPDATE it
        SET 
            Quantity   = ISNULL(i.Qty,0) * -1,
            Category   = i.Category,
            Client     = i.Client,
            DateOfSale = i.CompleteDate
    FROM tblInventoryTracking it
    INNER JOIN tblImport_Inv_Yardi_WOItems i 
            ON it.WONumber = i.WONumber 
           AND it.ItemCode = i.ItemCode
    WHERE 
        it.Source = 'WO'
        AND (
               it.Quantity <> ISNULL(i.Qty,0) * -1
            OR it.Category <> i.Category
            OR it.Client   <> i.Client
            OR ISNULL(it.DateOfSale,'1900-01-01') 
                    <> ISNULL(i.CompleteDate,'1900-01-01')
        );



    /* ======================================
       SORTLY
       ====================================== */

    INSERT INTO tblInventoryTracking 
        ([Source], [ItemCode], [ItemDesc], WONumber, Quantity, DateOfSale, ReceivedDate)
    SELECT 
        'Sortly',
        i.Notes AS ItemCode,
        LEFT(i.ItemName,75),
        i.WONumber_Calc,
        (ISNULL(i.Quantity,0) * -1),
        CASE 
            WHEN ISNULL(w.DateOfSale,'1900-01-01') <> ISNULL(i.WODate,'1900-01-01')
                 AND w.DateOfSale IS NOT NULL 
            THEN w.DateOfSale
            ELSE i.WODate
        END,
        i.WODate
    FROM tblImport_Sortly i
    LEFT JOIN tblWorkOrders w ON i.WONumber_Calc = w.WONumber
    WHERE 
        i.Notes IS NOT NULL
        AND i.Notes LIKE ('__-%')
        AND i.PrimaryFolder LIKE '%Today%Work Orders%'
        AND NOT EXISTS (
            SELECT 1 FROM tblInventoryTracking t
            WHERE t.ItemCode = i.Notes 
              AND ISNULL(t.WONumber,-1) = ISNULL(i.WONumber_Calc,-1)
              AND t.Source = 'Sortly'
        );



    UPDATE t
        SET 
            Quantity    = (ISNULL(i.Quantity,0) * -1),
            DateOfSale  = CASE 
                            WHEN ISNULL(w.DateOfSale,'1900-01-01') <> ISNULL(i.WODate,'1900-01-01')
                                 AND w.DateOfSale IS NOT NULL 
                            THEN w.DateOfSale 
                            ELSE i.WODate 
                          END,
            ReceivedDate = i.WODate
    FROM tblImport_Sortly i
    LEFT JOIN tblWorkOrders w ON i.WONumber_Calc = w.WONumber
    LEFT JOIN tblInventoryTracking t 
           ON t.ItemCode = i.Notes
          AND ISNULL(t.WONumber,-1) = ISNULL(i.WONumber_Calc,-1)
          AND t.Source='Sortly'
    WHERE 
        i.Notes IS NOT NULL
        AND i.Notes LIKE ('__-%')
        AND i.PrimaryFolder LIKE '%Today%Work Orders%'
        AND (
               t.Quantity <> (ISNULL(i.Quantity,0) * -1)
            OR ISNULL(t.DateOfSale,'1900-01-01') 
                    <> CASE 
                           WHEN ISNULL(w.DateOfSale,'1900-01-01') <> ISNULL(i.WODate,'1900-01-01')
                                AND w.DateOfSale IS NOT NULL 
                           THEN w.DateOfSale 
                           ELSE i.WODate 
                       END
            OR ISNULL(t.ReceivedDate,'1900-01-01') <> ISNULL(i.WODate,'1900-01-01')
        );



    /* ======================================
       FINAL CLEANUP
       ====================================== */

    DELETE it
    FROM tblInventoryTracking it
    INNER JOIN tblInvalidPOItems xx
        ON it.PONumber = xx.PONumber
       AND it.ItemCode = xx.ItemCode
       AND it.Quantity = xx.Quantity;

END
GO
/****** Object:  StoredProcedure [dbo].[spRptBuilder_Inventory_FullInventory]    Script Date: 2/27/2026 9:28:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Keep this comment: [spRptBuilder_Inventory_FullInventory] @EndDate='5/1/2025'
CREATE PROCEDURE [dbo].[spRptBuilder_Inventory_FullInventory]
    @EndDate AS datetime = NULL
AS
BEGIN
SET NOCOUNT ON;

DECLARE @ignoreCategory varchar(100) = 'CABINETS'
DECLARE @AsOfDate datetime = ISNULL(@EndDate, GETDATE())

-- Version: v2025.05.31-C
-- Purpose: Full Inventory Report
-- - Includes items with movement but no physical seed
-- - Uses per-ItemCode seed from tblPhysicalInventory
-- - Filters movement after seed date
-- - Adds LastPhysicalCount_Date column

-- STEP 1: Build Seed Table

IF OBJECT_ID('tempdb..#tmpSeed') IS NOT NULL DROP TABLE #tmpSeed
SELECT
    Code AS ItemCode,
    MAX(AsOfDate) AS SeedDate,
    CAST(NULL AS decimal(18,2)) AS Quantity
INTO #tmpSeed
FROM tblPhysicalInventory
WHERE AsOfDate <= @AsOfDate
    AND ISNULL(Code, '') > ''
    AND PhysicalCount IS NOT NULL
GROUP BY Code

UPDATE s
SET s.Quantity = p.PhysicalCount
FROM #tmpSeed s
JOIN tblPhysicalInventory p ON p.Code = s.ItemCode AND p.AsOfDate = s.SeedDate

-- STEP 2: ADP WOs not yet picked up in Yardi

SELECT WONumber, MIN(PayDate) AS ReceivedDate
INTO #tblADP_AddlWOs
FROM tblADP 
WHERE WONumber NOT IN (0)
    AND PayDate IS NOT NULL
    AND LaborerID IN (SELECT LaborerID FROM tblLaborers WHERE isCoopSupplier = 1)
    AND PayDate >= DATEADD(MONTH, -6, @AsOfDate) AND PayDate < @AsOfDate
    AND ISNULL(TimeDescription, '') = ''
GROUP BY WONumber

CREATE NONCLUSTERED INDEX idx_temp_table_column ON #tblADP_AddlWOs(WONumber)

-- STEP 3: Optional Month Labels

SELECT 
    FORMAT(DATEADD(MONTH, -6, @AsOfDate), 'MMM yyyy') AS Month6,
    FORMAT(DATEADD(MONTH, -5, @AsOfDate), 'MMM yyyy') AS Month5,
    FORMAT(DATEADD(MONTH, -4, @AsOfDate), 'MMM yyyy') AS Month4,
    FORMAT(DATEADD(MONTH, -3, @AsOfDate), 'MMM yyyy') AS Month3,
    FORMAT(DATEADD(MONTH, -2, @AsOfDate), 'MMM yyyy') AS Month2,
    FORMAT(DATEADD(MONTH, -1, @AsOfDate), 'MMM yyyy') AS Month1

-- STEP 4: Final Output

SELECT 
    i.ItemCode,
    UPPER(c.KeyString) AS Category,
    ISNULL(ic.ItemDesc, m.ItemDesc) AS ItemDesc,
    CAST(ISNULL(ic.Quantity, 0) AS int) AS LastPhysicalCount,
    s.SeedDate AS LastPhysicalCount_Date,

    CAST(ISNULL(m.YardiSalesQuantity, 0) AS int) AS TotalSales,
    CAST(ISNULL(m.YardiPurchaseQuantity, 0) AS int) AS TotalPurchases,

    ISNULL((SELECT MAX(v) FROM (VALUES (YardiSales1Mo), (YardiSales2Mo), (YardiSales3Mo), (YardiSales4Mo), (YardiSales5Mo), (YardiSales6Mo)) AS value(v) WHERE ISNULL(v,0) <> 0),0) AS [SixMoHigh],
    ISNULL((SELECT MIN(v) FROM (VALUES (YardiSales1Mo), (YardiSales2Mo), (YardiSales3Mo), (YardiSales4Mo), (YardiSales5Mo), (YardiSales6Mo)) AS value(v) WHERE ISNULL(v,0) <> 0),0) AS [SixMoLow],
    ISNULL(CAST(((YardiSales1Mo + YardiSales2Mo + YardiSales3Mo + YardiSales4Mo + YardiSales5Mo + YardiSales6Mo) / 6.0) AS decimal(10,2)), 0.00) AS SixMoAvg,
    ISNULL(CAST((((YardiSales1Mo + YardiSales2Mo + YardiSales3Mo + YardiSales4Mo + YardiSales5Mo + YardiSales6Mo) / 6.0) * 2) AS decimal(10,2)), 0.00) AS AnnualizedTurnover,

    ISNULL(YardiSales6Mo, 0.00) AS YardiSales6Mo,
    ISNULL(YardiSales5Mo, 0.00) AS YardiSales5Mo,
    ISNULL(YardiSales4Mo, 0.00) AS YardiSales4Mo,
    ISNULL(YardiSales3Mo, 0.00) AS YardiSales3Mo,
    ISNULL(YardiSales2Mo, 0.00) AS YardiSales2Mo,
    ISNULL(YardiSales1Mo, 0.00) AS YardiSales1Mo,

    CAST(ISNULL(ic.Quantity, 0) + ISNULL(m.Quantity, 0) AS int) AS TotalEndQuantity,
    ISNULL(si.UnitPrice, 0.00) AS UnitPrice,
    ISNULL(CAST((si.UnitPrice * (ISNULL(ic.Quantity, 0) + ISNULL(m.Quantity, 0))) AS decimal(10,2)), 0.00) AS TotalEndValue

FROM (
    SELECT DISTINCT ItemCode FROM #tmpSeed
    UNION
    SELECT DISTINCT ItemCode FROM tblInventoryTracking 
    WHERE ReportingDate_calc >= DATEADD(MONTH, -6, @AsOfDate) AND ReportingDate_calc < @AsOfDate
) i

LEFT JOIN (
    SELECT s.ItemCode, s.Quantity, MAX(p.[Description]) AS ItemDesc
    FROM #tmpSeed s
    JOIN tblPhysicalInventory p ON p.Code = s.ItemCode AND p.AsOfDate = s.SeedDate
    GROUP BY s.ItemCode, s.Quantity
) ic ON i.ItemCode = ic.ItemCode

LEFT JOIN (
    SELECT
        it.ItemCode,
        MAX(it.ItemDesc) AS ItemDesc,
        SUM(ISNULL(it.Quantity, 0)) AS Quantity,
        SUM(CASE WHEN it.Quantity < 0 THEN it.Quantity ELSE 0 END) AS YardiSalesQuantity,
        SUM(CASE WHEN it.Quantity > 0 THEN it.Quantity ELSE 0 END) AS YardiPurchaseQuantity,

        SUM(CASE WHEN it.Quantity < 0 AND rd >= DATEADD(MONTH, -1, @AsOfDate) THEN it.Quantity ELSE 0 END) AS YardiSales1Mo,
        SUM(CASE WHEN it.Quantity < 0 AND rd >= DATEADD(MONTH, -2, @AsOfDate) AND rd < DATEADD(MONTH, -1, @AsOfDate) THEN it.Quantity ELSE 0 END) AS YardiSales2Mo,
        SUM(CASE WHEN it.Quantity < 0 AND rd >= DATEADD(MONTH, -3, @AsOfDate) AND rd < DATEADD(MONTH, -2, @AsOfDate) THEN it.Quantity ELSE 0 END) AS YardiSales3Mo,
        SUM(CASE WHEN it.Quantity < 0 AND rd >= DATEADD(MONTH, -4, @AsOfDate) AND rd < DATEADD(MONTH, -3, @AsOfDate) THEN it.Quantity ELSE 0 END) AS YardiSales4Mo,
        SUM(CASE WHEN it.Quantity < 0 AND rd >= DATEADD(MONTH, -5, @AsOfDate) AND rd < DATEADD(MONTH, -4, @AsOfDate) THEN it.Quantity ELSE 0 END) AS YardiSales5Mo,
        SUM(CASE WHEN it.Quantity < 0 AND rd >= DATEADD(MONTH, -6, @AsOfDate) AND rd < DATEADD(MONTH, -5, @AsOfDate) THEN it.Quantity ELSE 0 END) AS YardiSales6Mo

    FROM tblInventoryTracking it
    LEFT JOIN #tblADP_AddlWOs adp ON it.WONumber = adp.WONumber
    LEFT JOIN tblWorkOrders wo ON it.WONumber = wo.WONumber
    LEFT JOIN tblLookupValues lv ON LEFT(it.ItemCode, 2) = CAST(lv.KeyValue AS INT) AND lv.Category = 'InvCategoryID'
    LEFT JOIN #tmpSeed s ON it.ItemCode = s.ItemCode
    CROSS APPLY (SELECT rd = ISNULL(it.ReportingDate_calc, adp.ReceivedDate)) AS dates
    WHERE
        UPPER(lv.KeyString) NOT IN (@ignoreCategory)
        AND ((it.Source = 'PO' AND ISNULL(it.WONumber, 0) = 0) OR it.Source <> 'PO')
        AND ISNULL(wo.Category, '') NOT IN ('APH-Plumbing', 'APH-Boiler')
        AND (s.SeedDate IS NULL OR rd >= s.SeedDate)
        AND rd < @AsOfDate
    GROUP BY it.ItemCode
) m ON i.ItemCode = m.ItemCode

LEFT JOIN tblSortlyInventory si ON i.ItemCode = si.ItemCode
LEFT JOIN #tmpSeed s ON i.ItemCode = s.ItemCode
LEFT JOIN tblLookupValues c ON c.Category = 'InvCategoryID' AND CAST(LEFT(i.ItemCode, 2) AS INT) = CAST(c.KeyValue AS INT)

WHERE UPPER(c.KeyString) NOT IN (@ignoreCategory)
ORDER BY i.ItemCode

DROP TABLE #tblADP_AddlWOs
DROP TABLE #tmpSeed

END
GO
/****** Object:  StoredProcedure [dbo].[spRptBuilder_Inventory_PivotByDay]    Script Date: 2/27/2026 9:28:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Keep this comment: [spRptBuilder_Inventory_PivotByDay] @StartDate='4/1/2025', @EndDate='5/1/2025'

-- =============================================
-- Procedure: [dbo].[spRptBuilder_Inventory_PivotByDay]
-- Version:   v2025.05.31-A
-- Committed: May 31, 2025
-- Author:    Vincent Santangelo
--
-- CHANGELOG SUMMARY:
-- Replaced global @PhysInventoryDate with per-ItemCode seed logic
-- Created #tmpSeed with QtyStart, SeedDate, Description, UnitPrice, and InventoryCategory
-- Removed redundant #SeedItems temp table
-- Updated all joins and logic to use #tmpSeed
-- Ensured one row per ItemCode in Detail tab via grouped ItemSummary
-- All original output columns preserved
-- STRING_AGG updated to nvarchar(MAX) to prevent 8K overflow
-- =============================================

CREATE PROCEDURE [dbo].[spRptBuilder_Inventory_PivotByDay]
    @StartDate as datetime = NULL,
    @EndDate   as datetime = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ignoreCategory varchar(100) = 'CABINETS';

    -- STEP 1: Per-item seed logic — find most recent physical inventory snapshot before @StartDate
    IF OBJECT_ID('tempdb..#LatestSeedDates') IS NOT NULL DROP TABLE #LatestSeedDates;
    SELECT 
        Code, 
        MAX(asOfDate) AS MaxAsOfDate
    INTO #LatestSeedDates
    FROM tblPhysicalInventory
    WHERE asOfDate <= ISNULL(@StartDate, GETDATE())
    GROUP BY Code;

    -- STEP 2: Join back to get actual seed values + item metadata
    IF OBJECT_ID('tempdb..#tmpSeed') IS NOT NULL DROP TABLE #tmpSeed;
    SELECT 
        p.Code AS ItemCode,
        p.PhysicalCount AS QtyStart,
        p.asOfDate AS SeedDate,
        ISNULL(si.ItemName, p.Description) AS [Description],
        si.UnitPrice,
        UPPER(lv.KeyString) AS InventoryCategory
    INTO #tmpSeed
    FROM tblPhysicalInventory p
    INNER JOIN #LatestSeedDates l ON p.Code = l.Code AND p.asOfDate = l.MaxAsOfDate
    LEFT JOIN tblSortlyInventory si ON p.Code = si.ItemCode
    LEFT JOIN tblLookupValues lv ON LEFT(p.Code, 2) = CAST(lv.keyValue AS int) AND lv.Category = 'InvCategoryID';

    -- ADP WOs not in Yardi
    SELECT WONumber, MIN(PayDate) as ReceivedDate
    INTO #tblADP_AddlWOs
    FROM tblADP 
    WHERE WONumber NOT IN (0)
      AND PayDate IS NOT NULL
      AND LaborerID IN (SELECT LaborerID FROM tblLaborers WHERE isCoopSupplier = 1)
      AND (PayDate >= @StartDate AND PayDate < @EndDate)
      AND ISNULL(TimeDescription, '') = ''
    GROUP BY WONumber;

    -- Build pivot column headers dynamically
    DECLARE @cols as nvarchar(MAX) = N'';
    SELECT @cols = CAST(
        STRING_AGG(CAST(QUOTENAME(header) AS nvarchar(max)), ',') AS nvarchar(max)
    )
    FROM (
        SELECT DISTINCT 
            FORMAT(ISNULL(it.ReportingDate_calc, adp.ReceivedDate), 'MM-dd-yy ') +
            CASE 
                WHEN ISNULL(it.WONumber, 0) = 0 THEN 'PO' + CAST(it.PONumber AS varchar(10)) 
                ELSE 'WO' + CAST(it.WONumber AS varchar(10)) 
            END AS header
        FROM tblInventoryTracking it
        LEFT JOIN #tblADP_AddlWOs adp ON it.WONumber = adp.WONumber
        WHERE ISNULL(it.ReportingDate_calc, adp.ReceivedDate) IS NOT NULL
          AND ISNULL(it.ReportingDate_calc, adp.ReceivedDate) >= @StartDate
          AND ISNULL(it.ReportingDate_calc, adp.ReceivedDate) < @EndDate
          AND (
                (it.Source = 'PO' AND ISNULL(it.WONumber, 0) = 0) 
                OR it.Source <> 'PO'
          )
    ) AS headers;

    -- Movement totals by item and header (WO/PO)
    SELECT 
        upper(lv.KeyString) as InventoryCategory,
        it.ItemCode,
        ISNULL(si.ItemName, it.ItemDesc) as [Description],
        si.UnitPrice,
        FORMAT(ISNULL(it.ReportingDate_calc, aa.ReceivedDate), 'MM-dd-yy ') +
            CASE WHEN ISNULL(it.WONumber, 0) = 0 THEN 'PO' + CAST(it.PONumber AS varchar(10)) 
                 ELSE 'WO' + CAST(it.WONumber AS varchar(10)) END as header,
        SUM(it.Quantity) as Quantity
    INTO #MovementsGrouped
    FROM tblInventoryTracking it
        LEFT JOIN tblLookupValues lv ON LEFT(it.ItemCode, 2) = CAST(lv.keyValue AS int) AND lv.Category = 'InvCategoryID'
        LEFT JOIN tblSortlyInventory si ON it.ItemCode = si.ItemCode
        LEFT JOIN #tblADP_AddlWOs aa ON it.WONumber = aa.WONumber
        LEFT JOIN tblWorkOrders wo ON it.WONumber = wo.WONumber
    WHERE upper(lv.KeyString) NOT IN (@ignoreCategory)
      AND ((it.Source = 'PO' AND ISNULL(it.WONumber, 0) = 0) OR it.Source <> 'PO')
      AND ISNULL(wo.Category, '') NOT IN ('APH-Plumbing', 'APH-Boiler')
      AND ((ISNULL(it.ReportingDate_calc, aa.ReceivedDate) IS NOT NULL
            AND ISNULL(it.ReportingDate_calc, aa.ReceivedDate) >= @StartDate
            AND ISNULL(it.ReportingDate_calc, aa.ReceivedDate) < @EndDate)
           OR (aa.WONumber IS NOT NULL))
    GROUP BY 
        lv.KeyString,
        it.ItemCode,
        si.ItemName,
        it.ItemDesc,
        si.UnitPrice,
        FORMAT(ISNULL(it.ReportingDate_calc, aa.ReceivedDate), 'MM-dd-yy ') +
            CASE WHEN ISNULL(it.WONumber, 0) = 0 THEN 'PO' + CAST(it.PONumber AS varchar(10)) 
                 ELSE 'WO' + CAST(it.WONumber AS varchar(10)) END;

-- Combine movement + seed
SELECT 
    COALESCE(m.InventoryCategory, s.InventoryCategory) AS InventoryCategory,
    m.ItemCode,
    COALESCE(m.Description, s.Description) AS [Description],
    COALESCE(m.UnitPrice, s.UnitPrice) AS UnitPrice,
    m.header,
    m.Quantity,
    ISNULL(s.QtyStart, 0) as QtyStart,
    ISNULL(m.Quantity, 0) + ISNULL(s.QtyStart, 0) as QtyTotal,
    CAST(COALESCE(m.UnitPrice, s.UnitPrice, 0) * (ISNULL(m.Quantity, 0) + ISNULL(s.QtyStart, 0)) as decimal(10,2)) as PriceTotal
INTO #tmp
FROM #MovementsGrouped m
LEFT JOIN #tmpSeed s ON m.ItemCode = s.ItemCode

-- Tab 1: Dates
SELECT 
    FORMAT(@StartDate, 'MM/dd/yy') as [Report Start Date], 
    FORMAT(@EndDate, 'MM/dd/yy') as [End Date]

-- Tab 2: Summary
SELECT 
    InventoryCategory, 
    SUM(ISNULL(QtyStart, 0)) as QtyStart,
    SUM(ISNULL(QtyTotal, 0)) as QtyTotal,
    SUM(ISNULL(PriceTotal, 0)) as Total
FROM (
    SELECT 
        InventoryCategory, 
        ItemCode,
        MAX(QtyStart) as QtyStart,
        MAX(QtyTotal) as QtyTotal,
        MAX(PriceTotal) as PriceTotal
    FROM #tmp
    GROUP BY InventoryCategory, ItemCode
) AS rolled
GROUP BY InventoryCategory
ORDER BY InventoryCategory

-- Tab 3: Pivoted Details
SELECT
    InventoryCategory,
    ItemCode,
    header,
    SUM(Quantity) AS Quantity
INTO #PivotMovements
FROM #tmp
GROUP BY InventoryCategory, ItemCode, header

SELECT
    InventoryCategory,
    ItemCode,
    MAX([Description]) AS [Description],
    MAX(UnitPrice) AS UnitPrice,
    MAX(QtyStart) AS QtyStart,
    MAX(QtyTotal) AS QtyTotal,
    MAX(PriceTotal) AS PriceTotal
INTO #ItemSummary
FROM #tmp
GROUP BY InventoryCategory, ItemCode

SELECT @cols = CAST(
    STRING_AGG(CAST(QUOTENAME(header) AS nvarchar(max)), ',')
    AS nvarchar(max)
)
FROM (SELECT DISTINCT header FROM #PivotMovements) AS headers

DECLARE @sql nvarchar(max) = '
SELECT 
    s.InventoryCategory, 
    s.ItemCode, 
    s.[Description], 
    s.UnitPrice, 
    s.QtyStart, 
    s.QtyTotal, 
    s.PriceTotal, 
    ' + @cols + '
FROM (
    SELECT InventoryCategory, ItemCode, header, Quantity
    FROM #PivotMovements
) AS src
PIVOT (
    SUM(Quantity) FOR header IN (' + @cols + ')
) AS pvt
INNER JOIN #ItemSummary s 
    ON s.InventoryCategory = pvt.InventoryCategory AND s.ItemCode = pvt.ItemCode
ORDER BY s.ItemCode'

EXEC sp_executesql @sql

-- Tab 4: Laborers
SELECT DISTINCT 
    it.WONumber, 
    ISNULL(
        CASE WHEN adp.Laborers IS NULL THEN wo.POVendors ELSE adp.Laborers + ISNULL(' / ' + wo.POVendors, '') END,
        it.Category
    ) as [Laborers],
    upper(wo.Category) as WOCategory
FROM tblInventoryTracking it
LEFT JOIN tblWorkOrders wo ON it.WONumber = wo.WONumber
LEFT JOIN (
    SELECT WONumber, STRING_AGG(FullName_Calc, ' / ') AS Laborers
    FROM (
        SELECT DISTINCT adp.WONumber, la.FullName_Calc
        FROM tblADP adp
        LEFT JOIN tblLaborers la ON adp.LaborerID = la.LaborerID
        WHERE ISNULL(adp.WONumber, '') > ''
    ) as distinctLaborers
    GROUP BY WONumber
) adp ON it.WONumber = adp.WONumber
WHERE ISNULL(it.WONumber, 0) > 0
  AND ISNULL(wo.Category, '') NOT IN ('APH-Plumbing', 'APH-Boiler')
  AND (
        (ISNULL(it.ReportingDate_calc, it.DateOfSale) IS NOT NULL
        AND ISNULL(it.ReportingDate_calc, it.DateOfSale) >= @StartDate
        AND ISNULL(it.ReportingDate_calc, it.DateOfSale) < @EndDate)
        OR (it.WONumber IN (SELECT WONumber FROM #tblADP_AddlWOs))
    )
ORDER BY it.WONumber

-- Tab 5: PO Vendors
SELECT DISTINCT p.PONumber, STRING_AGG(p.VendorName, ' / ') as Vendors
FROM tblPurchaseOrders p
WHERE p.VendorName IS NOT NULL
GROUP BY p.PONumber
ORDER BY p.PONumber

-- Tab 6: Exceptions
SELECT 
    po.WONumber, 
    d.PONumber, 
    po.VendorName, 
    d.QtyOrdered, 
    d.UnitPrice, 
    CAST(ISNULL(d.QtyOrdered,0) * ISNULL(d.UnitPrice,0) AS decimal(10,2)) as TotalCost, 
    FORMAT(po.OrderDate, 'MM/dd/yy') as OrderDate, 
    FORMAT(po.ReceivedDate, 'MM/dd/yy') as ReceivedDate, 
    d.ItemCode, 
    d.ItemDesc, 
    po.ExpenseType, 
    CASE WHEN ISNULL(prop.addr1_Co, '') > '' AND ISNULL(prop.addr2, '') > '' 
         THEN UPPER(TRIM(prop.addr1_Co + ', ' + prop.addr2)) 
         ELSE UPPER(TRIM(prop.addr1_Co + prop.addr2)) 
    END as Client
FROM tblPurchaseOrders_Details d
LEFT JOIN tblPurchaseOrders po ON d.PONumber = po.PONumber
LEFT JOIN tblWorkOrders wo ON po.WONumber = wo.WONumber
LEFT JOIN tblProperties prop ON wo.BuildingNum = prop.BuildingCode
WHERE po.ReceivedDate IS NOT NULL
  AND po.ReceivedDate >= @StartDate
  AND po.ReceivedDate < @EndDate
  AND d.ItemCode LIKE 'material%'
ORDER BY po.WONumber, d.PONumber

-- CLEANUP
DROP TABLE IF EXISTS #tblADP_AddlWOs;
DROP TABLE IF EXISTS #LatestSeedDates;
DROP TABLE IF EXISTS #tmpSeed;
DROP TABLE IF EXISTS #MovementsGrouped;
DROP TABLE IF EXISTS #tmp;
DROP TABLE IF EXISTS #PivotMovements;
DROP TABLE IF EXISTS #ItemSummary;

END
GO
/****** Object:  StoredProcedure [dbo].[spRptBuilder_Vacancy_Cover]    Script Date: 2/27/2026 9:28:25 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spRptBuilder_Vacancy_Cover_pt2]    Script Date: 2/27/2026 9:28:25 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spRptBuilder_WOReview_01_WOs]    Script Date: 2/27/2026 9:28:25 PM ******/
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
		PostedMonth = case when src.PostedMonth is null then tblWorkOrders.PostedMonth else src.PostedMonth end 
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


	/* DELETE WORK ORDER ITEMS THAT HAVE BEEN REMOVED - Comparing to the temp import table */
	/* -- The trigger on tblWorkOrderItems should delete rows in tblInventoryTracking */
	-- First delete from tblInventoryTracking
	DELETE it
	FROM tblInventoryTracking it
	WHERE it.Source IN ('WO', 'PO')
	  AND EXISTS (
		  SELECT 1 FROM tblImport_Yardi_WOList i
		  WHERE i.WONumber = it.WONumber
	  )
	  AND NOT EXISTS (
		  SELECT 1 FROM tblImport_Yardi_WOList i
		  WHERE i.WONumber = it.WONumber AND i.Code = it.ItemCode
	  );


	-- Then delete from tblWorkOrderItems
	DELETE woi
	FROM tblWorkOrderItems woi
		LEFT JOIN tblInventoryTracking it ON woi.WONumber = it.WONumber AND woi.ItemCode = it.ItemCode
	WHERE (it.Source IN ('WO', 'PO') OR it.Source IS NULL)
	  AND EXISTS (
		  SELECT 1 FROM tblImport_Yardi_WOList i
		  WHERE i.WONumber = woi.WONumber
	  )
	  AND NOT EXISTS (
		  SELECT 1 FROM tblImport_Yardi_WOList i
		  WHERE i.WONumber = woi.WONumber AND i.Code = woi.ItemCode
	  );



END

GO
/****** Object:  StoredProcedure [dbo].[spRptBuilder_WOReview_02_POs]    Script Date: 2/27/2026 9:28:25 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spRptBuilder_WOReview_03_Labor]    Script Date: 2/27/2026 9:28:25 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spRptBuilder_WOReview_04_SortlyFixes]    Script Date: 2/27/2026 9:28:25 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spRptBuilder_WOReview_05_Materials]    Script Date: 2/27/2026 9:28:25 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spRptBuilder_WOReview_06_Calcs]    Script Date: 2/27/2026 9:28:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO











-- spRptBuilder_WOReview_06_Calcs 

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

END		
GO
/****** Object:  StoredProcedure [dbo].[spSortlyFillInventoryTable]    Script Date: 2/27/2026 9:28:25 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spSortlyWorkOrderUpdate]    Script Date: 2/27/2026 9:28:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO











CREATE PROCEDURE [dbo].[spSortlyWorkOrderUpdate]
	--@SortlyImportRowID int = NULL,
	@WONumber int = NULL,  -- the WO Number is calcualted in Sortly - but if it's sent in here then use it
	--@ActivityDate_Calc datetime = NULL,
	@SortlyID varchar(20) = NULL,
	@ItemName varchar(100) = NULL,
	@Quantity int = NULL,
	@UnitPrice decimal(10,2) = NULL,
	@TotalValue decimal(10,2) = NULL,
	@Notes varchar(500) = NULL,
	--@Tags varchar(100) = NULL,
	@PrimaryFolder varchar(100) = NULL,
	@SubFolderLevel1 varchar(100) = NULL,
	@SubFolderLevel2 varchar(100) = NULL,
	@SubFolderLevel3 varchar(100) = NULL,
	@SubFolderLevel4 varchar(100) = NULL,
	@WODate datetime = NULL,
	--@SellPrice decimal(10,2) = NULL,
	--@LandedCost decimal(10,2) = NULL,
	@Createdby varchar(20) = NULL,
	@CreateDate DateTime = getdate,

	@NoReturn bit = 0  -- 0=Return a row of the inserted or updated data; 1=Return nothing / DEPRECIATED
AS
BEGIN

			INSERT INTO tblImport_Sortly(WONumber_Calc, SortlyID, ItemName, Quantity, UnitPrice, TotalValue, Notes, 
			PrimaryFolder, SubFolderLevel1, SubFolderLevel2, SubFolderLevel3, SubFolderLevel4, WODate, CreatedBy, CreateDate) 
			VALUES(@WONumber, @SortlyID, @ItemName, @Quantity, @UnitPrice, @TotalValue, @Notes, 
			@PrimaryFolder, @SubFolderLevel1, @SubFolderLevel2, @SubFolderLevel3, @SubFolderLevel4, @WODate, @CreatedBy, @CreateDate) 

END
GO
/****** Object:  StoredProcedure [dbo].[spTenantAR_DailySnapshot_RetentionCleanup]    Script Date: 2/27/2026 9:28:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[spTenantAR_DailySnapshot_RetentionCleanup]
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
/****** Object:  StoredProcedure [dbo].[spUsers]    Script Date: 2/27/2026 9:28:25 PM ******/
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

	SELECT *, 
		trim(FirstName + ' ' + LastName) as FullName,
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
/****** Object:  StoredProcedure [dbo].[spUserUpdate]    Script Date: 2/27/2026 9:28:25 PM ******/
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
	@isProjectManager bit = 0,
	@isLegalTeam bit = 0,
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
			( FirstName, LastName, password_enc, isAdmin, isSuperAdmin, emailAddress, isDisabled, tempPassword_enc, isLegalTeam, isProjectManager )
			VALUES( @FirstName, @LastName, @password_enc, @isAdmin, @isSuperAdmin, @emailAddress, @isDisabled, @tempPassword_enc, @isLegalTeam, @isProjectManager )

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
				isLegalTeam = @isLegalTeam,
				isProjectManager = @isProjectManager,
				isDisabled = @isDisabled,
				tempPassword_enc = @tempPassword_enc
		
			WHERE UserID=@UserID
		END

	EXEC dbo.spUsers @UserID=@UserID

END
GO
/****** Object:  StoredProcedure [dbo].[spWOAnalysisReport]    Script Date: 2/27/2026 9:28:25 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spWOAnalysisReport_Labor]    Script Date: 2/27/2026 9:28:25 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spWOAnalysisReport_LaborerTeamSubtotals]    Script Date: 2/27/2026 9:28:25 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spWOAnalysisReport_Lookup_Laborers]    Script Date: 2/27/2026 9:28:25 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spWOAnalysisReport_LookupValues]    Script Date: 2/27/2026 9:28:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[spWOAnalysisReport_LookupValues]
AS
	select Category, KeyString, isnull(KeyString2,''), KeyValue 
	from tblLookupValues order by category, keystring, KeyString2
GO
/****** Object:  StoredProcedure [dbo].[spWorkOrderItems]    Script Date: 2/27/2026 9:28:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[spWorkOrderItems]
    @CategoriesCsv            varchar(max) = NULL,
    @CompletionDateIsBlank    bit = NULL,
    @WONumber                int = NULL,
    @BuildingNumsCsv          varchar(max) = NULL,
    @JobStatus                varchar(50) = NULL,
    @ItemCodesCsv             varchar(max) = NULL,
    @FilterItemCategoriesCsv  varchar(max) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT woi.*, si.Category AS ItemCategoryName
    FROM dbo.tblWorkOrderItems woi
    INNER JOIN dbo.tblWorkOrders wo ON wo.WONumber = woi.WONumber
    LEFT JOIN dbo.tblSortlyInventory si ON si.ItemCode = woi.ItemCode
    WHERE 1 = 1
      AND (
            @CategoriesCsv IS NULL
            OR EXISTS (
                SELECT 1
                FROM STRING_SPLIT(@CategoriesCsv, ',') s
                WHERE UPPER(LTRIM(RTRIM(s.value))) = UPPER(wo.Category)
            )
          )
      AND (
            @CompletionDateIsBlank IS NULL
            OR (@CompletionDateIsBlank = 1 AND wo.CompletedDate IS NULL)
            OR (@CompletionDateIsBlank = 0 AND wo.CompletedDate IS NOT NULL)
          )
      AND (
            @WONumber IS NULL
            OR wo.WONumber = @WONumber
          )
      AND (
            @BuildingNumsCsv IS NULL
            OR EXISTS (
                SELECT 1
                FROM STRING_SPLIT(@BuildingNumsCsv, ',') s
                WHERE UPPER(LTRIM(RTRIM(s.value))) = UPPER(wo.BuildingNum)
            )
          )
      AND (
            @JobStatus IS NULL
            OR UPPER(wo.JobStatus) = UPPER(@JobStatus)
          )
      AND (
            @ItemCodesCsv IS NULL
            OR EXISTS (
                SELECT 1
                FROM STRING_SPLIT(@ItemCodesCsv, ',') s
                WHERE UPPER(LTRIM(RTRIM(s.value))) = UPPER(woi.ItemCode)
            )
          )
      AND (
            @FilterItemCategoriesCsv IS NULL
            OR EXISTS (
                SELECT 1
                FROM STRING_SPLIT(@FilterItemCategoriesCsv, ',') s
                WHERE UPPER(LTRIM(RTRIM(s.value))) = UPPER(si.Category)
            )
          );
END;
GO
/****** Object:  StoredProcedure [dbo].[spWorkOrders]    Script Date: 2/27/2026 9:28:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
API procedures for Work Orders endpoint.
Supports CSV filters to avoid large per-value SQL parameter lists.
*/

CREATE   PROCEDURE [dbo].[spWorkOrders]
    @CategoriesCsv            varchar(max) = NULL,
    @CompletionDateIsBlank    bit = NULL,
    @WONumber                int = NULL,
    @BuildingNumsCsv          varchar(max) = NULL,
    @JobStatus                varchar(50) = NULL,
    @ItemCodesCsv             varchar(max) = NULL,
    @FilterItemCategoriesCsv  varchar(max) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT wo.*
    FROM dbo.tblWorkOrders wo
    WHERE 1 = 1
      AND (
            @CategoriesCsv IS NULL
            OR EXISTS (
                SELECT 1
                FROM STRING_SPLIT(@CategoriesCsv, ',') s
                WHERE UPPER(LTRIM(RTRIM(s.value))) = UPPER(wo.Category)
            )
          )
      AND (
            @CompletionDateIsBlank IS NULL
            OR (@CompletionDateIsBlank = 1 AND wo.CompletedDate IS NULL)
            OR (@CompletionDateIsBlank = 0 AND wo.CompletedDate IS NOT NULL)
          )
      AND (
            @WONumber IS NULL
            OR wo.WONumber = @WONumber
          )
      AND (
            @BuildingNumsCsv IS NULL
            OR EXISTS (
                SELECT 1
                FROM STRING_SPLIT(@BuildingNumsCsv, ',') s
                WHERE UPPER(LTRIM(RTRIM(s.value))) = UPPER(wo.BuildingNum)
            )
          )
      AND (
            @JobStatus IS NULL
            OR UPPER(wo.JobStatus) = UPPER(@JobStatus)
          );
END;
GO
/****** Object:  StoredProcedure [dbo].[spWorkOrderUpdate]    Script Date: 2/27/2026 9:28:25 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spYardiPODetailsUpdate]    Script Date: 2/27/2026 9:28:25 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spYardiPOs]    Script Date: 2/27/2026 9:28:25 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spYardiPOsInvItemsUpdate]    Script Date: 2/27/2026 9:28:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spYardiPOsInvItemsUpdate]
    @POItemRowID        INT             = NULL,     -- identity key not used for matching
    @YardiMM2PODetID    BIGINT          = NULL,  
    @PONumber           INT             = NULL,
    @WONumber           INT             = NULL,
    @Vendor             VARCHAR(250)    = NULL,
    @QtyOrdered         DECIMAL(10,2)   = 0.00,
    @UnitPrice          DECIMAL(10,2)   = 0.00,
    @TotalCost          DECIMAL(10,2)   = 0.00,
    @OrderDate          DATETIME        = NULL,
    @ReceivedDate       DATETIME        = NULL,
    @ItemCode           VARCHAR(15)     = NULL,
    @ItemDesc           VARCHAR(200)    = NULL,
    @ExpenseType        VARCHAR(50)     = NULL,
    @isSeedItem         BIT             = 0,
    @Client             VARCHAR(250)    = NULL,
    @VendorCode         VARCHAR(25)     = NULL,
    @POAmount           DECIMAL(10,2)   = NULL,
    @WOAndInvoiceAmt    DECIMAL(10,2)   = NULL
AS
BEGIN
    SET NOCOUNT ON;

    ----------------------------------------------------------------------
    -- Normalize ReceivedDate key
    -- NULL means NULL — preserve exactly as Yardi gave it.
    ----------------------------------------------------------------------
    DECLARE @FinalReceivedDate DATE =
        CASE WHEN @ReceivedDate IS NOT NULL 
             THEN CONVERT(DATE, @ReceivedDate)
             ELSE NULL
        END;

    DECLARE @KeyItemCode VARCHAR(15) = ISNULL(@ItemCode, '');

    ----------------------------------------------------------------------
    -- Variables used for aggregation
    ----------------------------------------------------------------------
    DECLARE 
        @ExistingRowID       INT,
        @OldQty              DECIMAL(18,4),
        @OldTotal            DECIMAL(18,4),
        @ThisRowTotal        DECIMAL(18,4),
        @NewQty              DECIMAL(18,4),
        @NewTotal            DECIMAL(18,4),
        @NewUnitPrice        DECIMAL(18,4),
        @ExistingSeed        BIT;

    ----------------------------------------------------------------------
    -- Find existing row for this PONumber + Item + (ReceivedDate OR NULL)
    ----------------------------------------------------------------------
    SELECT TOP (1)
        @ExistingRowID = POItemRowID,
        @OldQty        = QtyOrdered,
        @OldTotal      = TotalCost,
        @ExistingSeed  = isSeedItem
    FROM dbo.tblImport_Inv_Yardi_POItems t
    WHERE t.PONumber = @PONumber
      AND ISNULL(t.ItemCode,'') = @KeyItemCode
      AND (
            ( @FinalReceivedDate IS NULL AND t.ReceivedDate IS NULL )
            OR
            ( @FinalReceivedDate IS NOT NULL 
              AND CONVERT(date, t.ReceivedDate) = @FinalReceivedDate )
          );

    ----------------------------------------------------------------------
    -- FIRST INSERT (no existing bucket)
    ----------------------------------------------------------------------
    IF @ExistingRowID IS NULL
    BEGIN
        INSERT INTO dbo.tblImport_Inv_Yardi_POItems
        (
            YardiMM2PODetID, PONumber, WONumber, Vendor,
            QtyOrdered, UnitPrice, TotalCost, OrderDate, ReceivedDate,
            ItemCode, ItemDesc, ExpenseType, isSeedItem,
            Client, VendorCode, POAmount, WOAndInvoiceAmt,
            AggregateSourceIDs, RowCountAggregated,
            LastUpdateReason, LastUpdateDate
        )
        VALUES
        (
            @YardiMM2PODetID, @PONumber, @WONumber, @Vendor,
            @QtyOrdered, @UnitPrice, @TotalCost, @OrderDate, @FinalReceivedDate,
            @ItemCode, @ItemDesc, @ExpenseType, @isSeedItem,
            @Client, @VendorCode, @POAmount, @WOAndInvoiceAmt,
            CAST(@YardiMM2PODetID AS VARCHAR(20)),  -- raw detail IDs list
            1,                                      -- aggregated 1 row
            'INSERT-FIRST',
            GETDATE()
        );
        RETURN;
    END

    ----------------------------------------------------------------------
    -- If existing row is a seed row > DO NOT modify financials/dates
    ----------------------------------------------------------------------
    IF @ExistingSeed = 1
    BEGIN
        UPDATE dbo.tblImport_Inv_Yardi_POItems
        SET AggregateSourceIDs =
                COALESCE(AggregateSourceIDs + ',' + CAST(@YardiMM2PODetID AS VARCHAR(20)),
                         CAST(@YardiMM2PODetID AS VARCHAR(20))),
            RowCountAggregated = ISNULL(RowCountAggregated,0) + 1,
            LastUpdateReason   = 'SEEDED-NO-UPDATE',
            LastUpdateDate     = GETDATE()
        WHERE POItemRowID = @ExistingRowID;
        RETURN;
    END

    ----------------------------------------------------------------------
    -- AGGREGATE INTO EXISTING BUCKET
    ----------------------------------------------------------------------
    SET @OldQty   = ISNULL(@OldQty,   0);
    SET @OldTotal = ISNULL(@OldTotal, 0);

    SET @ThisRowTotal = ISNULL(@TotalCost, @QtyOrdered * @UnitPrice);

    SET @NewQty   = @OldQty   + ISNULL(@QtyOrdered, 0);
    SET @NewTotal = @OldTotal + @ThisRowTotal;

    SET @NewUnitPrice =
        CASE WHEN @NewQty <> 0 THEN @NewTotal / @NewQty ELSE NULL END;

    UPDATE t
    SET
        QtyOrdered       = @NewQty,
        TotalCost        = @NewTotal,
        UnitPrice        = @NewUnitPrice,

        -- Only fill these if they were NULL before
        WONumber         = COALESCE(t.WONumber, @WONumber),
        Vendor           = COALESCE(t.Vendor, @Vendor),
        OrderDate        = COALESCE(t.OrderDate, @OrderDate),
        ItemDesc         = COALESCE(t.ItemDesc, @ItemDesc),
        ExpenseType      = COALESCE(t.ExpenseType, @ExpenseType),
        Client           = COALESCE(t.Client, @Client),
        VendorCode       = COALESCE(t.VendorCode, @VendorCode),
        POAmount         = COALESCE(t.POAmount, @POAmount),
        WOAndInvoiceAmt  = COALESCE(t.WOAndInvoiceAmt, @WOAndInvoiceAmt),

        AggregateSourceIDs =
            COALESCE(AggregateSourceIDs + ',' + CAST(@YardiMM2PODetID AS VARCHAR(20)),
                     CAST(@YardiMM2PODetID AS VARCHAR(20))),

        RowCountAggregated = ISNULL(RowCountAggregated,0) + 1,
        LastUpdateReason   = 'AGGREGATED',
        LastUpdateDate     = GETDATE()
    FROM dbo.tblImport_Inv_Yardi_POItems t
    WHERE t.POItemRowID = @ExistingRowID;

END
GO
/****** Object:  StoredProcedure [dbo].[spYardiPOsUpdate]    Script Date: 2/27/2026 9:28:25 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spYardiWOs]    Script Date: 2/27/2026 9:28:25 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spYardiWOsInvItemsUpdate]    Script Date: 2/27/2026 9:28:25 PM ******/
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
/****** Object:  StoredProcedure [dbo].[spYardiWOsUpdate]    Script Date: 2/27/2026 9:28:25 PM ******/
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
			INSERT INTO tblImport_Yardi_WOList(WONumber, BuildingNum, AptNum, JobStatus, Category, CallDate, --StartDate, 
					SchedDate, CompleteDate, BatchID, BatchDate, TransBatchDate, Employee, BriefDesc, Quantity, Code, FullDesc, UnitPrice, PayAmt, PostedMonth,
					WODetailRowID,
					createdBy, createDate)
			VALUES(@WONumber, @BuildingNum, @AptNum, @JobStatus, @Category, @CallDate, --@StartDate, 
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
				--StartDate = @StartDate, 
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
USE [master]
GO
ALTER DATABASE [lemlewolff] SET  READ_WRITE 
GO
