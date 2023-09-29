using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;
using System.Data;
using System.Data.SqlClient;
using System.Data.OleDb;
using System.Runtime.InteropServices;
using System.Runtime.InteropServices.ComTypes;
using Microsoft.Office.Interop.Excel;

namespace LW_Data
{
    using LW_Data;
    using Microsoft.Office.Interop.Excel;
    using System.Data;
    using System.Data.SqlClient;
    using Excel = Microsoft.Office.Interop.Excel;

    public class clsExcelHelper
    {
        public bool FillExcelRangeFromSP(ref Excel.Workbook xlWorkbook, string StoredProcedure, int WorksheetNumber, int CellStartRow, int CellStartColumn)
        {
            // Read the full datatable
            clsDataHelper DH = new clsDataHelper();
            SqlCommand cmd = new SqlCommand();
            System.Data.DataTable sourcedt = DH.GetDataTableCMD(StoredProcedure, ref cmd);
            int colCount = sourcedt.Columns.Count;
            int rowCount = sourcedt.Rows.Count;

            object[,] values = new object[rowCount, colCount];
            int i = 0;
            foreach (DataRow R in sourcedt.Rows)
            {
                for (int ii = 0; ii < colCount; ii++)
                {
                    if (!string.IsNullOrEmpty(R[ii].ToString())) values[i, ii] = R[ii];
                }
                i++;
            }

            Excel._Worksheet xlWorksheet = xlWorkbook.Sheets[WorksheetNumber];
            // Cells[Row, Column]
            Excel.Range xlRange = xlWorksheet.Range[xlWorksheet.Cells[CellStartRow, CellStartColumn], xlWorksheet.Cells[CellStartRow + rowCount - 1, CellStartColumn + colCount - 1]];
            xlRange.Value = values;
            xlWorkbook.Save();

            //release com objects to fully kill excel process from running in the background
            Marshal.ReleaseComObject(xlRange);
            Marshal.ReleaseComObject(xlWorksheet);

            return true;
        }

        public bool CleanUpExcelSession(ref Excel.Application xlApp, ref Excel.Workbook xlWorkbook, string TargetPathAndFileName)
        {
            /// CLEAN UP
            GC.Collect();
            GC.WaitForPendingFinalizers();

            //close and release
            xlWorkbook.Close(true, TargetPathAndFileName);
            xlApp.Quit();
            Marshal.ReleaseComObject(xlWorkbook);
            Marshal.ReleaseComObject(xlApp);

            return true;
        }


        public static string GetExcelConnectionString (string fileNameAndPath)
        {
            return string.Format("Provider=Microsoft.ACE.OLEDB.12.0;Data Source=\"{0}\";Extended Properties=\"Excel 12.0 Xml;IMEX=1;HDR=YES\";", fileNameAndPath);
        }

        public static string GetExcelConnectionString_RW(string fileNameAndPath)
        {
            return string.Format("Provider=Microsoft.ACE.OLEDB.12.0;Data Source=\"{0}\";Extended Properties=\"Excel 12.0 Xml;Mode=ReadWrite;HDR=YES\";", fileNameAndPath);
        }

        public static List<string> GetWorksheetNames(string fileNameAndPath)
        {
            List<string> sheets = new List<string>();
            using (var connection = new OleDbConnection(clsExcelHelper.GetExcelConnectionString(fileNameAndPath)))
            {
                connection.Open();
                System.Data.DataTable dt = connection.GetOleDbSchemaTable(OleDbSchemaGuid.Tables, null);
                foreach (DataRow drSheet in dt.Rows)
                    if (drSheet["TABLE_NAME"].ToString().EndsWith("$'") || drSheet["TABLE_NAME"].ToString().EndsWith("$"))
                    {
                        string s = drSheet["TABLE_NAME"].ToString();
                        sheets.Add(s.StartsWith("'") ? s.Substring(1, s.Length - 3) : s.Substring(0, s.Length - 1));
                    }
                connection.Close();
            }

            return sheets;
        }
    }

}
