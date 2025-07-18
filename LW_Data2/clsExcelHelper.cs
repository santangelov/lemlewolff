using System;
using System.Collections.Generic;
using System.Data.OleDb;
using System.Runtime.InteropServices;

namespace LW_Data
{
    using System.Data;
    using System.Data.SqlClient;
    using System.Security.RightsManagement;
    using Excel = Microsoft.Office.Interop.Excel;

    public class clsExcelHelper
    {
        public string ErrorMsg = "";

        /// <summary>
        /// Remove rows 1 and 2, promote row 2 to column headers, and clean up empty rows.
        /// </summary>
        /// <param name="sourceTable"></param>
        public static void PromoteExcelHeaderAndCleanRows(ref DataTable sourceTable)
        {
            if (sourceTable == null || sourceTable.Rows.Count < 2)
                return;

            // Row 0 = Header Row (even though for some reason it shows up in the spreadsheet as row 2)
            DataRow headerRow = sourceTable.Rows[0];
            for (int i = 0; i < sourceTable.Columns.Count; i++)
            {
                string colName = headerRow[i]?.ToString()?.Trim();
                if (!string.IsNullOrEmpty(colName))
                    sourceTable.Columns[i].ColumnName = colName;
                else
                    sourceTable.Columns[i].ColumnName = "Col" + (i + 1).ToString();
            }

            // Delete Excel rows 0-5
            if (sourceTable.Rows.Count >= 4)
            {
                sourceTable.Rows[3].Delete();
                sourceTable.Rows[2].Delete(); 
                sourceTable.Rows[1].Delete(); 
                sourceTable.Rows[0].Delete(); 
            }
            sourceTable.AcceptChanges();
        }

        public bool FillExcelRangeFromSP(ref Excel.Workbook xlWorkbook, string StoredProcedure, int WorksheetNumber, int CellStartRow, int CellStartColumn, SqlCommand cmd = null)
        {
            // Read the full datatable
            clsDataHelper DH = new clsDataHelper();
            if (cmd != null) DH.cmd = cmd;
            DH.cmd.CommandTimeout = 180;   // Seconds
            System.Data.DataTable sourcedt = DH.GetDataTable(StoredProcedure);

            return FillExcelRangeFromDT(ref xlWorkbook, ref sourcedt, WorksheetNumber, CellStartRow, CellStartColumn);
        }

        public bool FillExcelCellFromValue(ref Excel.Workbook xlWorkbook, int worksheetNumber, int row, int column, object value)
        {
            this.ErrorMsg = "";
            if (xlWorkbook == null) return false;

            Excel.Worksheet xlWorksheet = null;
            Excel.Range xlCell = null;

            try
            {
                // Get the specified worksheet
                xlWorksheet = xlWorkbook.Sheets[worksheetNumber] as Excel.Worksheet;
                if (xlWorksheet == null) return false;

                // Access the cell
                xlCell = xlWorksheet.Cells[row, column] as Excel.Range;
                xlCell.Value = value;

                // Save workbook
                xlWorkbook.Save();

                return true;
            }
            catch (Exception ex)
            {
                this.ErrorMsg = "Error filling Excel cell: " + ex.Message;
                return false;
            }
            finally
            {
                // Release COM objects properly
                if (xlCell != null)
                {
                    Marshal.ReleaseComObject(xlCell);
                    xlCell = null;
                }
            }
        }



        public bool FillExcelRangeFromDT(ref Excel.Workbook xlWorkbook, ref System.Data.DataTable dt, int WorksheetNumber, int CellStartRow, int CellStartColumn)
        {
            int colCount = dt.Columns.Count;
            int rowCount = dt.Rows.Count;

            object[,] values = new object[rowCount, colCount];
            int i = 0;
            foreach (DataRow R in dt.Rows)
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

        /// <summary>
        ///  Returns the number of columns pasted for the header
        /// </summary>
        /// <param name="xlWorkbook"></param>
        /// <param name="dt"></param>
        /// <param name="WorksheetNumber"></param>
        /// <param name="HeaderRowNum"></param>
        /// <param name="HeaderStartColumn"></param>
        /// <returns></returns>
        public int FillExcelHeadersFromDT(ref Excel.Workbook xlWorkbook, ref System.Data.DataTable dt, int WorksheetNumber, int HeaderRowNum, int HeaderStartColumn)
        {
            int colCount = dt.Columns.Count;
            object[,] values = new object[1, colCount];

            int i = 0;
            foreach (DataColumn C in dt.Columns)
            {
                if (!string.IsNullOrEmpty(C.ColumnName)) values[0, i] = C.ColumnName;   // 0 = One row of data for header
                i++;
            }

            Excel._Worksheet xlWorksheet = xlWorkbook.Sheets[WorksheetNumber];
            // Cells[Row, Column]
            Excel.Range xlRange = xlWorksheet.Range[xlWorksheet.Cells[HeaderRowNum, HeaderStartColumn], xlWorksheet.Cells[HeaderRowNum, HeaderStartColumn + colCount - 1]];
            xlRange.Value = values;
            xlWorkbook.Save();

            //release com objects to fully kill excel process from running in the background
            Marshal.ReleaseComObject(xlRange);
            Marshal.ReleaseComObject(xlWorksheet);

            return i;
        }

        /// <summary>
        /// Source and Dest strings: ie "A9:L9"
        /// </summary>
        /// <param name="xlWorkbook"></param>
        /// <param name="SourceRange"></param>
        /// <param name="DestRange"></param>
        /// <returns></returns>
        public bool CopyExcelRange(ref Excel.Workbook xlWorkbook, int WorksheetNumber, int SourceCellRow, int SourceCellColumn, int DestStartRow, int DestStartColumn, int DestEndRow, int DestEndColumn)
        {
            Excel._Worksheet xlWorksheet = xlWorkbook.Sheets[WorksheetNumber];
            Excel.Range xlSourceRange = xlWorksheet.Range[xlWorksheet.Cells[SourceCellRow, SourceCellColumn], xlWorksheet.Cells[SourceCellRow, SourceCellColumn]];
            Excel.Range xlDestRange = xlWorksheet.Range[xlWorksheet.Cells[DestStartRow, DestStartColumn], xlWorksheet.Cells[DestEndRow, DestEndColumn]];

            xlSourceRange.Copy();
            xlDestRange.PasteSpecial();

            //release com objects to fully kill excel process from running in the background
            Marshal.ReleaseComObject(xlSourceRange);
            Marshal.ReleaseComObject(xlDestRange);
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
            Marshal.ReleaseComObject(xlWorkbook);
            xlApp.Quit();
            Marshal.ReleaseComObject(xlApp);

            return true;
        }


        public static string GetExcelConnectionString(string fileNameAndPath)
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
