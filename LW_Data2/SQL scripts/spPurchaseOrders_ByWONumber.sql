USE [LemleWolff]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.spPurchaseOrders_ByWONumber
    @WONumber VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT po.*
    FROM dbo.tblPurchaseOrders po
    WHERE CONVERT(VARCHAR(50), po.WONumber) = @WONumber
    ORDER BY po.PONumber;

    SELECT pod.*
    FROM dbo.tblPurchaseOrders_Details pod
    WHERE EXISTS
    (
        SELECT 1
        FROM dbo.tblPurchaseOrders po
        WHERE po.PONumber = pod.PONumber
          AND CONVERT(VARCHAR(50), po.WONumber) = @WONumber
    )
    ORDER BY pod.PONumber, pod.YardiPODetailRowID;
END;
GO

GRANT EXECUTE ON dbo.spPurchaseOrders_ByWONumber TO lemlewolffRO;
GRANT EXECUTE ON dbo.spPurchaseOrders_ByWONumber TO lemlewolffRW;
GO
