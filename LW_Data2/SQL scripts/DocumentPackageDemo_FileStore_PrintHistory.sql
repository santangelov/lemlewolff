SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.tblPrintHistory', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[tblPrintHistory]
    (
        [PrintHistoryID] INT IDENTITY(1,1) NOT NULL,
        [PrintType] NVARCHAR(100) NOT NULL,
        [BuildingID] INT NULL,
        [UnitID] INT NULL,
        [TenantID] INT NULL,
        [CombinedFileID] INT NULL,
        [CreatedByUser] NVARCHAR(100) NOT NULL,
        [CreatedDate] DATETIME NOT NULL CONSTRAINT [DF_tblPrintHistory_CreatedDate] DEFAULT (GETDATE()),
        [UnitCount] INT NULL,
        [Notes] NVARCHAR(500) NULL,
        CONSTRAINT [PK_tblPrintHistory] PRIMARY KEY CLUSTERED ([PrintHistoryID] ASC)
    );
END
GO

IF OBJECT_ID(N'dbo.tblFileStore', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[tblFileStore]
    (
        [FileID] INT IDENTITY(1,1) NOT NULL,
        [FileCategory] NVARCHAR(100) NOT NULL,
        [RelatedTable] NVARCHAR(100) NULL,
        [RelatedRecordID] INT NULL,
        [BuildingID] INT NULL,
        [UnitID] INT NULL,
        [TenantID] INT NULL,
        [FilePath] NVARCHAR(500) NOT NULL,
        [FileName] NVARCHAR(255) NOT NULL,
        [FileExtension] NVARCHAR(20) NOT NULL,
        [FileSizeBytes] BIGINT NULL,
        [CreatedDate] DATETIME NOT NULL CONSTRAINT [DF_tblFileStore_CreatedDate] DEFAULT (GETDATE()),
        [CreatedByUser] NVARCHAR(100) NOT NULL,
        CONSTRAINT [PK_tblFileStore] PRIMARY KEY CLUSTERED ([FileID] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tblPrintHistory_BuildingID' AND object_id = OBJECT_ID(N'dbo.tblPrintHistory'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_tblPrintHistory_BuildingID] ON [dbo].[tblPrintHistory] ([BuildingID] ASC);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tblPrintHistory_UnitID' AND object_id = OBJECT_ID(N'dbo.tblPrintHistory'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_tblPrintHistory_UnitID] ON [dbo].[tblPrintHistory] ([UnitID] ASC);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tblPrintHistory_CreatedDate' AND object_id = OBJECT_ID(N'dbo.tblPrintHistory'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_tblPrintHistory_CreatedDate] ON [dbo].[tblPrintHistory] ([CreatedDate] ASC);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tblFileStore_BuildingID' AND object_id = OBJECT_ID(N'dbo.tblFileStore'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_tblFileStore_BuildingID] ON [dbo].[tblFileStore] ([BuildingID] ASC);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tblFileStore_UnitID' AND object_id = OBJECT_ID(N'dbo.tblFileStore'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_tblFileStore_UnitID] ON [dbo].[tblFileStore] ([UnitID] ASC);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tblFileStore_TenantID' AND object_id = OBJECT_ID(N'dbo.tblFileStore'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_tblFileStore_TenantID] ON [dbo].[tblFileStore] ([TenantID] ASC);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tblFileStore_CreatedDate' AND object_id = OBJECT_ID(N'dbo.tblFileStore'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_tblFileStore_CreatedDate] ON [dbo].[tblFileStore] ([CreatedDate] ASC);
END
GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.tblPrintHistory') AND type = N'U')
BEGIN
    GRANT SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.tblPrintHistory TO [lemwolffRW];
    GRANT SELECT ON OBJECT::dbo.tblPrintHistory TO [lemwolffRO];
END
GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.tblFileStore') AND type = N'U')
BEGIN
    GRANT SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.tblFileStore TO [lemwolffRW];
    GRANT SELECT ON OBJECT::dbo.tblFileStore TO [lemwolffRO];
END
GO
