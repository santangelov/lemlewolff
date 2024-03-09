using LW_Common;
using LW_Data;
using System;
using System.Collections.Generic;
using System.Data;
using System.IO;
using System.Net;
using System.Runtime.CompilerServices;
using System.Security.Cryptography;
using System.Text;
using System.Threading;
using System.Web;

namespace LW_Security
{
    public class clsSecurity
    {
        public clsSecurity() { }

        public string ErrorMsg { get; set; }

        public string FullName { get; set; }
        public string EmailAddress { get; set; }
        public string Password { get; set; }
        public string Password_Enc { get; set; }

        public static bool isUserLoggedIn()
        {
            return clsFunc.CastToBool(HttpContext.Current.Session["IsLoggedIn"], false);
        }
        public static bool isUserAdmin()
        {
            return clsFunc.CastToBool(HttpContext.Current.Session["IsAdminLoggedIn"], false);
        }
        public static string LoggedInUserFullName()
        {
            return clsFunc.CastToStr(HttpContext.Current.Session["FullName"]);
        }
        public static string LoggedInUserEmail()
        {
            return clsFunc.CastToStr(HttpContext.Current.Session["EmailAddress"]);
        }
        public static int LoggedInUserID()
        {
            return clsFunc.CastToInt(HttpContext.Current.Session["UserID"], -1);
        }

        public bool LogOutUser()
        {
            HttpContext.Current.Session["IsAdminLoggedIn"] = null;
            HttpContext.Current.Session["IsLoggedIn"] = false;
            HttpContext.Current.Session["FullName"] = null;
            HttpContext.Current.Session["EmailAddress"] = null;
            HttpContext.Current.Session["UserID"] = null;

            return true;
        }

        public bool ValidateLogin(string emailAddress, string passwordNotEncrypted, bool LogInTheUser = false)
        {
            if (string.IsNullOrEmpty(emailAddress) || string.IsNullOrEmpty(passwordNotEncrypted)) { return false; }

            string pw_enc = EncryptString(passwordNotEncrypted);
            clsDataHelper dh = new clsDataHelper();
            dh.cmd.Parameters.AddWithValue("@emailAddress", emailAddress);
            dh.cmd.Parameters.AddWithValue("@password_enc", pw_enc);
            dh.cmd.Parameters.AddWithValue("@password_enc", pw_enc);
            DataRow r = dh.GetDataRow("spUsers");

            if (r is null) 
            { 
                if (LogInTheUser)
                {
                    // If not found then we log out the user essentially
                    FullName = "";
                    EmailAddress = "";
                    Password = "";
                    Password_Enc = "";

                    LogOutUser();
                }
                return false;
            }
            else
            {
                if (LogInTheUser)
                {
                    FullName = r["FullName"].ToString();
                    EmailAddress = r["EmailAddress"].ToString();
                    Password_Enc = r["Password_Enc"].ToString();
                    Password = clsSecurity.DecryptString(r["Password_Enc"].ToString());

                    HttpContext.Current.Session["IsAdminLoggedIn"] = r["isAdmin"];
                    HttpContext.Current.Session["IsLoggedIn"] = true;
                    HttpContext.Current.Session["FullName"] = FullName;
                    HttpContext.Current.Session["EmailAddress"] = EmailAddress;
                    HttpContext.Current.Session["UserID"] = clsFunc.CastToInt(r["UserID"], -1);
                }
                return true;
            }
        }

        public static string EncryptString(string plainText)
        {
            byte[] iv = new byte[16];
            byte[] array;
            string key = clsDataHelper.ENCRYPTION_KEY;

            using (Aes aes = Aes.Create())
            {
                aes.Key = Encoding.UTF8.GetBytes(key);
                aes.IV = iv;

                ICryptoTransform encryptor = aes.CreateEncryptor(aes.Key, aes.IV);

                using (MemoryStream memoryStream = new MemoryStream())
                {
                    using (CryptoStream cryptoStream = new CryptoStream((Stream)memoryStream, encryptor, CryptoStreamMode.Write))
                    {
                        using (StreamWriter streamWriter = new StreamWriter((Stream)cryptoStream))
                        {
                            streamWriter.Write(plainText);
                        }

                        array = memoryStream.ToArray();
                    }
                }
            }

            return Convert.ToBase64String(array);
        }

        public static string DecryptString(string string_enc)
        {
            byte[] iv = new byte[16];
            byte[] buffer = Convert.FromBase64String(string_enc);
            string key = clsDataHelper.ENCRYPTION_KEY;

            using (Aes aes = Aes.Create())
            {
                aes.Key = Encoding.UTF8.GetBytes(key);
                aes.IV = iv;
                ICryptoTransform decryptor = aes.CreateDecryptor(aes.Key, aes.IV);

                using (MemoryStream memoryStream = new MemoryStream(buffer))
                {
                    using (CryptoStream cryptoStream = new CryptoStream((Stream)memoryStream, decryptor, CryptoStreamMode.Read))
                    {
                        using (StreamReader streamReader = new StreamReader((Stream)cryptoStream))
                        {
                            return streamReader.ReadToEnd();
                        }
                    }
                }
            }
        }


    }

}
