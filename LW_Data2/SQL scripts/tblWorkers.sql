USE [LemleWolff]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dbo.tblWorkers', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.tblWorkers
    (
        WorkerID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tblWorkers PRIMARY KEY,
        CompanyCode VARCHAR(10) NOT NULL,
        ADPFileNumber VARCHAR(25) NOT NULL,
        DisplayName VARCHAR(200) NOT NULL,
        IsActive BIT NOT NULL CONSTRAINT DF_tblWorkers_IsActive DEFAULT (1)
    );

    CREATE UNIQUE INDEX UX_tblWorkers_Company_File
        ON dbo.tblWorkers (CompanyCode, ADPFileNumber);
END
GO

GRANT SELECT ON dbo.tblWorkers TO lemlewolffRO;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.tblWorkers TO lemlewolffRW;
GO
