using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;

namespace LW_Data
{
    public class clsDataHelper
    {
        public static string ENCRYPTION_KEY = "lmllm-ygsta7&%^?Hposga";

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
        /// This will open and close the connection with each call. This is always opened as Read-Write
        /// </summary>
        /// <param name="sqlStoredProcedure"></param>
        /// <param name="ConnectionStr"></param>
        /// <returns></returns>
        public bool ExecuteSPCMD(string sqlStoredProcedure, bool CloseOnCompletion = true, bool OpenReadWrite = true)
        {
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.CommandTimeout = 180;  // 3 minutes
            cmd.CommandText = sqlStoredProcedure;
            if (cmd.Connection is null || cmd.Connection?.ConnectionString == "") cmd.Connection = clsDataHelper.sqlconn(OpenReadWrite);

            try
            {
                using (cmd.Connection)
                {
                    cmd.Connection.Open();
                    cmd.ExecuteNonQuery();
                    if (CloseOnCompletion)
                    {
                        cmd.Connection.Close();
                        cmd.Connection.Dispose();
                    }
                }
            }
            catch (Exception ex)
            {
                data_err_msg = ex.Message;
                cmd.Connection.Dispose();
                return false;
            }

            return true;
        }

        /// <summary>
        /// This returns one table from the returned dataset. use the DataHelper.CMD for the cmd parameters.
        /// </summary>
        /// <param name="sqlStoredProcedure"></param>
        /// <returns></returns>
        public DataTable GetDataTable(string sqlStoredProcedure)
        {
            data_err_msg = "";

            cmd.Connection = clsDataHelper.sqlconn(false);
            cmd.CommandText = sqlStoredProcedure;
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.CommandTimeout = 180;   // 3 minutes

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
                cmd.Connection.Close();
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

        /// <summary>
        /// This returns a DataSet which can contain multiple tables; Read-Only
        /// </summary>
        /// <param name="sqlStoredProcedure"></param>
        /// <param name="cmd"></param>
        /// <returns></returns>
        public DataSet GetDataSetCMD(string sqlStoredProcedure, ref SqlCommand cmd)
        {
            data_err_msg = "";

            cmd.Connection = clsDataHelper.sqlconn(false);
            cmd.CommandText = sqlStoredProcedure;
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.CommandTimeout = 180;   // 3 minutes

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
                cmd.Connection.Close();
            }

            return ds;
        }

        /// <summary>
        /// This returns one row from the returned dataset. use the DataHelper.CMD for the cmd parameters.
        /// </summary>
        /// <param name="sqlStoredProcedure"></param>
        /// <returns></returns>
        public DataRow GetDataRow(string sqlStoredProcedure)
        {
            data_err_msg = "";

            DataTable dt = GetDataTable(sqlStoredProcedure);
            if (dt == null) { return null; }
            if (dt.Rows.Count == 0) { return null; }

            return dt.Rows[0];
        }

    }
}