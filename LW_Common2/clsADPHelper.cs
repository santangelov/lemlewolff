using System.IO;
using System.Data;
using System.Data.SqlClient;
using System.Data.OleDb;
using System.Configuration;
using LW_Data;
using System.Threading;
using System;
using System.Collections.Generic;

namespace LW_Common
{
    public class clsADPHelper
    {
        public string error_message { get; set; }
        public int RowsProcessed { get; set; }

        //public string GetWorkSheetNames(string FilePathAndName)

        public bool Import_ADP_File(string FilePathAndName, string WorksheetName)
        {
            DataTable dtImport = new DataTable();
            error_message = "";

            clsUtilities.WriteToCounter("ADP", "Starting...");

            DataSet ds = new DataSet("Temp");
            using (var conn = new OleDbConnection(clsExcelHelper.GetExcelConnectionString(FilePathAndName)))
            {
                conn.Open();
                OleDbDataAdapter adapter = new OleDbDataAdapter(@"SELECT * FROM [" + WorksheetName + "$A5:Z] WHERE [Payroll Name] > ''", conn); // Filtering so we don't pick up the TOTAL rows
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
                // Validate the import file first - All columns are required
                string NotFoundStr = "";
                foreach (string s in new List<string> { "Company Code", "Payroll Name", "File Number", "Time In", "Time Out", "Timecard Work Location", "Timecard Work W#O#", "Worked Department", "Payroll Pay Date", "Pay Code (Timecard)", "Hours", "Dollars", "Timecard Worked Work Id Description", "Timecard Worked W#O# Desc Description" })
                {
                    if (!sourceTable.Columns.Contains(s)) if (NotFoundStr == "") NotFoundStr += s; else NotFoundStr += ", " + s;
                }
                if (NotFoundStr != "")
                {
                    error_message = "ADP Import file NOT loaded. ** Check that headings start in row 5. **  Columns not found: " + NotFoundStr;
                    return false;
                }


                foreach (DataRow r in sourceTable.Rows)
                {
                    string uniqueID = r["File Number"].ToString() + "; " + r["Time In"].ToString() + "; " + r["Time Out"].ToString();
                    try
                    {
                        clsDataHelper dh = new clsDataHelper();
                        // Change Period to "#" and brackets [] to Parenthasis () in the field names from Excel
                        dh.cmd.Parameters.AddWithValue("@CompanyCode", r["Company Code"].ToString());
                        dh.cmd.Parameters.AddWithValue("@PayrollName", r["Payroll Name"].ToString().Replace("\t"," "));
                        dh.cmd.Parameters.AddWithValue("@FileNumber", r["File Number"].ToString());
                        dh.cmd.Parameters.AddWithValue("@TimeIn", "1/1/1900 " + r["Time In"].ToString());
                        dh.cmd.Parameters.AddWithValue("@TimeOut", "1/1/1900 " + r["Time Out"].ToString());
                        dh.cmd.Parameters.AddWithValue("@Location", r["Timecard Work Location"]);
                        dh.cmd.Parameters.AddWithValue("@WONumber", r["Timecard Work W#O#"]);
                        dh.cmd.Parameters.AddWithValue("@Department", r["Worked Department"]);
                        dh.cmd.Parameters.AddWithValue("@PayDate", r["Payroll Pay Date"]);
                        dh.cmd.Parameters.AddWithValue("@PayCode", r["Pay Code (Timecard)"].ToString());  // in the file it's "[Timecard]"
                        dh.cmd.Parameters.AddWithValue("@Hours", r["Hours"]);
                        dh.cmd.Parameters.AddWithValue("@Dollars", r["Dollars"]);
                        dh.cmd.Parameters.AddWithValue("@TimeDescription", r["Timecard Worked Work Id Description"]);
                        dh.cmd.Parameters.AddWithValue("@WODescription", r["Timecard Worked W#O# Desc Description"]);
                        dh.cmd.Parameters.AddWithValue("@CreateDate", createDate);
                        dh.cmd.Parameters.AddWithValue("@CreatedBy", "User1");

                        dh.cmd.Parameters.AddWithValue("@NoReturn", true);  // Force it to not return data for speed
                        bool isSuccess = dh.ExecuteSPCMD("spADPUpdate", false);
                        if (isSuccess)
                        {
                            RowsProcessed++;
                            if (RowsProcessed % 34 == 0) clsUtilities.WriteToCounter("ADP", RowsProcessed.ToString("#,###") + " of " + NumToProcess.ToString("#,###"));
                        }
                        else
                        {
                            clsUtilities.WriteToCounter("ADP", "ERROR IN ROW " + RowsProcessed.ToString("#,###") + ". " + dh.data_err_msg + "; " + uniqueID);
                            error_message += "ERROR IN ROW " + RowsProcessed.ToString("#,###") + ". " + dh.data_err_msg + "; " + uniqueID + "\n";
                        }
                    }
                    catch (Exception e)
                    {
                        // Show the error and continue - later we need to record this somewhere 
                        clsUtilities.WriteToCounter("ADP", "ERROR IN ROW " + RowsProcessed.ToString("#,###") + ". " + e.Message + "; " + uniqueID);
                        error_message += "ERROR READING ROW " + RowsProcessed.ToString("#,###") + ". " + e.Message + "; " + uniqueID + "\n";
                    }
                }
            }
            return true;
        }

    }
}