USE [LemleWolff]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

;WITH src AS
(
    SELECT * FROM (VALUES
    ('02-00100','02-00100','Labor'),('02-00101','02-00101','Labor'),('02-00102','02-00102','Labor'),('02-00103','02-00103','Labor'),('02-00104','02-00104','Labor'),
    ('02-00105','02-00105','Labor'),('02-00106','02-00106','Labor'),('02-00107','02-00107','Labor'),('02-00108','02-00108','Labor'),('02-00109','02-00109','Labor'),
    ('02-00110','02-00110','Additional'),('02-00111','02-00111','Additional'),('02-00112','02-00112','Additional'),('02-00113','02-00113','Additional'),('02-00114','02-00114','Additional'),
    ('02-00115','02-00115','Additional'),('02-00116','02-00116','Additional'),('02-00117','02-00117','Additional'),('02-00118','02-00118','Additional'),('02-00119','02-00119','Additional'),
    ('02-00120','02-00120','Material'),('02-00121','02-00121','Material'),('02-00122','02-00122','Material'),('02-00123','02-00123','Material'),('02-00124','02-00124','Material'),
    ('02-00125','02-00125','Material'),('02-00126','02-00126','Material'),('02-00127','02-00127','Material'),('02-00128','02-00128','Material'),('02-00129','02-00129','Material'),
    ('02-00130','02-00130','Equipment'),('02-00131','02-00131','Equipment'),('02-00132','02-00132','Equipment'),('02-00133','02-00133','Equipment'),('02-00134','02-00134','Equipment'),
    ('02-00135','02-00135','Equipment'),('02-00136','02-00136','Equipment'),('02-00137','02-00137','Equipment'),('02-00138','02-00138','Equipment'),('02-00139','02-00139','Equipment')
    ) v(ItemCode, ItemDesc, Category)
)
MERGE dbo.tblWorkOrderItemCatalog AS tgt
USING src
   ON tgt.ItemCode = src.ItemCode
WHEN MATCHED THEN
   UPDATE SET tgt.ItemDesc = src.ItemDesc, tgt.Category = src.Category, tgt.IsActive = 1
WHEN NOT MATCHED BY TARGET THEN
   INSERT (ItemCode, ItemDesc, Category, IsActive)
   VALUES (src.ItemCode, src.ItemDesc, src.Category, 1);
GO
