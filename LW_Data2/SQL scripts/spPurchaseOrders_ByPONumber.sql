USE [LemleWolff]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.spPurchaseOrders_ByPONumber
    @PONumber VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT po.*
    FROM dbo.tblPurchaseOrders po
    WHERE po.PONumber = @PONumber
    ORDER BY po.PONumber;

    SELECT pod.*
    FROM dbo.tblPurchaseOrders_Details pod
    WHERE pod.PONumber = @PONumber
    ORDER BY pod.PONumber, pod.YardiPODetailRowID;
END;
GO

GRANT EXECUTE ON dbo.spPurchaseOrders_ByPONumber TO lemlewolffRO;
GRANT EXECUTE ON dbo.spPurchaseOrders_ByPONumber TO lemlewolffRW;
GO
