USE [LemleWolff]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
API procedures for Work Orders endpoint.
Supports CSV filters to avoid large per-value SQL parameter lists.
*/

CREATE OR ALTER PROCEDURE dbo.spWorkOrders
    @CategoriesCsv            varchar(max) = NULL,
    @CompletionDateIsBlank    bit = NULL,
    @WONumber                 int = NULL,
    @BuildingNumsCsv          varchar(max) = NULL,
    @JobStatus                varchar(50) = NULL,
    @ItemCodesCsv             varchar(max) = NULL,
    @FilterItemCategoriesCsv  varchar(max) = NULL,
    @IsAssigned               bit = NULL,
    @AssignedToID             int = NULL
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
          )
      AND (
            @IsAssigned IS NULL
            OR (@IsAssigned = 1 AND wo.AssignedToID IS NOT NULL)
            OR (@IsAssigned = 0 AND wo.AssignedToID IS NULL)
          )
      AND (
            @AssignedToID IS NULL
            OR wo.AssignedToID = @AssignedToID
          );
END;
GO

CREATE OR ALTER PROCEDURE dbo.spWorkOrderItems
    @CategoriesCsv            varchar(max) = NULL,
    @CompletionDateIsBlank    bit = NULL,
    @WONumber                 int = NULL,
    @BuildingNumsCsv          varchar(max) = NULL,
    @JobStatus                varchar(50) = NULL,
    @ItemCodesCsv             varchar(max) = NULL,
    @FilterItemCategoriesCsv  varchar(max) = NULL,
    @IsAssigned               bit = NULL,
    @AssignedToID             int = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        woi.WOItemRowID,
        woi.YardiWODetailRowID,
        woi.WONumber,
        woi.ItemCode,
        woi.Quantity,
        woi.PayAmount,
        COALESCE(ic.ItemDesc, woi.FullDescription) AS FullDescription,
        COALESCE(ic.Category, si.Category) AS ItemCategoryName
    FROM dbo.tblWorkOrderItems woi
    INNER JOIN dbo.tblWorkOrders wo ON wo.WONumber = woi.WONumber
    LEFT JOIN dbo.tblSortlyInventory si ON si.ItemCode = woi.ItemCode
    LEFT JOIN dbo.tblWorkOrderItemCatalog ic ON ic.ItemCode = woi.ItemCode
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
                WHERE UPPER(LTRIM(RTRIM(s.value))) = UPPER(COALESCE(ic.Category, si.Category))
            )
          )
      AND (
            @IsAssigned IS NULL
            OR (@IsAssigned = 1 AND wo.AssignedToID IS NOT NULL)
            OR (@IsAssigned = 0 AND wo.AssignedToID IS NULL)
          )
      AND (
            @AssignedToID IS NULL
            OR wo.AssignedToID = @AssignedToID
          );
END;
GO

GRANT EXECUTE ON OBJECT::dbo.spWorkOrders TO [lemwolffRO];
GRANT EXECUTE ON OBJECT::dbo.spWorkOrderItems TO [lemwolffRO];
GRANT EXECUTE ON OBJECT::dbo.spWorkOrders TO [lemwolffRW];
GRANT EXECUTE ON OBJECT::dbo.spWorkOrderItems TO [lemwolffRW];
GO
