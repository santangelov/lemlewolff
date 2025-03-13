using LW_Data;
using System;
using System.Data;
using System.Data.OleDb;
using System.IO;
using System.Linq;

namespace LW_Common
{
    public class clsYardiHelper
    {
        public string error_message { get; set; }
        public int RowsProcessed { get; set; }
        public string Error_Log { get; set; }

        /// <summary>
        /// Import WOs for the Inventory Report. Used for Importing ySQL Yardi File #3
        /// </summary>
        /// <param name="FilePathAndName"></param>
        /// <returns></returns>
        public bool Import_YardiWO_InventoryFile(string FilePathAndName)
        {
            Error_Log = "";

            System.Data.DataTable dtImport = new System.Data.DataTable();

            clsUtilities.WriteToCounter("YardiWO2", "Starting...");

            // Always delete contents of temp table first
            clsDataHelper dh1 = new clsDataHelper();
            dh1.cmd.Parameters.AddWithValue("@FileType", "InventoryWO");
            dh1.ExecuteSPCMD("spImport_Delete");

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

            System.Data.DataTable sourceTable = ds.Tables[0];

            RowsProcessed = 0;
            DateTime CreateDate = DateTime.Now;
            int NumToProcess = sourceTable.Rows.Count;
            if (NumToProcess > 0)
            {
                clsReportHelper.RecordFileDateRanges("YardiWO_Inventory", clsFunc.CastToDateTime(sourceTable.Rows[0]["Date1"], new DateTime(1900, 1, 1)), clsFunc.CastToDateTime(sourceTable.Rows[0]["Date2"], new DateTime(1900, 1, 1)));

                foreach (DataRow r in sourceTable.Rows)
                {
                    clsDataHelper dh = new clsDataHelper();
                    dh.cmd.Parameters.AddWithValue("@WONumber", r["WONumber"].ToString());
                    dh.cmd.Parameters.AddWithValue("@Category", r["Category"]);
                    dh.cmd.Parameters.AddWithValue("@BriefDesc", r["BriefDesc"]);
                    dh.cmd.Parameters.AddWithValue("@ItemCode", r["ItemCode"]);
                    dh.cmd.Parameters.AddWithValue("@ItemDesc", r["ItemDesc"]);
                    dh.cmd.Parameters.AddWithValue("@Qty", r["Qty"]);
                    dh.cmd.Parameters.AddWithValue("@UnitPrice", r["UnitPrice"]);
                    dh.cmd.Parameters.AddWithValue("@TotalAmt", r["TotalAmt"]);
                    dh.cmd.Parameters.AddWithValue("@CompleteDate", r["CompleteDate"]);
                    dh.cmd.Parameters.AddWithValue("@Vendor", r["Vendor"]);
                    dh.cmd.Parameters.AddWithValue("@Client", r["Client"]);

                    bool isSuccess = dh.ExecuteSPCMD("spYardiWOsInvItemsUpdate", false);   // Importing to tblImport_Inv_Yardi_WOItems
                    RowsProcessed++;
                    if (!isSuccess)
                    {
                        clsUtilities.WriteToCounter("YardiWO2", "Error: " + dh.data_err_msg + " (" + RowsProcessed.ToString("#,###") + " of " + NumToProcess.ToString("#,###") + ")");
                        Error_Log += DateTime.Now.ToString() + ": Item Code " + r["ItemCode"].ToString() + "; WO Number: " + r["WONumber"].ToString() + "; ERROR: " + dh.data_err_msg + "\r\n";
                    }
                    else
                    {
                        if (RowsProcessed % 15 == 0) clsUtilities.WriteToCounter("YardiWO2", RowsProcessed.ToString("#,###") + " of " + NumToProcess.ToString("#,###"));  // only update every 15 records
                    }
                }
            }

            if (RowsProcessed == 5000)
            {
                Error_Log += DateTime.Now.ToString() + ": <span style='color:Orange;'>WARNING: Exactly 5000 rows were imported. This could indicate that you had filtering on to limit the export to the first 5000 rows. This import was completed, however , please check your export to insure filtering in Yardi allows unlimited rows.</span>\r\n";
            }

            clsUtilities.WriteToCounter("YardiWO2", "Completed");
            return true;
        }

        /// <summary>
        /// Import POs for the Inventory Report (tblImport_Inv_Yardi_POItems). It also updates tblWorkOrders with some vendor info
        /// </summary>
        /// <param name="FilePathAndName"></param>
        /// <returns></returns>
        public bool Import_YardiPO_InventoryFile(string FilePathAndName)  // Import ySQL File #4 
        {
            Error_Log = "";

            System.Data.DataTable dtImport = new System.Data.DataTable();

            clsUtilities.WriteToCounter("YardiPO2", "Starting...");

            // Always delete contents of temp table first
            clsDataHelper dh1 = new clsDataHelper();
            dh1.cmd.Parameters.AddWithValue("@FileType", "InventoryPO");
            dh1.ExecuteSPCMD("spImport_Delete");

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

            System.Data.DataTable sourceTable = ds.Tables[0];

            RowsProcessed = 0;
            DateTime CreateDate = DateTime.Now;
            int NumToProcess = sourceTable.Rows.Count;
            if (NumToProcess > 0)
            {
                clsReportHelper.RecordFileDateRanges("YardiPO_Inventory", clsFunc.CastToDateTime(sourceTable.Rows[0]["Date1"], new DateTime(1900, 1, 1)), clsFunc.CastToDateTime(sourceTable.Rows[0]["Date2"], new DateTime(1900, 1, 1)));

                foreach (DataRow r in sourceTable.Rows)
                {
                    clsDataHelper dh = new clsDataHelper();
                    dh.cmd.Parameters.AddWithValue("@YardiMM2PODetID", r["YardiMM2PODetID"]);
                    dh.cmd.Parameters.AddWithValue("@PONumber", r["PONumber"].ToString());
                    dh.cmd.Parameters.AddWithValue("@WONumber", r["WONumber"].ToString());
                    dh.cmd.Parameters.AddWithValue("@vendor", r["vendor"]);
                    dh.cmd.Parameters.AddWithValue("@QtyOrdered", r["QtyOrdered"]);
                    dh.cmd.Parameters.AddWithValue("@ExpenseType", r["ExpenseType"]);
                    dh.cmd.Parameters.AddWithValue("@UnitPrice", r["UnitPrice"]);
                    dh.cmd.Parameters.AddWithValue("@TotalCost", r["TotalCost"]);
                    dh.cmd.Parameters.AddWithValue("@OrderDate", r["OrderDate"]);
                    dh.cmd.Parameters.AddWithValue("@ReceivedDate", r["ReceivedDate"]);
                    dh.cmd.Parameters.AddWithValue("@ItemCode", r["ItemCode"]);
                    dh.cmd.Parameters.AddWithValue("@ItemDesc", r["ItemDesc"]);
                    dh.cmd.Parameters.AddWithValue("@Client", r["Client"]);
                    dh.cmd.Parameters.AddWithValue("@VendorCode", r["VendorCode"]);
                    dh.cmd.Parameters.AddWithValue("@POAmount", r["POAmount"]);
                    dh.cmd.Parameters.AddWithValue("@WOAndInvoiceAmt", r["WOAndInvoiceAmt"]);


                    bool isSuccess = true;

                    // Import into the PO Items Table (tblPurchaseOrderItems which holds ALL items, good or bad, from the PO)
                    // Later we can get rid of the exceptions table and only report on the ALL ITEMS table

                    // Capture Exceptions for the PO Exception Table
                    //  1. Item Code = "material%"

                    if (r["ItemCode"].ToString().ToLower().Contains("material"))
                    {
                        isSuccess = dh.ExecuteSPCMD("spPurchaseOrderItems_ExceptionsUpdate", false);   // Importing to tblImport_Inv_Yardi_POItems_Exception table
                    }

                    /* Start importing all into tblImport_Inv_Yardi_POItems even with Materials even though we are filling up the Exceptions table */
                    if (isSuccess) isSuccess = dh.ExecuteSPCMD("spYardiPOsInvItemsUpdate", false);   // Importing to tblImport_Inv_Yardi_POItems 
                    if (isSuccess) isSuccess = dh.ExecuteSPCMD("spYardiPODetailsUpdate", false);     // Importing PO data into tblPurchaseOrders_Details

                    RowsProcessed++;

                    if (!isSuccess)
                    {
                        clsUtilities.WriteToCounter("YardiPO2", "Error: " + dh.data_err_msg + " (" + RowsProcessed.ToString("#,###") + " of " + NumToProcess.ToString("#,###") + ")");
                        Error_Log += DateTime.Now.ToString() + ": Item Code " + r["ItemCode"].ToString() + "; PO Number: " + r["PONumber"].ToString() + "; ERROR: " + dh.data_err_msg + "\r\n";
                    }
                    else
                    {
                        if (RowsProcessed % 15 == 0) clsUtilities.WriteToCounter("YardiPO2", RowsProcessed.ToString("#,###") + " of " + NumToProcess.ToString("#,###"));  // only update every 15 records
                    }
                }

                if (!clsReportHelper.RunAllReportSQL_Public()) { return false; }  // Run the SQL because it uses the temp tables just loaded
            }

            if (RowsProcessed == 5000)
            {
                Error_Log += DateTime.Now.ToString() + ": <span style='color:Orange;'>WARNING: Exactly 5000 rows were imported. This could indicate that you had filtering on to limit the export to the first 5000 rows. This import was completed, however , please check your export to insure filtering in Yardi allows unlimited rows.</span>\r\n";
            }

            clsUtilities.WriteToCounter("YardiPO2", "Completed");
            return true;
        }

        /// <summary>
        /// Import Yardi Work Orders for WO Analysis reporting (File #1)
        /// </summary>
        /// <param name="FilePathAndName"></param>
        /// <returns></returns>
        public bool Import_YardiWO_File(string FilePathAndName)
        {
            Error_Log = "";

            System.Data.DataTable dtImport = new System.Data.DataTable();

            clsUtilities.WriteToCounter("YardiWO", "Starting...");

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

            System.Data.DataTable sourceTable = ds.Tables[0];

            RowsProcessed = 0;
            DateTime CreateDate = DateTime.Now;
            int NumToProcess = sourceTable.Rows.Count;

            // Clear out the table first
            clsDataHelper dh1 = new clsDataHelper();
            dh1.cmd.Parameters.AddWithValue("@FileType", "YardiWO");   // tblImport_Yardi_WOList
            dh1.ExecuteSPCMD("spImport_Delete", true, true);

            if (NumToProcess > 0)
            {
                clsReportHelper.RecordFileDateRanges("YardiWO_File", clsFunc.CastToDateTime(sourceTable.Rows[0]["Date1"], new DateTime(1900, 1, 1)), clsFunc.CastToDateTime(sourceTable.Rows[0]["Date2"], new DateTime(1900, 1, 1)));

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
                    dh.cmd.Parameters.AddWithValue("@BatchID", r["BatchID"]);
                    dh.cmd.Parameters.AddWithValue("@BatchDate", r["BatchDate"]);
                    dh.cmd.Parameters.AddWithValue("@Employee", r["Employee"]);
                    dh.cmd.Parameters.AddWithValue("@BriefDesc", r["BriefDesc"]);
                    dh.cmd.Parameters.AddWithValue("@Quantity", r["Quantity"]);
                    dh.cmd.Parameters.AddWithValue("@Code", r["Code"].ToString());
                    dh.cmd.Parameters.AddWithValue("@FullDesc", r["FullDesc"]);
                    dh.cmd.Parameters.AddWithValue("@UnitPrice", r["UnitPrice"]);
                    dh.cmd.Parameters.AddWithValue("@PayAmt", r["PayAmt"]);
                    dh.cmd.Parameters.AddWithValue("@TransBatchDate", r["woBatchOccuredDate"]);
                    dh.cmd.Parameters.AddWithValue("@PostedMonth", r["PostedMonth"]);
                    dh.cmd.Parameters.AddWithValue("@YardiWODetailRowID", r["WODetailRowID"]);  // unique in the WO detail table in Yardi

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

            if (RowsProcessed == 5000)
            {
                Error_Log += DateTime.Now.ToString() + ": <span style='color:Orange;'>WARNING: Exactly 5000 rows were imported. This could indicate that you had filtering on to limit the export to the first 5000 rows. This import was completed, however , please check your export to insure filtering in Yardi allows unlimited rows.</span>\r\n";
            }

            clsUtilities.WriteToCounter("YardiWO", "Completed");
            return true;
        }

        /// <summary>
        /// Import POs for the WO Review Report (tblMasterWOReview). It also updates tblWorkOrders with some vendor info. File #2
        /// </summary>
        /// <param name="FilePathAndName"></param>
        /// <returns></returns>
        public bool Import_YardiPO_File(string FilePathAndName)
        {
            Error_Log = "";

            System.Data.DataTable dtImport = new System.Data.DataTable();

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

            System.Data.DataTable sourceTable = ds.Tables[0];

            RowsProcessed = 0;
            DateTime CreateDate = DateTime.Now;
            int NumToProcess = sourceTable.Rows.Count;
            if (NumToProcess > 0)
            {
                clsReportHelper.RecordFileDateRanges("YardiPO_File", clsFunc.CastToDateTime(sourceTable.Rows[0]["Date1"], new DateTime(1900, 1, 1)), clsFunc.CastToDateTime(sourceTable.Rows[0]["Date2"], new DateTime(1900, 1, 1)));

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

                /* Do some extra processing to update other tables 
                    This uses the table we just updated to all at once update tblPurchaseOrders
                */
                clsDataHelper dh2 = new clsDataHelper();
                bool isSuccess2 = dh2.ExecuteSPCMD("spPurchaseOrders_Import", true);

                if (RowsProcessed == 5000)
                {
                    Error_Log += DateTime.Now.ToString() + ": <span style='color:Orange;'>WARNING: Exactly 5000 rows were imported. This could indicate that you had filtering on to limit the export to the first 5000 rows. This import was completed, however , please check your export to insure filtering in Yardi allows unlimited rows.</span>\r\n";
                }
            }

            clsUtilities.WriteToCounter("YardiPO", "Completed");
            return true;
        }

        /// <summary>
        /// Work Order File #5
        /// </summary>
        /// <param name="FilePathAndName"></param>
        /// <returns></returns>
        public bool Import_YardiWO_GeneralFile(string FilePathAndName)
        {
            Error_Log = "";

            System.Data.DataTable dtImport = new System.Data.DataTable();

            clsUtilities.WriteToCounter("YardiWOH", "Starting...");

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

            System.Data.DataTable sourceTable = ds.Tables[0];

            RowsProcessed = 0;
            int NumToProcess = sourceTable.Rows.Count;
            if (NumToProcess > 0)
            {
                clsReportHelper.RecordFileDateRanges("YardiWO_GeneralFile", null, DateTime.Now);

                // We are loading the tblWorkOrders table directly
                foreach (DataRow r in sourceTable.Rows)
                {
                    clsDataHelper dh = new clsDataHelper();
                    dh.cmd.Parameters.AddWithValue("@WONumber", r["WONumber"].ToString());
                    dh.cmd.Parameters.AddWithValue("@CompleteDate", r["CompleteDate"]);
                    dh.cmd.Parameters.AddWithValue("@Category", r["Category"]);
                    dh.cmd.Parameters.AddWithValue("@JObStatus", r["JObStatus"]);
                    dh.cmd.Parameters.AddWithValue("@CallDate", r["CallDate"]);
                    dh.cmd.Parameters.AddWithValue("@SchedDate", r["SchedDate"]);
                    dh.cmd.Parameters.AddWithValue("@BatchID", r["BatchID"]);
                    dh.cmd.Parameters.AddWithValue("@BriefDesc", r["BriefDesc"]);
                    dh.cmd.Parameters.AddWithValue("@ExpenseType", r["ExpenseType"]);
                    dh.cmd.Parameters.AddWithValue("@yardiCreateDate", r["yardiCreateDate"]);
                    dh.cmd.Parameters.AddWithValue("@yardiUpdatedDate", r["yardiUpdatedDate"]);

                    bool isSuccess = dh.ExecuteSPCMD("spWorkOrderUpdate", false);
                    RowsProcessed++;
                    if (!isSuccess)
                    {
                        clsUtilities.WriteToCounter("YardiWOH", "Error: " + dh.data_err_msg + " (" + RowsProcessed.ToString("#,###") + " of " + NumToProcess.ToString("#,###") + ")");
                        Error_Log += DateTime.Now.ToString() + ": WO Number: " + r["WONumber"].ToString() + "; ERROR: " + dh.data_err_msg + "\r\n";
                    }
                    else
                    {
                        if (RowsProcessed % 15 == 0) clsUtilities.WriteToCounter("YardiWOH", RowsProcessed.ToString("#,###") + " of " + NumToProcess.ToString("#,###"));  // only update every 15 records
                    }
                }

                if (!clsReportHelper.RunAllReportSQL_Public()) { return false; }  // Run the SQL because it uses the temp tables just loaded

                if (RowsProcessed == 5000)
                {
                    Error_Log += DateTime.Now.ToString() + ": <span style='color:Orange;'>WARNING: Exactly 5,000 rows were imported. This could indicate that you had filtering on to limit the export to the first 5000 rows. This import was completed, however , please check your export to insure filtering in Yardi allows unlimited rows.</span>\r\n";
                }
            }
            clsUtilities.WriteToCounter("YardiWOH", "Completed");
            return true;
        }

        /// <summary>
        /// Work Order File #5
        /// </summary>
        /// <param name="FilePathAndName"></param>
        /// <returns></returns>
        public bool Import_YardiProperty_File(string FilePathAndName)
        {
            Error_Log = "";

            System.Data.DataTable dtImport = new System.Data.DataTable();

            clsUtilities.WriteToCounter("YardiProp", "Starting...");

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

            System.Data.DataTable sourceTable = ds.Tables[0];

            // Create DataView and select distinct rows
            DataView view = new DataView(sourceTable);
            System.Data.DataTable filteredTable = view.ToTable(true,
                "yardiPropertyRowID", "BuildingCode", "addr1_Co", "addr2", "addr3", "addr4", "City", "StateCode", "ZipCode",
                "isPropertyInactive", "propertyInactiveDate");

            RowsProcessed = 0;
            int NumToProcess = filteredTable.Rows.Count;
            if (NumToProcess > 0)
            {
                // We are loading the table directly into tblProperties
                foreach (DataRow r in filteredTable.Rows)
                {
                    clsDataHelper dh = new clsDataHelper();
                    dh.cmd.Parameters.AddWithValue("@yardiPropertyRowID", r["yardiPropertyRowID"]);
                    dh.cmd.Parameters.AddWithValue("@BuildingCode", r["BuildingCode"]);
                    dh.cmd.Parameters.AddWithValue("@Addr1_Co", r["Addr1_Co"]);
                    dh.cmd.Parameters.AddWithValue("@addr2", r["Addr2"]);
                    dh.cmd.Parameters.AddWithValue("@addr3", r["Addr3"]);
                    dh.cmd.Parameters.AddWithValue("@addr4", r["Addr4"]);
                    dh.cmd.Parameters.AddWithValue("@City", r["City"]);
                    dh.cmd.Parameters.AddWithValue("@StateCode", r["StateCode"]);
                    dh.cmd.Parameters.AddWithValue("@ZipCode", r["ZipCode"]);
                    dh.cmd.Parameters.AddWithValue("@isInactive", r["isPropertyInactive"]);
                    dh.cmd.Parameters.AddWithValue("@inactiveDate", r["PropertyInactiveDate"]);

                    bool isSuccess = dh.ExecuteSPCMD("spPropertyUpdate", false);
                    RowsProcessed++;
                    if (!isSuccess)
                    {
                        clsUtilities.WriteToCounter("YardiProp", "Error (Pass 1 - properties): " + dh.data_err_msg + " (" + RowsProcessed.ToString("#,###") + " of " + NumToProcess.ToString("#,###") + ")");
                        Error_Log += DateTime.Now.ToString() + ": Building Code: " + r["BuildingCode"].ToString() + "; ERROR: " + dh.data_err_msg + "\r\n";
                    }
                    else
                    {
                        if (RowsProcessed % 15 == 0) clsUtilities.WriteToCounter("YardiProp", "(Pass 1: Properties): " + RowsProcessed.ToString("#,###") + " of " + NumToProcess.ToString("#,###"));  // only update every 15 records
                    }
                }

                //if (!clsReportHelper.RunAllReportSQL_Public()) { return false; }  // Run the SQL because it uses the temp tables just loaded
            }
            clsUtilities.WriteToCounter("YardiProp", "Completed");


            // SECOND LOOP - UNITS
            // NEED TO GO THROUGH ALL ROWS
            //==================================================================
            System.Data.DataTable unitsTable = ds.Tables[0];

            RowsProcessed = 0;
            NumToProcess = unitsTable.Rows.Count;
            if (NumToProcess > 0)
            {
                // We are loading the table directly into tblUnits
                foreach (DataRow r in unitsTable.Rows)
                {
                    clsDataHelper dh = new clsDataHelper();
                    dh.cmd.Parameters.AddWithValue("@yardiUnitRowID", r["yardiUnitRowID"]);
                    dh.cmd.Parameters.AddWithValue("@yardiPropertyRowID", r["yardiPropertyRowID"]);
                    dh.cmd.Parameters.AddWithValue("@AptNumber", r["AptNumber"]);
                    dh.cmd.Parameters.AddWithValue("@Bedrooms", r["Bedrooms"]);
                    dh.cmd.Parameters.AddWithValue("@rent", r["rent"]);
                    dh.cmd.Parameters.AddWithValue("@SqFt", r["SqFt"]);
                    dh.cmd.Parameters.AddWithValue("@UnitStatus", r["UnitStatus"]);
                    dh.cmd.Parameters.AddWithValue("@LastMoveInDate", r["LastMoveInDate"]);
                    dh.cmd.Parameters.AddWithValue("@LastMoveOutDate", r["LastMoveOutDate"]);
                    dh.cmd.Parameters.AddWithValue("@isExcluded", r["isUnitExcluded"]);
                    dh.cmd.Parameters.AddWithValue("@LastTenantRent", r["LastTenantRent"]);

                    bool isSuccess = dh.ExecuteSPCMD("spPropertyUnitUpdate", false);
                    RowsProcessed++;
                    if (!isSuccess)
                    {
                        clsUtilities.WriteToCounter("YardiUnit", "Error (Pass 2 - units): " + dh.data_err_msg + " (" + RowsProcessed.ToString("#,###") + " of " + NumToProcess.ToString("#,###") + ")");
                        Error_Log += DateTime.Now.ToString() + ": Apt Number: " + r["AptNumber"].ToString() + "; ERROR: " + dh.data_err_msg + "\r\n";
                    }
                    else
                    {
                        if (RowsProcessed % 15 == 0) clsUtilities.WriteToCounter("YardiUnit", "(Pass 2: Units): " + RowsProcessed.ToString("#,###") + " of " + NumToProcess.ToString("#,###"));  // only update every 15 records
                    }
                }

                //if (!clsReportHelper.RunAllReportSQL_Public()) { return false; }  // Run the SQL because it uses the temp tables just loaded

                if (RowsProcessed == 5000)
                {
                    Error_Log += DateTime.Now.ToString() + ": <span style='color:Orange;'>WARNING: Exactly 5,000 rows were imported. This could indicate that you had filtering on to limit the export to the first 5000 rows. This import was completed, however , please check your export to insure filtering in Yardi allows unlimited rows.</span>\r\n";
                }
            }
            clsUtilities.WriteToCounter("YardiProp", "Completed");
            clsUtilities.WriteToCounter("YardiUnit", "Completed");

            clsReportHelper.RecordFileDateRanges("YardiPropertyFile", null, DateTime.Now);

            return true;
        }


    }
}