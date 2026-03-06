USE [LemleWolff]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dbo.tblWorkOrderItemCatalog', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.tblWorkOrderItemCatalog
    (
        ItemCode VARCHAR(25) NOT NULL CONSTRAINT PK_tblWorkOrderItemCatalog PRIMARY KEY,
        ItemDesc VARCHAR(250) NULL,
        Category VARCHAR(50) NULL,
        IsActive BIT NOT NULL CONSTRAINT DF_tblWorkOrderItemCatalog_IsActive DEFAULT (1)
    );
END
GO

GRANT SELECT ON dbo.tblWorkOrderItemCatalog TO lemwolffRO;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.tblWorkOrderItemCatalog TO lemwolffRW;
GO
