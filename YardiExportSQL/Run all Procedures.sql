use lemlewolff
go
	
	--delete from tblImport_ADP
	--delete from tblImport_Sortly
	--delete from tblImport_Yardi_POs
	--delete from tblImport_Yardi_WOList
	-- DELETE FROM tblMasterWOReview
	
	spRptBuilder_WOReview_01_WOs --@wonumbers=461128
	go

	spRptBuilder_WOReview_02_POs --@wonumbers=461128
	go

	spRptBuilder_WOReview_03_Labor --@wonumbers=461128
	go

	spRptBuilder_WOReview_04_SortlyFixes 
	go

	spRptBuilder_WOReview_05_Materials --@wonumbers=461128
	go

	spRptBuilder_WOReview_06_Calcs --@wonumbers=461524
	go

	--select LastName, FirstName, LWHourlyRate, LWSmJobMinRateAdj, LWOTRate, isnull(LWMaterialRate,0) as LWMaterialRate from tblLaborers order by LastName, FirstName

	--SELECT [Category], [KeyString] as [Key], [KeyValue] as [Value] FROM [tblLookupValues] ORDER BY [Category], [KeyString]

	select * from vwMasterExport_v01 ORDER BY WONumber --where wonumber=461246 --in (461882, 462124, 462126, 462515, 463191, 463355, 463946, 466699, 467401) ORDER BY WONumber




  