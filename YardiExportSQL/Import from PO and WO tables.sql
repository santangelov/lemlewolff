

INSERT INTO [tblImport_Inv_Yardi_POItems] 
	([PONumber], [WONumber], [VendorCode], [QtyOrdered], [UnitPrice], 
	[TotalCost], [OrderDate], [ReceivedDate], [ItemCode], [ItemDesc])
SELECT 
	[PONumber], [WONumber], [vendorCode], [iQtyOrdered], [dUnitPrice], 
	[dTotalCost], [dtordereddate], [dtReceivedDate], [stkcode], [sDesc]
FROM PO


INSERT INTO [dbo].[tblImport_Inv_Yardi_WOItems]
	([WONumber], [Category], [BriefDesc], [ItemCode], [ItemDesc], [Qty], [UnitPrice], [TotalAmt], [CompleteDate])
SELECT
	[WONumber], [Category], [BriefDesc], [ItemCode], [ItemDesc], [Qty], [UnitPrice], [TotalAmt], [CompleteDate]
FROM WO