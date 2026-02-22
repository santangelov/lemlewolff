/*
API procedures for Work Orders endpoint.
Supports CSV filters to avoid large per-value SQL parameter lists.
*/

CREATE OR ALTER PROCEDURE dbo.spWorkOrders
    @CategoriesCsv            varchar(max) = NULL,
    @CompletionDateIsBlank    bit = NULL,
    @WONumber                int = NULL,
    @BuildingNumsCsv          varchar(max) = NULL,
    @JobStatus                varchar(50) = NULL
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

CREATE OR ALTER PROCEDURE dbo.spWorkOrderItems
    @WONumber                int,
    @ItemCodesCsv             varchar(max) = NULL,
    @FilterItemCategoriesCsv  varchar(max) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT woi.*, si.Category AS ItemCategoryName
    FROM dbo.tblWorkOrderItems woi
    INNER JOIN dbo.tblWorkOrders wo ON wo.WONumber = woi.WONumber
    LEFT JOIN dbo.tblSortlyInventory si ON si.ItemCode = woi.ItemCode
    WHERE wo.WONumber = @WONumber
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

GRANT EXECUTE ON OBJECT::dbo.spWorkOrders TO [lemwolffRO];
GRANT EXECUTE ON OBJECT::dbo.spWorkOrderItems TO [lemwolffRO];
GO
