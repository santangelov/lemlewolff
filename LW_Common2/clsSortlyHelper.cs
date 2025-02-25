using LW_Data;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.OleDb;
using System.IO;

namespace LW_Common
{
    public class clsSortlyHelper
    {
        public string error_message { get; set; }
        public int RowsProcessed { get; set; }
        public string WarningMsg { get; set; }

        public bool Import_Sortly_File(string FilePathAndName, string WorksheetName)
        {
            DataTable dtImport = new DataTable();

            clsUtilities.WriteToCounter("Sortly", "Starting...");

            string FolderOnly = Path.GetDirectoryName(FilePathAndName);
            string FileNameOnly = Path.GetFileName(FilePathAndName);
            DateTime FileCreateDate = File.GetCreationTime(FilePathAndName);

            DataSet ds = new DataSet("Temp");

            using (var conn = new OleDbConnection(clsExcelHelper.GetExcelConnectionString(FilePathAndName)))
            {
                conn.Open();
                OleDbDataAdapter adapter = new OleDbDataAdapter(string.Format("SELECT * FROM [{0}$A1:AO]", WorksheetName), conn);
                adapter.Fill(ds);
                conn.Close();
                conn.Dispose();
            }

            DataTable sourceTable = ds.Tables[0];

            DateTime CreateDate = DateTime.Now;
            int NumToProcess = sourceTable.Rows.Count;
            if (NumToProcess > 0)
            {
                // Validate the import file first - All columns are required
                string NotFoundStr = "";
                foreach (string s in new List<string> { "Entry Name", "SID", "Quantity", "Price", "Value", "Sell price", "Notes", "Primary Folder", "Subfolder-level1", "Subfolder-level2", "Subfolder-level3", "Subfolder-level4", "LANDED COST", "WO Date" })
                {
                    if (!sourceTable.Columns.Contains(s)) if (NotFoundStr == "") NotFoundStr += s; else NotFoundStr += ", " + s;
                }
                if (NotFoundStr != "")
                {
                    WarningMsg = "Sortly Import file NOT loaded. Columns not found: " + NotFoundStr;
                    return false;
                }

                // Record the Range Imported
                clsReportHelper.RecordFileDateRanges("Sortly", null, FileCreateDate);

                // Add rows
                RowsProcessed = 0;
                clsUtilities.WriteToCounter("Sortly", "0 of " + NumToProcess.ToString("#,###"));

                int rowCount = 0;
                foreach (DataRow r in sourceTable.Rows)
                {
                    rowCount++;

                    /* THe WO Number will be calculated later for Sorty data at this point - 
                     * So no WO Number will be imported now. Later we can set the WO Mumber during the import if we want. 
                     * It is in the Folder columns */

                    // Importing the Excel Sortly file. Not all columns are imported
                    // Just make sure the names of the r[] entries match the column headers

                    clsDataHelper dh = new clsDataHelper();
                    dh.cmd.Parameters.AddWithValue("@ItemName", r["Entry Name"].ToString());
                    dh.cmd.Parameters.AddWithValue("@SortlyID", r["SID"].ToString());
                    dh.cmd.Parameters.AddWithValue("@Quantity", clsFunc.CastToInt(r["Quantity"], 0));
                    dh.cmd.Parameters.AddWithValue("@unitPrice", r["Price"]);
                    dh.cmd.Parameters.AddWithValue("@TotalValue", r["Value"]);
                    dh.cmd.Parameters.AddWithValue("@sellPrice", r["Sell price"]);
                    dh.cmd.Parameters.AddWithValue("@Notes", r["Notes"].ToString());
                    dh.cmd.Parameters.AddWithValue("@PrimaryFolder", r["Primary Folder"].ToString());
                    dh.cmd.Parameters.AddWithValue("@SubFolderLevel1", r["Subfolder-level1"].ToString());
                    dh.cmd.Parameters.AddWithValue("@SubFolderLevel2", r["Subfolder-level2"].ToString());
                    dh.cmd.Parameters.AddWithValue("@SubFolderLevel3", r["Subfolder-level3"].ToString());
                    dh.cmd.Parameters.AddWithValue("@SubFolderLevel4", r["Subfolder-level4"].ToString());
                    if (r["LANDED COST"].ToString().Trim() != "") dh.cmd.Parameters.AddWithValue("@LandedCost", clsFunc.CastToDec(r["LANDED COST"], 0));
                    if (r["WO Date"].ToString().Trim() != "") dh.cmd.Parameters.AddWithValue("@WODate", r["WO Date"].ToString());  // Do not pass parameter if blank to make it NULL
                    dh.cmd.Parameters.AddWithValue("@CreatedBy", "User1");
                    dh.cmd.Parameters.AddWithValue("@CreateDate", CreateDate);

                    dh.cmd.Parameters.AddWithValue("@NoReturn", true);  // Force it to not return data for speed
                    bool isSuccess = dh.ExecuteSPCMD("spSortlyWorkOrderUpdate", false);
                    if (isSuccess) RowsProcessed++; else WarningMsg += " || row " + rowCount.ToString() + ": " + dh.data_err_msg;
                    if (RowsProcessed % 15 == 0) clsUtilities.WriteToCounter("Sortly", RowsProcessed.ToString("#,###") + " of " + NumToProcess.ToString("#,###"));  // only update every 15 records
                }

                // Run the after Stored Procedures to clean up fields
                clsDataHelper sp = new clsDataHelper();
                if (!sp.ExecuteSPCMD("spRptBuilder_WOReview_04_SortlyFixes", false)) WarningMsg += " || spRptBuilder_WOReview_04_SortlyFixes: " + sp.data_err_msg;
            }
            clsUtilities.WriteToCounter("Sortly", "Completed");
            return true;
        }

    }
}