using LW_Data;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.OleDb;
using System.IO;

namespace LW_Common
{
    public class clsGeneralImportHelper
    {
        public string error_message { get; set; }
        public int RowsProcessed { get; set; }
        public string WarningMsg { get; set; }

        public bool Import_PhysicalCounts_File(string FilePathAndName, string WorksheetName, string UserName)
        {
            DataTable dtImport = new DataTable();

            clsUtilities.WriteToCounter("PC", "Starting...");

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
                foreach (string s in new List<string> { "AsOfDate", "Code", "Quantity", "Description" })
                {
                    if (!sourceTable.Columns.Contains(s)) if (NotFoundStr == "") NotFoundStr += s; else NotFoundStr += ", " + s;
                }
                if (NotFoundStr != "")
                {
                    WarningMsg = "Import file NOT loaded. Columns not found: " + NotFoundStr;
                    return false;
                }

                // Record the Range Imported
                clsReportHelper.RecordFileDateRanges("PC", FileCreateDate);

                // Add rows
                RowsProcessed = 0;
                clsUtilities.WriteToCounter("PC", "0 of " + NumToProcess.ToString("#,###"));

                int rowCount = 0;
                foreach (DataRow r in sourceTable.Rows)
                {
                    rowCount++;

                    clsDataHelper dh = new clsDataHelper();
                    dh.cmd.Parameters.AddWithValue("@Code", r["Code"].ToString());
                    dh.cmd.Parameters.AddWithValue("@AsOfDate", r["AsOfDate"].ToString());
                    dh.cmd.Parameters.AddWithValue("@PhysicalCount", r["Quantity"].ToString());
                    dh.cmd.Parameters.AddWithValue("@Description", r["Description"].ToString());
                    dh.cmd.Parameters.AddWithValue("@CreatedBy", UserName);
                    dh.cmd.Parameters.AddWithValue("@CreateDate", CreateDate);

                    dh.cmd.Parameters.AddWithValue("@NoReturn", true);  // Force it to not return data for speed
                    bool isSuccess = dh.ExecuteSPCMD("spPhysicalInventoryUpdate", false);
                    if (isSuccess) RowsProcessed++; else WarningMsg += " || row " + rowCount.ToString() + ": " + dh.data_err_msg;
                    if (RowsProcessed % 15 == 0) clsUtilities.WriteToCounter("PC", RowsProcessed.ToString("#,###") + " of " + NumToProcess.ToString("#,###"));  // only update every 15 records
                }
            }
            clsUtilities.WriteToCounter("PC", "Completed");
            return true;
        }

    }
}
