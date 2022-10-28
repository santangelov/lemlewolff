using System.IO;
using System.Data;
using System.Data.SqlClient;
using System.Data.OleDb;
using System.Configuration;
using LW_Data;
using System.Threading;

namespace LW_Common
{
    public class clsAMCTimeHelper
    {
        public string error_message { get; set; }
        public int RowsProcessed { get; set; }

        public bool Import_AMCTime_File(string FilePathAndName)
        {

            DataTable dtImport = new DataTable();

            clsUtilities.WriteToCounter("AMC", "Starting...");

            string FolderOnly = Path.GetDirectoryName(FilePathAndName);
            string FileNameOnly = Path.GetFileName(FilePathAndName);
            string connectionString = string.Format(@"Provider=Microsoft.ACE.OLEDB.12.0;Data Source=""{0}"";Extended Properties=""Excel 12.0 Xml;HDR=YES"";", FilePathAndName);

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
            int NumToProcess = sourceTable.Rows.Count;
            if (NumToProcess > 0)
            {
                foreach (DataRow r in sourceTable.Rows)
                {
                    clsDataHelper dh = new clsDataHelper();
                    dh.cmd.Parameters.AddWithValue("@CompanyCode", r["Company Code"].ToString());
                    dh.cmd.Parameters.AddWithValue("@PayrollName", r["Payroll Name"].ToString());
                    dh.cmd.Parameters.AddWithValue("@FileNumber", r["File Number"].ToString());
                    dh.cmd.Parameters.AddWithValue("@TimeIn", r["Time In"].ToString());
                    dh.cmd.Parameters.AddWithValue("@TimeOut", r["Time Out"]);
                    dh.cmd.Parameters.AddWithValue("@Location", r["Timecard Work Location"]);
                    dh.cmd.Parameters.AddWithValue("@WONumber", r["Timecard Work W.O."]);
                    dh.cmd.Parameters.AddWithValue("@Department", r["Worked Department"]);
                    dh.cmd.Parameters.AddWithValue("@PayDate", r["Payroll Pay Date"]);
                    dh.cmd.Parameters.AddWithValue("@PayCode", r["Pay Code [Timecard]"].ToString());
                    dh.cmd.Parameters.AddWithValue("@Hours", r["Hours"]);
                    dh.cmd.Parameters.AddWithValue("@Dollars", r["Dollars"]);
                    dh.cmd.Parameters.AddWithValue("@TimeDescription", r["Timecard Worked Work Id Description"]);
                    dh.cmd.Parameters.AddWithValue("@WODescription", r["Timecard Worked W.O. Desc Description"]);

                    dh.cmd.Parameters.AddWithValue("@NoReturn", true);  // Force it to not return data for speed
                    bool isSuccess = dh.ExecuteSPCMD("spAMCTimeUpdate", false);
                    if (isSuccess) RowsProcessed++;
                    if (RowsProcessed % 15 == 0) clsUtilities.WriteToCounter("AMC", RowsProcessed.ToString("#,###") + " of " + NumToProcess.ToString("#,###"));  // only update every 15 records
                }
            }
            return true;
        }

    }
}