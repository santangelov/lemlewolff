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
using System.Runtime.InteropServices.ComTypes;
using Microsoft.Office.Interop.Excel;

namespace LW_Common
{
    using LW_Data;
    using Microsoft.Office.Interop.Excel;
    using System.Data;
    using System.Data.SqlClient;
    using Excel = Microsoft.Office.Interop.Excel;

    public sealed class clsReportHelper
    {
        public string error_message { get; set; }
        public string WarningMsg { get; set; }

        public static string WOAnalysisReportTemplatePath = "C:\\Users\\Vincent\\Source\\Repos\\lemlewolff\\LW_Web\\_Templates";
        public static string WOAnalysisReportDownloadPath = "C:\\Users\\Vincent\\Source\\Repos\\lemlewolff\\LW_Web\\_Downloads";
        public static string WOAnalysisReportTemplateFileName = "_Template - WOAnalysis_01 - MMM-MMM.xlsx";

        public bool CreateWOAnalysisReport(string NewFileName)
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

            // Read the full datatable
            clsDataHelper DH = new clsDataHelper();
            SqlCommand cmd = new SqlCommand();
            System.Data.DataTable sourcedt = DH.GetDataTableCMD("spWOAnalysisReport", ref cmd);
            int colCount = sourcedt.Columns.Count;
            int rowCount = sourcedt.Rows.Count;

            object[,] values = new object[rowCount, colCount];
            int i = 0;
            foreach (DataRow R in sourcedt.Rows)
            {
                for (int ii = 0; ii < colCount; ii++)
                {
                    if (!string.IsNullOrEmpty(R[ii].ToString())) values[i,ii] = R[ii];
                }
                i++;
            }

            Excel.Application xlApp = new Excel.Application();
            Excel.Workbook xlWorkbook = xlApp.Workbooks.Open(TargetPathAndFileName);
            Excel._Worksheet xlWorksheet = xlWorkbook.Sheets[1];
            Excel.Range xlRange = xlWorksheet.Range[xlWorksheet.Cells[2,1], xlWorksheet.Cells[rowCount+1, colCount]];  

            xlRange.Value = values;
            xlApp.Visible = false;
            xlApp.UserControl = false;
            xlWorkbook.Save();

            //cleanup
            GC.Collect();
            GC.WaitForPendingFinalizers();

            //release com objects to fully kill excel process from running in the background
            Marshal.ReleaseComObject(xlRange);
            Marshal.ReleaseComObject(xlWorksheet);

            //close and release
            xlWorkbook.Close();
            Marshal.ReleaseComObject(xlWorkbook);

            //quit and release
            xlApp.Quit();
            Marshal.ReleaseComObject(xlApp);

            return true;
        }


        //public static bool FillExcelWithData_AnalysisReport(string NewFileName)
        //{

        //    string TargetPathAndFileName = WOAnalysisReportDownloadPath + "\\" + NewFileName;

        //    // Delete any existing file of the same name
        //    try
        //    {
        //        System.IO.File.Delete(TargetPathAndFileName);
        //    }
        //    catch (Exception) { }

        //    // Copy the Template file first to the new file name
        //    System.IO.File.Copy(WOAnalysisReportTemplatePath + "\\" + WOAnalysisReportTemplateFileName, TargetPathAndFileName, true);   // Default to overwrite = true

        //    Excel.Application xlApp = new Excel.Application();
        //    Excel.Workbook xlWorkbook = xlApp.Workbooks.Open(TargetPathAndFileName);
        //    Excel._Worksheet xlWorksheet = xlWorkbook.Sheets[1];
        //    Excel.Range xlRange = xlWorksheet.UsedRange;

        //    xlWorksheet.Cells[1, 1] = txtWrite.Text;
        //    xlApp.Visible = false;
        //    xlApp.UserControl = false;
        //    xlWorkbook.Save();

        //    //cleanup
        //    GC.Collect();
        //    GC.WaitForPendingFinalizers();

        //    //release com objects to fully kill excel process from running in the background
        //    Marshal.ReleaseComObject(xlRange);
        //    Marshal.ReleaseComObject(xlWorksheet);

        //    //close and release
        //    xlWorkbook.Close();
        //    Marshal.ReleaseComObject(xlWorkbook);

        //    //quit and release
        //    xlApp.Quit();
        //    Marshal.ReleaseComObject(xlApp);
        //}

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

        /// <summary>
        /// Pass in only the file name - it ends up in the _Downloads folder
        /// </summary>
        /// <param name="NewFileName"></param>
        /// <returns></returns>
        public bool CreateWOAnalysisReport_Insert(string NewFileName)
        {
            // Delete any existing file of the same name
            try
            {
                System.IO.File.Delete(WOAnalysisReportDownloadPath + "\\" + NewFileName);
            }
            catch (Exception) { }

            // Copy the Template file first to the new file name
            System.IO.File.Copy(WOAnalysisReportTemplatePath + "\\" + WOAnalysisReportTemplateFileName, WOAnalysisReportDownloadPath + "\\" + NewFileName, true);   // Default to overwrite = true

            // Insert the data
            //write data in EXCEL sheet (Insert data)
            using (OleDbConnection conn = new OleDbConnection(clsExcelHelper.GetExcelConnectionString_RW(WOAnalysisReportDownloadPath + "\\" + NewFileName)))
            {
                // Read the full datatable
                clsDataHelper DH = new clsDataHelper();
                SqlCommand cmd = new SqlCommand();
                System.Data.DataTable sourcedt = DH.GetDataTableCMD("spWOAnalysisReport", ref cmd);

                // Loop through table
                try
                {

                    conn.Open();
                    foreach (DataRow R in sourcedt.Rows)
                    {
                        OleDbCommand cmd1 = new OleDbCommand("INSERT INTO [Results$] ([WONumber], [BuildingNum], [AptNum], [StatusYardi], [ScheduledCompletedDate], [InvoiceDate], [Call Date]," +
                            "[PostedMonth], [BatchID], [Batch Date], [Transaction batch Date], [RadDetails], [Categry], [addlWork2], [TotalEstPrice], [MetricMeasure], [MaterialFromInventCost]," +
                            "[PONumbers], [Vendors], [PurchasedMaterialCost], [TotalMaterialCost], [TotalMaterialPricing], [MaterialUnusedToInv], [LaborCost_Outside], [ContDate], [CompletedDate], " +
                            "[LaborPricing_Outside], [Laborer1_Name], [Laborer2_Name], [Laborer3_Name], [Laborer4_Name], [Laborer1_HoursReg], [Laborer2_HoursReg], [Laborer3_HoursReg], [Laborer4_HoursReg]," +
                            "[Laborer1_HoursOT], [Laborer2_HoursOT], [Laborer3_HoursOT], [Laborer4_HoursOT], [Laborer1_CostReg], [Laborer2_CostReg], [Laborer3_CostReg], [Laborer4_CostReg], [Laborer1_CostOT]," +
                            "[Laborer2_CostOT], [Laborer3_CostOT], [Laborer4_CostOT], [LaborAdjMin], [LaborAdj_OT], [LaborSupplies], [Labor_Total], [Labor_MarkUp], [TotalMaterialsLaborAndOL], [FinalSalePrice]," +
                            "[SalesTax], [InvoicePrice], [GrossProfit], [CostPlusOH], [NetProfit], [GrossProfitMargin_Pct], [NetProfitMargin_Pct] ) " +
                            "VALUES(@cellA, @cellB, @cellC, @cellD, @cellE, @cellF, @cellG, @cellH, @cellI, @cellJ, @cellK, @cellL, @cellM, @cellN, @cellO, @cellP, @cellQ, @cellR, @cellS, @cellT, @cellU, @cellV, @cellW, @cellX, @cellY, @cellZ," +
                            "@cellAA, @cellAB, @cellAC, @cellAD, @cellAE, @cellAF, @cellAG, @cellAH, @cellAI, @cellAJ, @cellAK, @cellAL, @cellAM, @cellAN, @cellAO, @cellAP, @cellAQ, @cellAR, @cellAS, @cellAT, @cellAU, @cellAV, @cellAW, @cellAX, @cellAY, @cellAZ, " + 
                            "@cellBA, @cellBB, @cellBC, @cellBD, @cellBE, @cellBF, @cellBG, @cellBH, @cellBI )"
                            , conn);
                        cmd1.Parameters.AddWithValue("@cellA", R[0]);
                        cmd1.Parameters.AddWithValue("@cellB", R[1]);
                        cmd1.Parameters.AddWithValue("@cellC", R[2]);
                        cmd1.Parameters.AddWithValue("@cellD", R[3]);
                        cmd1.Parameters.AddWithValue("@cellE", R[4]);
                        cmd1.Parameters.AddWithValue("@cellF", R[5]);
                        cmd1.Parameters.AddWithValue("@cellG", R[6]);
                        cmd1.Parameters.AddWithValue("@cellH", R[7]);
                        cmd1.Parameters.AddWithValue("@cellI", R[8]);
                        cmd1.Parameters.AddWithValue("@cellJ", R[9]);
                        cmd1.Parameters.AddWithValue("@cellK", R[10]);
                        cmd1.Parameters.AddWithValue("@cellL", R[11]);
                        cmd1.Parameters.AddWithValue("@cellM", R[12]);
                        cmd1.Parameters.AddWithValue("@cellN", R[13]);
                        cmd1.Parameters.AddWithValue("@cellO", R[14]);
                        cmd1.Parameters.AddWithValue("@cellP", R[15]);
                        cmd1.Parameters.AddWithValue("@cellQ", R[16]);
                        cmd1.Parameters.AddWithValue("@cellR", R[17]);
                        cmd1.Parameters.AddWithValue("@cellS", R[18]);
                        cmd1.Parameters.AddWithValue("@cellT", R[19]);
                        cmd1.Parameters.AddWithValue("@cellU", R[20]);
                        cmd1.Parameters.AddWithValue("@cellV", R[21]);
                        cmd1.Parameters.AddWithValue("@cellW", R[22]);
                        cmd1.Parameters.AddWithValue("@cellX", R[23]);
                        cmd1.Parameters.AddWithValue("@cellY", R[24]);
                        cmd1.Parameters.AddWithValue("@cellZ", R[25]);

                        cmd1.Parameters.AddWithValue("@cellAA", R[26]);
                        cmd1.Parameters.AddWithValue("@cellAB", R[27]);
                        cmd1.Parameters.AddWithValue("@cellAC", R[28]);
                        cmd1.Parameters.AddWithValue("@cellAD", R[29]);
                        cmd1.Parameters.AddWithValue("@cellAE", R[30]);
                        cmd1.Parameters.AddWithValue("@cellAF", R[31]);
                        cmd1.Parameters.AddWithValue("@cellAG", R[32]);
                        cmd1.Parameters.AddWithValue("@cellAH", R[33]);
                        cmd1.Parameters.AddWithValue("@cellAI", R[34]);
                        cmd1.Parameters.AddWithValue("@cellAJ", R[35]);
                        cmd1.Parameters.AddWithValue("@cellAK", R[36]);
                        cmd1.Parameters.AddWithValue("@cellAL", R[37]);
                        cmd1.Parameters.AddWithValue("@cellAM", R[38]);
                        cmd1.Parameters.AddWithValue("@cellAN", R[39]);
                        cmd1.Parameters.AddWithValue("@cellAO", R[40]);
                        cmd1.Parameters.AddWithValue("@cellAP", R[41]);
                        cmd1.Parameters.AddWithValue("@cellAQ", R[42]);
                        cmd1.Parameters.AddWithValue("@cellAR", R[43]);
                        cmd1.Parameters.AddWithValue("@cellAS", R[44]);
                        cmd1.Parameters.AddWithValue("@cellAT", R[45]);
                        cmd1.Parameters.AddWithValue("@cellAU", R[46]);
                        cmd1.Parameters.AddWithValue("@cellAV", R[47]);
                        cmd1.Parameters.AddWithValue("@cellAW", R[48]);
                        cmd1.Parameters.AddWithValue("@cellAX", R[49]);
                        cmd1.Parameters.AddWithValue("@cellAY", R[50]);
                        cmd1.Parameters.AddWithValue("@cellAZ", R[51]);

                        cmd1.Parameters.AddWithValue("@cellBA", R[52]);
                        cmd1.Parameters.AddWithValue("@cellBB", R[53]);
                        cmd1.Parameters.AddWithValue("@cellBC", R[54]);
                        cmd1.Parameters.AddWithValue("@cellBD", R[55]);
                        cmd1.Parameters.AddWithValue("@cellBE", R[56]);
                        cmd1.Parameters.AddWithValue("@cellBF", R[57]);
                        cmd1.Parameters.AddWithValue("@cellBG", R[58]);
                        cmd1.Parameters.AddWithValue("@cellBH", R[59]);
                        cmd1.Parameters.AddWithValue("@cellBI", R[60]);

                        cmd1.ExecuteNonQuery();
                        cmd1 = null;
                    }
                    conn.Close();
                    conn.Dispose();
                }
                catch (Exception ex)
                {
                    error_message = ex.Message;
                    return false;   // If there are any failures then the whole thing fails so we don't miss any rows
                }
                finally 
                {
                    conn.Close();
                    conn.Dispose();
                }

                //cleanup
                GC.Collect();
                GC.WaitForPendingFinalizers();
            }

            return true;
        }
    }
}

