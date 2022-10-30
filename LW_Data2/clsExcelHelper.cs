using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;
using System.Data;
using System.Data.SqlClient;
using System.Data.OleDb;

namespace LW_Data
{
    public class clsExcelHelper
    {
        public static string GetExcelConnectionString (string fileNameAndPath)
        {
            return string.Format("Provider=Microsoft.ACE.OLEDB.12.0;Data Source=\"{0}\";Extended Properties=\"Excel 12.0 Xml;HDR=YES\";", fileNameAndPath);
        }

        public static List<string> GetWorksheetNames(string fileNameAndPath)
        {
            List<string> sheets = new List<string>();
            using (var connection = new OleDbConnection(clsExcelHelper.GetExcelConnectionString(fileNameAndPath)))
            {
                connection.Open();
                DataTable dt = connection.GetOleDbSchemaTable(OleDbSchemaGuid.Tables, null);
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
