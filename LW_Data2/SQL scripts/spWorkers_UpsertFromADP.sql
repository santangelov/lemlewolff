USE [LemleWolff]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.spWorkers_UpsertFromADP
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH src AS
    (
        SELECT
            CompanyCode = LTRIM(RTRIM(a.CompanyCode)),
            ADPFileNumber = LTRIM(RTRIM(a.FileNumber)),
            DisplayName = MAX(LTRIM(RTRIM(a.PayrollName)))
        FROM dbo.tblADP a
        WHERE ISNULL(LTRIM(RTRIM(a.FileNumber)), '') <> ''
          AND LTRIM(RTRIM(a.FileNumber)) <> '000000'
        GROUP BY LTRIM(RTRIM(a.CompanyCode)), LTRIM(RTRIM(a.FileNumber))
    )
    MERGE dbo.tblWorkers AS tgt
    USING src
        ON tgt.CompanyCode = src.CompanyCode
       AND tgt.ADPFileNumber = src.ADPFileNumber
    WHEN MATCHED THEN
        UPDATE SET
            tgt.DisplayName = src.DisplayName,
            tgt.IsActive = 1
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (CompanyCode, ADPFileNumber, DisplayName, IsActive)
        VALUES (src.CompanyCode, src.ADPFileNumber, src.DisplayName, 1)
    WHEN NOT MATCHED BY SOURCE THEN
        UPDATE SET tgt.IsActive = 0;
END;
GO

GRANT EXECUTE ON dbo.spWorkers_UpsertFromADP TO lemlewolffRW;
GO
