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
    public class clsAMCTimeHelper
    {
        public string error_message { get; set; }
        public int RowsProcessed { get; set; }

        //public string GetWorkSheetNames(string FilePathAndName)

        public bool Import_AMCTime_File(string FilePathAndName, string WorksheetName)
        {
            DataTable dtImport = new DataTable();
            error_message = "";

            clsUtilities.WriteToCounter("AMC", "Starting...");

            DataSet ds = new DataSet("Temp");
            using (var conn = new OleDbConnection(clsExcelHelper.GetExcelConnectionString(FilePathAndName)))
            {
                conn.Open();
                OleDbDataAdapter adapter = new OleDbDataAdapter(string.Format("SELECT * FROM [{0}$A4:N80000] WHERE [Payroll Name] > ''", WorksheetName), conn);
                adapter.Fill(ds);
                conn.Close();
                conn.Dispose();
            }

            DataTable sourceTable = ds.Tables[0];

            RowsProcessed = 0;
            int NumToProcess = sourceTable.Rows.Count;
            DateTime createDate = DateTime.Now;
            if (NumToProcess > 0)
            {
                foreach (DataRow r in sourceTable.Rows)
                {
                    try
                    {
                        clsDataHelper dh = new clsDataHelper();
                        // Change Period to "#" and brackets [] to Parenthasis () int eh field names from Excel
                        dh.cmd.Parameters.AddWithValue("@CompanyCode", r["Company Code"].ToString());
                        dh.cmd.Parameters.AddWithValue("@PayrollName", r["Payroll Name"].ToString());
                        dh.cmd.Parameters.AddWithValue("@FileNumber", r["File Number"].ToString());
                        dh.cmd.Parameters.AddWithValue("@TimeIn", "1/1/1900 " + r["Time In"].ToString());
                        dh.cmd.Parameters.AddWithValue("@TimeOut", "1/1/1900 " + r["Time Out"].ToString());
                        dh.cmd.Parameters.AddWithValue("@Location", r["Timecard Work Location"]);
                        dh.cmd.Parameters.AddWithValue("@WONumber", r["Timecard Work W#O#"]);
                        dh.cmd.Parameters.AddWithValue("@Department", r["Worked Department"]);
                        dh.cmd.Parameters.AddWithValue("@PayDate", r["Payroll Pay Date"]);
                        dh.cmd.Parameters.AddWithValue("@PayCode", r["Pay Code (Timecard)"].ToString());
                        dh.cmd.Parameters.AddWithValue("@Hours", r["Hours"]);
                        dh.cmd.Parameters.AddWithValue("@Dollars", r["Dollars"]);
                        dh.cmd.Parameters.AddWithValue("@TimeDescription", r["Timecard Worked Work Id Description"]);
                        dh.cmd.Parameters.AddWithValue("@WODescription", r["Timecard Worked W#O# Desc Description"]);
                        dh.cmd.Parameters.AddWithValue("@CreateDate", createDate);
                        dh.cmd.Parameters.AddWithValue("@CreatedBy", "User1");

                        dh.cmd.Parameters.AddWithValue("@NoReturn", true);  // Force it to not return data for speed
                        bool isSuccess = dh.ExecuteSPCMD("spAMCTimeUpdate", false);
                        if (isSuccess)
                        {
                            RowsProcessed++;
                            if (RowsProcessed % 34 == 0) clsUtilities.WriteToCounter("AMC", RowsProcessed.ToString("#,###") + " of " + NumToProcess.ToString("#,###"));
                        }
                        else
                        {
                            clsUtilities.WriteToCounter("AMC", "ERROR IN ROW " + RowsProcessed.ToString("#,###") + ". " + dh.data_err_msg);
                            error_message += "ERROR IN ROW " + RowsProcessed.ToString("#,###") + ". " + dh.data_err_msg + "\n";
                        }
                    }
                    catch (Exception e)
                    {
                        // Show the error and continue - later we need to record this somewhere 
                        clsUtilities.WriteToCounter("AMC", "ERROR IN ROW " + RowsProcessed.ToString("#,###") + ". " + e.Message);
                        error_message += "ERROR READING ROW " + RowsProcessed.ToString("#,###") + ". " + e.Message + "\n";
                    }
                }
            }
            return true;
        }

    }
}