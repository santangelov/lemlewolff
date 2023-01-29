using System.IO;
using System.Data;
using System.Data.SqlClient;
using System.Data.OleDb;
using System.Configuration;
using LW_Data;
using System.Threading;
using System;
using System.Text.RegularExpressions;

namespace LW_Common
{
    public class clsSortlyHelper
    {
        public string error_message { get; set; }
        public int RowsProcessed { get; set; }

        public bool Import_Sortly_File(string FilePathAndName)
        {

            DataTable dtImport = new DataTable();

            clsUtilities.WriteToCounter("Sortly", "Starting...");

            string FolderOnly = Path.GetDirectoryName(FilePathAndName);
            string FileNameOnly = Path.GetFileName(FilePathAndName);
            //string connectionString = string.Format(@"Provider=Microsoft.ACE.OLEDB.12.0;Data Source=""{0}"";Extended Properties=""Excel 12.0 Xml;HDR=Yes;FMT=Delimited"";", FilePathAndName);
            string connectionString = string.Format(@"Provider=Microsoft.ACE.OLEDB.12.0;Data Source=""{0}"";Extended Properties=""text;HDR=Yes;FMT=Delimited"";", FolderOnly);

            DataSet ds = new DataSet("Temp");
            using (var conn = new OleDbConnection(connectionString))
            {
                conn.Open();
                OleDbDataAdapter adapter = new OleDbDataAdapter("SELECT * FROM [" + FileNameOnly + "]", conn);
                //OleDbDataAdapter adapter = new OleDbDataAdapter("SELECT * FROM [Sheet1$]", conn);
                adapter.Fill(ds);
                conn.Close();
                conn.Dispose();
            }

            DataTable sourceTable = ds.Tables[0];

            RowsProcessed = 0;
            DateTime CreateDate = DateTime.Now;
            int NumToProcess = sourceTable.Rows.Count;
            if (NumToProcess > 0)
            {
                foreach (DataRow r in sourceTable.Rows)
                {
                    // Get the WO NUmber from Folder-Level-2
                    string WONumber = r["Subfolder-level2"].ToString();
                    if (WONumber != "") { 
                        if (WONumber.Trim().ToUpper().StartsWith("WO"))
                        {
                            WONumber = Regex.Match(WONumber, @"\d{6}").Value;
                        }
                        else
                        {
                            WONumber = string.Empty;
                        }
                    }

                    clsDataHelper dh = new clsDataHelper();
                    dh.cmd.Parameters.AddWithValue("@SortlyID", r["SID"].ToString());
                    dh.cmd.Parameters.AddWithValue("@itemName", r["Entry Name"].ToString());
                    dh.cmd.Parameters.AddWithValue("@itemGroupName", r["Item Group Name"].ToString());
                    dh.cmd.Parameters.AddWithValue("@attribute1", r["Attribute 1 Option"].ToString());
                    dh.cmd.Parameters.AddWithValue("@Qty", r["Quantity"]);
                    dh.cmd.Parameters.AddWithValue("@minLevel", r["Min Level"]);
                    dh.cmd.Parameters.AddWithValue("@unitPrice", r["Price"]);
                    dh.cmd.Parameters.AddWithValue("@unitValue", r["Value"]);
                    dh.cmd.Parameters.AddWithValue("@sellPrice", r["Sell price"]);
                    dh.cmd.Parameters.AddWithValue("@Notes", r["Notes"].ToString());
                    dh.cmd.Parameters.AddWithValue("@folderLevel1", r["Primary Folder"].ToString());
                    dh.cmd.Parameters.AddWithValue("@folderLevel2", r["Subfolder-level1"].ToString());
                    dh.cmd.Parameters.AddWithValue("@folderLevel3", r["Subfolder-level2"].ToString());
                    dh.cmd.Parameters.AddWithValue("@folderLevel4", r["Subfolder-level3"].ToString());
                    dh.cmd.Parameters.AddWithValue("@QR1", r["Barcode/QR1-Data"].ToString());
                    dh.cmd.Parameters.AddWithValue("@QR2", r["Barcode/QR2-Data"].ToString());
                    dh.cmd.Parameters.AddWithValue("@QR2Type", r["Barcode/QR2-Type"].ToString());
                    dh.cmd.Parameters.AddWithValue("@PONumber", r["Purchase Order Number"].ToString());
                    dh.cmd.Parameters.AddWithValue("@WONumber", WONumber.ToString());
                    dh.cmd.Parameters.AddWithValue("@WODate", r["WO Date"].ToString());
                    dh.cmd.Parameters.AddWithValue("@CreatedBy", "User1");
                    dh.cmd.Parameters.AddWithValue("@CreateDate", CreateDate);

                    dh.cmd.Parameters.AddWithValue("@NoReturn", true);  // Force it to not return data for speed
                    bool isSuccess = dh.ExecuteSPCMD("spSortlyWorkOrderUpdate", false);
                    if (isSuccess) RowsProcessed++;
                    if (RowsProcessed % 15 == 0) clsUtilities.WriteToCounter("Sortly", RowsProcessed.ToString("#,###") + " of " + NumToProcess.ToString("#,###"));  // only update every 15 records
                }
            }
            return true;
        }

    }
}