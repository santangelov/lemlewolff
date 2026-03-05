USE [LemleWolff]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.spWorkOrders_AssignByWONumber
    @WONumber VARCHAR(50),
    @AssignedToID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.tblWorkOrders
    SET AssignedToID = @AssignedToID
    WHERE CONVERT(VARCHAR(50), WONumber) = @WONumber;

    SELECT @@ROWCOUNT AS RowsAffected;
END;
GO

GRANT EXECUTE ON dbo.spWorkOrders_AssignByWONumber TO lemlewolffRW;
GO
