USE [LemleWolff]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.spPurchaseOrders
AS
BEGIN
    SET NOCOUNT ON;

    SELECT po.*
    FROM dbo.tblPurchaseOrders po
    ORDER BY po.PONumber;

    SELECT pod.*
    FROM dbo.tblPurchaseOrders_Details pod
    ORDER BY pod.PONumber, pod.YardiPODetailRowID;
END;
GO

GRANT EXECUTE ON dbo.spPurchaseOrders TO lemlewolffRO;
GRANT EXECUTE ON dbo.spPurchaseOrders TO lemlewolffRW;
GO
