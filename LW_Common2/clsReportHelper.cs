using System;
using System.Collections;
using System.Collections.Generic;
using System.Data;
using System.Data.OleDb;
using System.Data.SqlClient;
using System.Linq;
using System.Resources;
using System.Runtime.ConstrainedExecution;
using System.Text;
using System.Threading.Tasks;
using LW_Data;
using System.Runtime.InteropServices;
using System.IO;

namespace LW_Common
{
    using LW_Data;
    using Microsoft.Office.Interop.Excel;
    using System.Data;
    using System.Data.SqlClient;
    using System.Web.Hosting;
    using Excel = Microsoft.Office.Interop.Excel;

    public sealed class clsReportHelper
    {
        public string error_message { get; set; }
        public string WarningMsg { get; set; }

        public static string WOAnalysisReportTemplatePath = HostingEnvironment.ApplicationPhysicalPath + "_Templates";   // C:\\Users\\Vincent\\Source\\Repos\\lemlewolff\\LW_Web
        public static string WOAnalysisReportDownloadPath = HostingEnvironment.ApplicationPhysicalPath + "_Downloads";
        public static string WOAnalysisReportTemplateFileName = "_Template - WOAnalysis_01 - MMM-MMM.xlsx";

        public bool FillExcel_WOAnalysisReport(string NewFileName)
        {
            string TargetPathAndFileName = WOAnalysisReportDownloadPath + "\\" + NewFileName;

            // Delete any existing file of the same name
            try
            {
                System.IO.File.Delete(TargetPathAndFileName);
            }
            catch (Exception) { }

            // Copy the Template file first to the new file name
            System.IO.File.Copy(WOAnalysisReportTemplatePath + "\\" + WOAnalysisReportTemplateFileName, TargetPathAndFileName, true);   // Default to overwrite = true

            Excel.Application xlApp = new Excel.Application();
            xlApp.Visible = false;
            xlApp.UserControl = false;
            Excel.Workbook xlWorkbook = xlApp.Workbooks.Open(TargetPathAndFileName);

            clsExcelHelper E = new clsExcelHelper();

            //  PAGE 1. Fill in the full report
            E.FillExcelRangeFromSP(ref xlWorkbook, "spWOAnalysisReport", 1, 2, 1);

            //  PAGE 2. Fill in the Laborers
            E.FillExcelRangeFromSP(ref xlWorkbook, "spLaborers", 2, 3, 1);

            //  PAGE 3. Fill in the Lookup Values
            E.FillExcelRangeFromSP(ref xlWorkbook, "spLookupValues", 2, 3, 8);

            //  PAGE 4. Fill in WO Numbers in the ADP import, but 
            E.FillExcelRangeFromSP(ref xlWorkbook, "spADP_MissingFromAnalysisReport", 4, 2, 1);

            // Close Excel Session
            E.CleanUpExcelSession(ref xlApp, ref xlWorkbook, TargetPathAndFileName);

            return true;
        }

        public static bool RunAllReportSQL()
        {
            // Clear out the results table first
            clsDataHelper dh1 = new clsDataHelper();
            dh1.cmd.Parameters.AddWithValue("@FileType", "master");
            dh1.ExecuteSPCMD("spImport_Delete");

            clsDataHelper dh = new clsDataHelper();
            bool isSuccess = true;

            //clsUtilities.WriteToCounter("MaintenanceMsg", "1: Processing WOs...");
            if (isSuccess) isSuccess = dh.ExecuteSPCMD("spRptBuilder_WOReview_01_WOs", true);

            //clsUtilities.WriteToCounter("MaintenanceMsg", "2: Processing POs...");
            if (isSuccess) isSuccess = dh.ExecuteSPCMD("spRptBuilder_WOReview_02_POs", true);

            //clsUtilities.WriteToCounter("MaintenanceMsg", "3: Processing Labor...");
            if (isSuccess) isSuccess = dh.ExecuteSPCMD("spRptBuilder_WOReview_03_Labor", true);

            //clsUtilities.WriteToCounter("MaintenanceMsg", "4: Processing Sortly Fixes...");
            if (isSuccess) isSuccess = dh.ExecuteSPCMD("spRptBuilder_WOReview_04_SortlyFixes", true);

            //clsUtilities.WriteToCounter("MaintenanceMsg", "5: Processing Materials...");
            if (isSuccess) isSuccess = dh.ExecuteSPCMD("spRptBuilder_WOReview_05_Materials", true);

            //clsUtilities.WriteToCounter("MaintenanceMsg", "6: Processing Final Calcs...");
            if (isSuccess) isSuccess = dh.ExecuteSPCMD("spRptBuilder_WOReview_06_Calcs", true);

            //clsUtilities.WriteToCounter("MaintenanceMsg", "7: DONE");

            return isSuccess;
        }


    }
}

