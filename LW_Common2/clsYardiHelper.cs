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

            clsUtilities.WriteToCounter("Yardi WOs", "Starting...");

            string FolderOnly = Path.GetDirectoryName(FilePathAndName);
            string FileNameOnly = Path.GetFileName(FilePathAndName);
            string connectionString = string.Format(@"Provider=Microsoft.ACE.OLEDB.12.0;Data Source=""{0}"";Extended Properties=""text;HDR=Yes;FMT=Delimited;ImportMixedTypes=Text;MaxScanRows=0;"";", FolderOnly);

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
                    dh.cmd.Parameters.AddWithValue("@WONumber", r["WONumber"].ToString());
                    dh.cmd.Parameters.AddWithValue("@BuildingNum", r["BuildingNum"].ToString());
                    dh.cmd.Parameters.AddWithValue("@AptNum", r["AptNum"].ToString());
                    dh.cmd.Parameters.AddWithValue("@JobStatus", r["JobStatus"].ToString());
                    dh.cmd.Parameters.AddWithValue("@Category", r["Category"]);
                    dh.cmd.Parameters.AddWithValue("@CallDate", r["CallDate"]);
                    dh.cmd.Parameters.AddWithValue("@StartDate", r["StartDate"]);
                    dh.cmd.Parameters.AddWithValue("@SchedDate", r["SchedDate"]);
                    dh.cmd.Parameters.AddWithValue("@CompleteDate", r["CompleteDate"]);
                    dh.cmd.Parameters.AddWithValue("@Employee", r["Employee"]);
                    dh.cmd.Parameters.AddWithValue("@BriefDesc", r["BriefDesc"]);
                    dh.cmd.Parameters.AddWithValue("@Quantity", r["Quantity"]);
                    dh.cmd.Parameters.AddWithValue("@Code", r["Code"].ToString());
                    dh.cmd.Parameters.AddWithValue("@FullDesc", r["FullDesc"]);
                    dh.cmd.Parameters.AddWithValue("@UnitPrice", r["UnitPrice"]);
                    dh.cmd.Parameters.AddWithValue("@PayAmt", r["PayAmt"]);

                    dh.cmd.Parameters.AddWithValue("@CreatedBy", "User1");
                    dh.cmd.Parameters.AddWithValue("@CreateDate", CreateDate);

                    dh.cmd.Parameters.AddWithValue("@NoReturn", true);  // Force it to not return data for speed
                    bool isSuccess = dh.ExecuteSPCMD("spYardiWOsUpdate", false);
                    RowsProcessed++;
                    if (!isSuccess)
                    {
                        clsUtilities.WriteToCounter("YardiWO", "Error: " + dh.data_err_msg + " (" + RowsProcessed.ToString("#,###") + " of " + NumToProcess.ToString("#,###") + ")");
                        Error_Log += DateTime.Now.ToString() + ": Call Date " + r["CallDate"].ToString() + "; WO Number: " + r["WONumber"].ToString() + "; ERROR: " + dh.data_err_msg + "\r\n";
                    }
                    else
                    {
                        if (RowsProcessed % 15 == 0) clsUtilities.WriteToCounter("YardiWO", RowsProcessed.ToString("#,###") + " of " + NumToProcess.ToString("#,###"));  // only update every 15 records
                    }
                }
            }
            return true;
        }

        public bool Import_YardiPO_File(string FilePathAndName)
        {
            Error_Log = "";

            DataTable dtImport = new DataTable();

            clsUtilities.WriteToCounter("YardiPO", "Starting...");

            string FolderOnly = Path.GetDirectoryName(FilePathAndName);
            string FileNameOnly = Path.GetFileName(FilePathAndName);
            string connectionString = string.Format(@"Provider=Microsoft.ACE.OLEDB.12.0;Data Source=""{0}"";Extended Properties=""text;HDR=Yes;FMT=Delimited;ImportMixedTypes=Text;MaxScanRows=0;"";", FolderOnly);

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
                    dh.cmd.Parameters.AddWithValue("@WONumber", r["WONumber"].ToString());
                    dh.cmd.Parameters.AddWithValue("@CallDate", r["CallDate"]);
                    dh.cmd.Parameters.AddWithValue("@PONumber", r["PONumber"]);
                    dh.cmd.Parameters.AddWithValue("@VendorCode", r["VendorCode"].ToString());
                    dh.cmd.Parameters.AddWithValue("@VendorName", r["VendorName"].ToString());
                    dh.cmd.Parameters.AddWithValue("@InvoiceDate", r["InvoiceDate"]);
                    dh.cmd.Parameters.AddWithValue("@AcctCode", r["AcctCode"]);
                    dh.cmd.Parameters.AddWithValue("@AcctCategory", r["AcctCategory"]);
                    dh.cmd.Parameters.AddWithValue("@AcctDesc", r["AcctDesc"]);
                    dh.cmd.Parameters.AddWithValue("@IndivPOTotal", r["IndivPOTotal"]);
                    dh.cmd.Parameters.AddWithValue("@POAmount", r["POAmount"]);
                    dh.cmd.Parameters.AddWithValue("@WOAndInvoiceAmt", r["WOAndInvoiceAmt"]);
                    dh.cmd.Parameters.AddWithValue("@LaborPricingOutside", r["LaborPricingOutside"]);
                    dh.cmd.Parameters.AddWithValue("@expensetype", r["expensetype"]);
                    dh.cmd.Parameters.AddWithValue("@RequestedBy", r["Requested"]);
                    dh.cmd.Parameters.AddWithValue("@PODate", r["PODate"]);

                    dh.cmd.Parameters.AddWithValue("@CreatedBy", "User1");
                    dh.cmd.Parameters.AddWithValue("@CreateDate", CreateDate);

                    dh.cmd.Parameters.AddWithValue("@NoReturn", true);  // Force it to not return data for speed
                    bool isSuccess = dh.ExecuteSPCMD("spYardiPOsUpdate", false);
                    RowsProcessed++;
                    if (!isSuccess)
                    {
                        clsUtilities.WriteToCounter("YardiPO", "Error: " + dh.data_err_msg + " (" + RowsProcessed.ToString("#,###") + " of " + NumToProcess.ToString("#,###") + ")");
                        Error_Log += DateTime.Now.ToString() + ": Call Date " + r["CallDate"].ToString() + "; WO Number: " + r["WONumber"].ToString() + "; ERROR: " + dh.data_err_msg + "\r\n";
                    }
                    else
                    {
                        if (RowsProcessed % 15 == 0) clsUtilities.WriteToCounter("YardiPO", RowsProcessed.ToString("#,###") + " of " + NumToProcess.ToString("#,###"));  // only update every 15 records
                    }
                }
            }
            return true;
        }


    }
}