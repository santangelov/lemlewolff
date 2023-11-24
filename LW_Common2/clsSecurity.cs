using LW_Data;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LW_Common
{
    internal class clsSecurity
    {
        public clsSecurity() { }

        public string ErrorMsg { get; set; }

        public string FullName { get; set; }
        public string EmailAddress { get; set; }
        public string Password { get; set; }
        public string Password_Enc { get; set; }

        public static bool LogInUser(string EmailAddress, string password)
        {
            clsDataHelper d = new clsDataHelper();
            SqlCommand cmd = new SqlCommand();
            cmd.Parameters.AddWithValue("@EmailAddress", EmailAddress);
            cmd.Parameters.AddWithValue("Password", password);
            DataTable dt = d.GetDataTableCMD("spUsers", ref cmd);
            if (dt.Rows.Count > 0)
            {
                // Log in the user

                return true;
            }
            else
            {
                return false;
            }
        }
    }
}
