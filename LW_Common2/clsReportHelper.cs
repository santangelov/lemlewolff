using System;
using System.Data;

namespace LW_Common
{
    using LW_Data;
    using System.Data;
    using System.Data.SqlClient;
    using System.Web.Hosting;
    using DataTable = DataTable;
    using Excel = Microsoft.Office.Interop.Excel;

    public sealed class clsReportHelper
    {
        public string error_message { get; set; }
        public string WarningMsg { get; set; }

        public static string TemplatePath = HostingEnvironment.ApplicationPhysicalPath + "_Templates";   // C:\\Users\\Vincent\\Source\\Repos\\lemlewolff\\LW_Web
        public static string WOAnalysisReportDownloadPath = HostingEnvironment.ApplicationPhysicalPath + "_Downloads";
        public static string WOAnalysisReportTemplateFileName = "_Template - WOAnalysis_01 - MMM-MMM.xlsm";
        public static string POInventoryItemReviewReportTemplateFileName = "_Template - InvItemReview.xlsx";
        public static string InventoryReportTemplateFileName_Pivot = "_Template - Inventory Daily Pivot_WithDollars.xlsx";
        public static string VacancyCoverSheetFileName = "_Template - VacancyCoverSheet.xlsx";

        public static bool RecordFileDateRanges(string DateKey, DateTime? Date1, DateTime Date2)
        {
            // Grab the Date Range columns for the record
            clsDataHelper H = new clsDataHelper();
            H.cmd.Parameters.AddWithValue("@DateKey", DateKey);
            if (Date1 != null) { H.cmd.Parameters.AddWithValue("@LatestImportDateRange_Date1", Date1); }
            H.cmd.Parameters.AddWithValue("@LatestImportDateRange_Date2", Date2);
            return H.ExecuteSPCMD("spImportDatesUpdate", true, true);
        }

        public class clsImportDateRange
        {
            public string DateKey { get; set; } = "";
            public string Date1 { get; set; } = "";
            public string Date2 { get; set; } = "";
            public string DateRangeAsString { get; set; } = "";
        }

        public static clsImportDateRange GetFileDateRangeValues(string DateKey)
        {
            // Grab the Date Range columns for the record
            clsDataHelper H = new clsDataHelper();
            H.cmd.Parameters.AddWithValue("@DateKey", DateKey);
            DataRow r = H.GetDataRow("spImportDates");

            clsImportDateRange retObj = new clsImportDateRange();
            retObj.DateKey = DateKey;
            if (r is null) { retObj.DateRangeAsString = "No record."; return retObj; }

            if (r["LatestImportDateRange_Date1"] != null) { retObj.Date1 = clsFunc.CastToStr(r["LatestImportDateRange_Date1"]); }
            retObj.Date2 = clsFunc.CastToStr(r["LatestImportDateRange_Date2"]);

            retObj.DateRangeAsString = clsFunc.CastToDateTime(r["LatestImportDateRange_Date2"], new DateTime(1900, 1, 1)).ToString("M/d/yy");

            return retObj;
        }


        public bool FillExcel_POInventoryItemReviewReport(string NewFileName, string StartDate, string EndDate)
        {
            // Run Pre-Processing of data
            if (!RunAllReportSQL()) { return false; }

            string TargetPathAndFileName = WOAnalysisReportDownloadPath + "\\" + NewFileName;

            // Delete any existing file of the same name
            try
            {
                System.IO.File.Delete(TargetPathAndFileName);
            }
            catch (Exception) { }

            // Copy the Template file first to the new file name
            System.IO.File.Copy(TemplatePath + "\\" + POInventoryItemReviewReportTemplateFileName, TargetPathAndFileName, true);   // Default to overwrite = true

            Excel.Application xlApp = new Excel.Application();
            xlApp.Visible = false;
            xlApp.UserControl = false;
            Excel.Workbook xlWorkbook = xlApp.Workbooks.Open(TargetPathAndFileName);

            clsExcelHelper E = new clsExcelHelper();
            SqlCommand cmd = new SqlCommand();
            cmd.Parameters.AddWithValue("@date1", StartDate);
            cmd.Parameters.AddWithValue("@date2", EndDate);

            //  PAGE 1. Fill in the full report
            E.FillExcelRangeFromSP(ref xlWorkbook, "spPOInventoryItemReport", 1, 2, 1, cmd);

            // Close Excel Session
            E.CleanUpExcelSession(ref xlApp, ref xlWorkbook, TargetPathAndFileName);

            return true;
        }

        public bool FillExcel_WOAnalysisReport(string NewFileName, string StartDate, string EndDate)
        {
            // Run Pre-Processing of data
            if (!RunAllReportSQL()) { return false; }

            string TargetPathAndFileName = WOAnalysisReportDownloadPath + "\\" + NewFileName;

            // Delete any existing file of the same name
            try
            {
                System.IO.File.Delete(TargetPathAndFileName);
            }
            catch (Exception) { }

            // Copy the Template file first to the new file name
            System.IO.File.Copy(TemplatePath + "\\" + WOAnalysisReportTemplateFileName, TargetPathAndFileName, true);   // Default to overwrite = true

            Excel.Application xlApp = new Excel.Application();
            xlApp.Visible = false;
            xlApp.UserControl = false;
            Excel.Workbook xlWorkbook = xlApp.Workbooks.Open(TargetPathAndFileName);

            clsExcelHelper E = new clsExcelHelper();
            SqlCommand cmd = new SqlCommand();
            cmd.Parameters.AddWithValue("@date1", StartDate);
            cmd.Parameters.AddWithValue("@date2", EndDate);

            //  PAGE 1. Fill in the full report
            E.FillExcelRangeFromSP(ref xlWorkbook, "spWOAnalysisReport", 1, 2, 1, cmd);

            //  PAGE 2. Fill in the Laborers Tab
            E.FillExcelRangeFromSP(ref xlWorkbook, "spWOAnalysisReport_Labor", 2, 2, 1, cmd);

            //  PAGE 3. Fill in the Summary Reports Tab
            E.FillExcelRangeFromSP(ref xlWorkbook, "spWOAnalysisReport_LaborerTeamSubtotals", 3, 2, 1, cmd);

            //  PAGE 2. Fill in the Lookup Table: Laborers
            E.FillExcelRangeFromSP(ref xlWorkbook, "spWOAnalysisReport_Lookup_Laborers", 4, 3, 1);

            //  PAGE 3. Fill in the Lookup Table: Lookup Values
            E.FillExcelRangeFromSP(ref xlWorkbook, "spWOAnalysisReport_LookupValues", 4, 3, 9);

            //  PAGE 4. Fill in WO Numbers in the ADP import, but 
            E.FillExcelRangeFromSP(ref xlWorkbook, "spADP_MissingFromAnalysisReport", 6, 2, 1, cmd);

            //  PAGE 5. Bonus Stats
            clsDataHelper dh = new clsDataHelper();
            DataSet ds = dh.GetDataSetCMD("spBonusReport", ref cmd);
            DataTable dt = ds.Tables[0];
            E.FillExcelRangeFromDT(ref xlWorkbook, ref dt, 7, 2, 1);
            dt = ds.Tables[1];
            E.FillExcelRangeFromDT(ref xlWorkbook, ref dt, 7, 2, 10);

            // Close Excel Session
            E.CleanUpExcelSession(ref xlApp, ref xlWorkbook, TargetPathAndFileName);

            return true;
        }

        public bool FillExcel_InventoryDailyPivotReport(string NewFileName, string StartDate, string EndDate)
        {
            // Run the pre-processing of data
            if (!RunAllReportSQL()) { return false; }

            string TargetPathAndFileName = WOAnalysisReportDownloadPath + "\\" + NewFileName;

            // Delete any existing file of the same name
            try
            {
                System.IO.File.Delete(TargetPathAndFileName);
            }
            catch (Exception) { }

            // Copy the Template file first to the new file name
            System.IO.File.Copy(TemplatePath + "\\" + InventoryReportTemplateFileName_Pivot, TargetPathAndFileName, true);   // Default to overwrite = true

            clsExcelHelper E = new clsExcelHelper();
            Excel.Application xlApp = new Excel.Application();
            xlApp.Visible = false;
            xlApp.UserControl = false;
            Excel.Workbook xlWorkbook = xlApp.Workbooks.Open(TargetPathAndFileName);

            bool retVal = true;

            try
            {

                // Set the parameters for the stored procedure
                SqlCommand cmd = new SqlCommand();
                cmd.Parameters.AddWithValue("@StartDate", StartDate);
                cmd.Parameters.AddWithValue("@EndDate", EndDate);

                // Run the one Stored Procedure, and it returns a number of tables
                DataSet ds = new DataSet();
                clsDataHelper DH = new clsDataHelper();
                ds = DH.GetDataSetCMD("spRptBuilder_Inventory_PivotByDay", ref cmd);

                // Pass in each table to fill in the worksheets
                System.Data.DataTable dt = new System.Data.DataTable();

                // Sheet: Summary,  Dates
                dt = ds.Tables[0];
                E.FillExcelRangeFromDT(ref xlWorkbook, ref dt, 1, 2, 1);

                // Sheet: Summary,  Totals
                dt = ds.Tables[1];
                E.FillExcelRangeFromDT(ref xlWorkbook, ref dt, 1, 5, 1);

                // Sheet: Detail Data
                dt = ds.Tables[2];
                E.FillExcelRangeFromDT(ref xlWorkbook, ref dt, 2, 4, 1);   // Details
                int numTotalColumns = E.FillExcelHeadersFromDT(ref xlWorkbook, ref dt, 2, 1, 1);   // Header
                int columnCopyFrom = 8;   // Column number that has the formula to copy across - nothing else needs to be set below
                E.CopyExcelRange(ref xlWorkbook, 2, 2, columnCopyFrom, 2, columnCopyFrom + 1, 2, numTotalColumns);  // ROW 2; Categories for Work Orders formula - copy across sheet
                E.CopyExcelRange(ref xlWorkbook, 2, 3, columnCopyFrom, 3, columnCopyFrom + 1, 3, numTotalColumns);  // ROW 3; Names Formula: copy the cell with the formula (H8) across all further columns

                // Return to Cell A1
                xlApp.Goto(xlWorkbook.Sheets[2].Range("A1"));

                // Sheet: Full Inventory  (separate stored procedure)
                clsDataHelper DH2 = new clsDataHelper();
                DataSet DS2 = new DataSet();
                DH2.cmd.Parameters.AddWithValue("@EndDate", EndDate);
                DS2 = DH2.GetDataSetCMD("spRptBuilder_Inventory_FullInventory", ref DH2.cmd);
                System.Data.DataTable dt2 = new System.Data.DataTable();

                // --- Inventory - Date Headers
                dt2 = DS2.Tables[0];
                E.FillExcelRangeFromDT(ref xlWorkbook, ref dt2, 3, 1, 11);  // Fill in the Headers with the past 6 months

                // --- Full Inventory Data with Turnover
                dt2 = DS2.Tables[1];
                E.FillExcelRangeFromDT(ref xlWorkbook, ref dt2, 3, 2, 1);  // Fill in the Full Inventory data with the turnover data

                // Sheet: Labor
                dt = ds.Tables[3];
                E.FillExcelRangeFromDT(ref xlWorkbook, ref dt, 4, 2, 1);

                // Sheet: Vendors
                dt = ds.Tables[4];
                E.FillExcelRangeFromDT(ref xlWorkbook, ref dt, 5, 2, 1);

                // Sheet: Exceptions
                dt = ds.Tables[5];
                E.FillExcelRangeFromDT(ref xlWorkbook, ref dt, 6, 2, 1);
            }
            catch (Exception)
            {
                retVal = false;
            }
            finally
            {
                // Close Excel Session if there is an exception or just con completion
                E.CleanUpExcelSession(ref xlApp, ref xlWorkbook, TargetPathAndFileName);
            }

            return retVal;
        }

        public bool FillExcel_VacancyCoverSheet(string NewFileName, string BuildingCode, string AptNumber)
        {
            //// Run Pre-Processing of data
            //if (!RunAllReportSQL()) { return false; }

            string TargetPathAndFileName = WOAnalysisReportDownloadPath + "\\" + NewFileName;

            // Delete any existing file of the same name
            try
            {
                System.IO.File.Delete(TargetPathAndFileName);
            }
            catch (Exception) { }

            // Copy the Template file first to the new file name
            System.IO.File.Copy(TemplatePath + "\\" + VacancyCoverSheetFileName, TargetPathAndFileName, true);   // Default to overwrite = true

            Excel.Application xlApp = new Excel.Application();
            xlApp.Visible = false;
            xlApp.UserControl = false;
            Excel.Workbook xlWorkbook = xlApp.Workbooks.Open(TargetPathAndFileName);

            clsDataHelper D = new clsDataHelper();
            D.cmd.Parameters.AddWithValue("@buildingCode", BuildingCode);
            D.cmd.Parameters.AddWithValue("@aptNumber", AptNumber);
            DataRow r = D.GetDataRow("spRptBuilder_Vacancy_Cover");
            DataTable dt = D.GetDataTable("spRptBuilder_Vacancy_Cover_pt2");  // The parameters are still the same as above
            
            if (r is null) { error_message = "Property Not Found with included Units."; return false; }

            //  TOP OF COVER SHEET
            clsExcelHelper E = new clsExcelHelper();
            E.FillExcelCellFromValue(ref xlWorkbook, 1, 1, 1, "Date: " + DateTime.Now.ToString("MM/dd/yyyy"));
            E.FillExcelCellFromValue(ref xlWorkbook, 1, 4, 2, r["BuildingCode"].ToString() + (r["unitCount"].ToString() == "" ? "" : " (" + r["unitCount"].ToString() + " units)"));
            E.FillExcelCellFromValue(ref xlWorkbook, 1, 6, 2, r["fullAddress_calc"]);
            E.FillExcelCellFromValue(ref xlWorkbook, 1, 8, 2, r["aptNumber"].ToString());
            E.FillExcelCellFromValue(ref xlWorkbook, 1, 8, 3, r["statusBasedOnDates"]);
            E.FillExcelCellFromValue(ref xlWorkbook, 1, 10, 2, r["Bedrooms"].ToString());
            E.FillExcelCellFromValue(ref xlWorkbook, 1, 10, 3, r["unitTypeDesc"]);
            E.FillExcelCellFromValue(ref xlWorkbook, 1, 12, 2, r["yearsOccupied"]);
            E.FillExcelCellFromValue(ref xlWorkbook, 1, 12, 3, r["UnitStatus"]);
            E.FillExcelCellFromValue(ref xlWorkbook, 1, 14, 2, r["LastTenantRent"]);

            //  BOTTOM PORTION OF COVER SHEET
            int startRow = 26;
            int i = 0;
            foreach(DataRow dr in dt.Rows)
            {
                E.FillExcelCellFromValue(ref xlWorkbook, 1, startRow + i, 1, dr["Category"]);
                E.FillExcelCellFromValue(ref xlWorkbook, 1, startRow + i, 2, dr["SumOfInvoicePrice"]);
                E.FillExcelCellFromValue(ref xlWorkbook, 1, startRow + i, 3, dr["WONumbers"]);
                i++;
            }

            // Close Excel Session
            E.CleanUpExcelSession(ref xlApp, ref xlWorkbook, TargetPathAndFileName);

            return true;
        }


        public static bool RunAllReportSQL_Public()
        {
            return RunAllReportSQL();
        }

        private static bool RunAllReportSQL()
        {
            bool isSuccess = true;

            clsDataHelper dh = new clsDataHelper();

            // INVENTORY REPORT FOCUSED
            //clsUtilities.WriteToCounter("MaintenanceMsg", "1: Importing Any Inventory Data...");
            if (isSuccess) isSuccess = dh.ExecuteSPCMD("spRptBuilder_Inventory_01_Import", true);

            // WO ANALYTICS REPORT FOCUSED
            //clsUtilities.WriteToCounter("MaintenanceMsg", "1: Processing WOs...");
            if (isSuccess) isSuccess = dh.ExecuteSPCMD("spRptBuilder_WOReview_01_WOs", true, true);

            //clsUtilities.WriteToCounter("MaintenanceMsg", "2: Processing POs...");
            if (isSuccess) isSuccess = dh.ExecuteSPCMD("spRptBuilder_WOReview_02_POs", true, true);

            //clsUtilities.WriteToCounter("MaintenanceMsg", "3: Processing Labor...");
            if (isSuccess) isSuccess = dh.ExecuteSPCMD("spRptBuilder_WOReview_03_Labor", true, true);

            //clsUtilities.WriteToCounter("MaintenanceMsg", "4: Processing Sortly Fixes...");
            if (isSuccess) isSuccess = dh.ExecuteSPCMD("spRptBuilder_WOReview_04_SortlyFixes", true, true);

            //clsUtilities.WriteToCounter("MaintenanceMsg", "5: Processing Materials...");
            if (isSuccess) isSuccess = dh.ExecuteSPCMD("spRptBuilder_WOReview_05_Materials", true, true);

            //clsUtilities.WriteToCounter("MaintenanceMsg", "6: Processing Final Calcs...");
            if (isSuccess) isSuccess = dh.ExecuteSPCMD("spRptBuilder_WOReview_06_Calcs", true, true);

            return isSuccess;
        }

    }
}

