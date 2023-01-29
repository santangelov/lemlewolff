using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;

namespace LW_Data
{
    public class clsDataHelper
    {
        public string data_err_msg = "";
        public SqlCommand cmd = new SqlCommand();

        public static SqlConnection sqlconn(bool OpenReadWrite)
        {
            if (OpenReadWrite)
            {
                return new SqlConnection(ConfigurationManager.ConnectionStrings["LWSQLConnStrRW"].ConnectionString);
            }
            else
            {
                return new SqlConnection(ConfigurationManager.ConnectionStrings["LWSQLConnStrRO"].ConnectionString);
            }
        }


        /// <summary>
        /// This will opena nd clsoe the connection with each call. This is always opened as Read-Write
        /// </summary>
        /// <param name="sqlStoredProcedure"></param>
        /// <param name="ConnectionStr"></param>
        /// <returns></returns>
        public bool ExecuteSPCMD(string sqlStoredProcedure, bool CloseOnCompletion = true)
        {
            SqlConnection cn = sqlconn(true);

            cmd.CommandType = CommandType.StoredProcedure;
            cmd.CommandText = sqlStoredProcedure;
            cmd.Connection = cn;

            try
            {
                using (cn)
                {
                    cn.Open();
                    cmd.ExecuteNonQuery();
                    if (CloseOnCompletion) cn.Dispose();
                }
            }
            catch (Exception ex)
            {
                
                data_err_msg = ex.Message;
                cn.Dispose();
                return false;
            }

            return true;
        }

        public DataTable GetDataTableCMD(string sqlStoredProcedure, ref SqlCommand cmd)
        {
            string connStr = ConfigurationManager.ConnectionStrings["LWSQLConnStrRO"].ConnectionString;
            SqlConnection cn = new SqlConnection(connStr);
            data_err_msg = "";

            cmd.Connection = cn;
            cmd.CommandText = sqlStoredProcedure;
            cmd.CommandType = CommandType.StoredProcedure;

            SqlDataAdapter DA = new SqlDataAdapter(cmd);
            DataSet ds = new DataSet();

            try
            {
                DA.Fill(ds);
            }
            catch (Exception e)
            {
                data_err_msg = e.Message;
            }
            finally
            {
                DA.Dispose();
                cn.Close();
            }

            if (ds.Tables.Count == 0)
            {
                data_err_msg = "No tables returned. " + data_err_msg;
                return null;
            }
            else
            {
                return ds.Tables[0];
            }

        }

    }
}                                               