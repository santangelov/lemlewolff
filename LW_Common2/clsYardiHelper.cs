using System.IO;
using System.Data;
using System.Data.SqlClient;
using System.Data.OleDb;
using System.Configuration;
using LW_Data;
using System.Threading;
using System;

namespace LW_Common
{
    public class clsYardiHelper
    {
        public string error_message { get; set; }
        public int RowsProcessed { get; set; }
        public string Error_Log { get; set; }

        public bool Import_YardiWO_File(string FilePathAndName)
        {
            Error_Log = "";

            DataTable dtImport = new DataTable();

            clsUtilities.WriteToCounter("Yardi", "Starting...");

            string FolderOnly = Path.GetDirectoryName(FilePathAndName);
            string FileNameOnly = Path.GetFileName(FilePathAndName);
            string connectionString = string.Format(@"Provider=Microsoft.ACE.OLEDB.12.0;Data Source=""{0}"";Extended Properties=""text;HDR=Yes;FMT=Delimited"";", FolderOnly);

            DataSet ds = new DataSet("Temp");
            using (var conn = new OleDbConnection(connectionString))
            {
                conn.Open();
                OleDbDataAdapter adapter = new OleDbDataAdapter("SELECT * FROM [" + FileNameOnly + "]", conn);
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
                    clsDataHelper dh = new clsDataHelper();
                    dh.cmd.Parameters.AddWithValue("@CallDate", r["dtCall"].ToString());
                    dh.cmd.Parameters.AddWithValue("@WONumber", r["WorkOrder"].ToString());
                    dh.cmd.Parameters.AddWithValue("@BuildingNum", r["BuildingNum"].ToString());
                    dh.cmd.Parameters.AddWithValue("@AptNum", r["AptNum"].ToString());
                    dh.cmd.Parameters.AddWithValue("@JobStatus", r["StatusPerYardi"].ToString());
                    dh.cmd.Parameters.AddWithValue("@EffectiveDate", r["EffectiveDate"]);
                    dh.cmd.Parameters.AddWithValue("@DateCompleted", r["DateCompleted"]);
                    dh.cmd.Parameters.AddWithValue("@ChargeBatchNum", r["ChargeBatchNum"]);
                    dh.cmd.Parameters.AddWithValue("@ChargeBatchID", r["ChargeBatchID"]);
                    dh.cmd.Parameters.AddWithValue("@invoiceDate", r["invoiceDate"]);
                    dh.cmd.Parameters.AddWithValue("@MonthPosted", r["MonthPosted"]);
                    dh.cmd.Parameters.AddWithValue("@Rad", r["Rad"].ToString());
                    dh.cmd.Parameters.AddWithValue("@AddlWork", r["AddlWork"].ToString());
                    dh.cmd.Parameters.AddWithValue("@JobPricingCategory", r["JobPricingCategory-Internal"].ToString());
                    dh.cmd.Parameters.AddWithValue("@Division", r["Division"].ToString());
                    dh.cmd.Parameters.AddWithValue("@PONum", r["PONum"].ToString());
                    dh.cmd.Parameters.AddWithValue("@POVendorName", r["VendorNameOnPO"].ToString());
                    dh.cmd.Parameters.AddWithValue("@VendorInvoiceAmt", r["VendorInvoiceAmt"]);
                    dh.cmd.Parameters.AddWithValue("@Total0", r["Total0"]);
                    dh.cmd.Parameters.AddWithValue("@Total1", r["Total1"]);
                    dh.cmd.Parameters.AddWithValue("@PayTranTotal", r["PayTranTotal"]);
                    dh.cmd.Parameters.AddWithValue("@ChgTranTotal", r["ChgTranTotal"]);

                    dh.cmd.Parameters.AddWithValue("@CreatedBy", "User1");
                    dh.cmd.Parameters.AddWithValue("@CreateDate", CreateDate);

                    dh.cmd.Parameters.AddWithValue("@NoReturn", true);  // Force it to not return data for speed
                    bool isSuccess = dh.ExecuteSPCMD("spYardiWOsUpdate", false);
                    RowsProcessed++;
                    if (!isSuccess)
                    {
                        clsUtilities.WriteToCounter("Yardi", "Error: " + dh.data_err_msg + " (" + RowsProcessed.ToString("#,###") + " of " + NumToProcess.ToString("#,###") + ")");
                        Error_Log += DateTime.Now.ToString() + ": Call Date " + r["dtCall"].ToString() + "; WO Number: " + r["WorkOrder"].ToString() + "; ERROR: " + dh.data_err_msg + "\r\n";
                    }
                    else
                    {
                        if (RowsProcessed % 15 == 0) clsUtilities.WriteToCounter("Yardi", RowsProcessed.ToString("#,###") + " of " + NumToProcess.ToString("#,###"));  // only update every 15 records
                    }
                }
            }
            return true;
        }

    }
}