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
        private static readonly byte[] Key = Encoding.UTF8.GetBytes("jmialjur&^%5676453524243"); // 16, 24, or 32 bytes
        private static readonly byte[] IV = Encoding.UTF8.GetBytes("IVIVforLEMLEwlo9"); // 16 bytes

        public clsSecurity() { }

        public string ErrorMsg { get; set; }

        public string FullName { get; set; }
        public string FirstName { get; set; }
        public string UserLevel { get; set; }
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
        public static string LoggedInUserFirstName()
        {
            return clsFunc.CastToStr(HttpContext.Current.Session["FirstName"]);
        }
        public static string LoggedInUserFullName()
        {
            return clsFunc.CastToStr(HttpContext.Current.Session["FullName"]);
        }
        public static string LoggedInUserLevel()
        {
            return clsFunc.CastToStr(HttpContext.Current.Session["UserLevel"]);
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
            HttpContext.Current.Session["FirstName"] = null;
            HttpContext.Current.Session["UserLevel"] = null;
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
            DataRow r = dh.GetDataRow("spUsers");

            if (r is null) 
            { 
                if (LogInTheUser)
                {
                    // If not found then we log out the user essentially
                    FullName = "";
                    FirstName = "";
                    UserLevel = "";
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
                    FirstName = r["FirstName"].ToString();
                    UserLevel = r["UserLevel"].ToString();
                    EmailAddress = r["EmailAddress"].ToString();
                    Password_Enc = r["Password_Enc"].ToString();
                    Password = clsSecurity.DecryptString(r["Password_Enc"].ToString());

                    HttpContext.Current.Session["IsAdminLoggedIn"] = r["isAdmin"];
                    HttpContext.Current.Session["IsLoggedIn"] = true;
                    HttpContext.Current.Session["FullName"] = FullName;
                    HttpContext.Current.Session["FirstName"] = FirstName;
                    HttpContext.Current.Session["UserLevel"] = UserLevel;
                    HttpContext.Current.Session["EmailAddress"] = EmailAddress;
                    HttpContext.Current.Session["UserID"] = clsFunc.CastToInt(r["UserID"], -1);
                }
                return true;
            }
        }


        public static string EncryptString(string plainText)
        {
            using (var aesAlg = Aes.Create())
            {
                aesAlg.Key = Key;
                aesAlg.IV = IV;

                var encryptor = aesAlg.CreateEncryptor(aesAlg.Key, aesAlg.IV);

                using (var msEncrypt = new MemoryStream())
                {
                    using (var csEncrypt = new CryptoStream(msEncrypt, encryptor, CryptoStreamMode.Write))
                    {
                        using (var swEncrypt = new StreamWriter(csEncrypt))
                        {
                            swEncrypt.Write(plainText);
                        }
                    }

                    return Convert.ToBase64String(msEncrypt.ToArray());
                }
            }
        }

        public static string DecryptString(string cipherText)
        {
            var cipherBytes = Convert.FromBase64String(cipherText);

            using (var aesAlg = Aes.Create())
            {
                aesAlg.Key = Key;
                aesAlg.IV = IV;

                var decryptor = aesAlg.CreateDecryptor(aesAlg.Key, aesAlg.IV);

                using (var msDecrypt = new MemoryStream(cipherBytes))
                {
                    using (var csDecrypt = new CryptoStream(msDecrypt, decryptor, CryptoStreamMode.Read))
                    {
                        using (var srDecrypt = new StreamReader(csDecrypt))
                        {
                            return srDecrypt.ReadToEnd();
                        }
                    }
                }
            }
        }

        //public static string EncryptString(string plaintext)
        //{
        //    string key = clsDataHelper.ENCRYPTION_KEY;

        //    // Convert the plaintext string to a byte array
        //    byte[] plaintextBytes = System.Text.Encoding.UTF8.GetBytes(plaintext);

        //    // Derive a new password using the PBKDF2 algorithm and a random salt
        //    Rfc2898DeriveBytes passwordBytes = new Rfc2898DeriveBytes(key, 20);

        //    // Use the password to encrypt the plaintext
        //    Aes encryptor = Aes.Create();
        //    encryptor.Key = passwordBytes.GetBytes(32);
        //    encryptor.IV = passwordBytes.GetBytes(16);
        //    using (MemoryStream ms = new MemoryStream())
        //    {
        //        using (CryptoStream cs = new CryptoStream(ms, encryptor.CreateEncryptor(), CryptoStreamMode.Write))
        //        {
        //            cs.Write(plaintextBytes, 0, plaintextBytes.Length);
        //        }
        //        return Convert.ToBase64String(ms.ToArray());
        //    }
        //}


        //static string DecryptString(string encrypted)
        //{
        //    string key = clsDataHelper.ENCRYPTION_KEY;

        //    // Convert the encrypted string to a byte array
        //    byte[] encryptedBytes = Convert.FromBase64String(encrypted);

        //    // Derive the password using the PBKDF2 algorithm
        //    Rfc2898DeriveBytes passwordBytes = new Rfc2898DeriveBytes(key, 20);

        //    // Use the password to decrypt the encrypted string
        //    Aes encryptor = Aes.Create();
        //    encryptor.Key = passwordBytes.GetBytes(32);
        //    encryptor.IV = passwordBytes.GetBytes(16);
        //    using (MemoryStream ms = new MemoryStream())
        //    {
        //        using (CryptoStream cs = new CryptoStream(ms, encryptor.CreateDecryptor(), CryptoStreamMode.Write))
        //        {
        //            cs.Write(encryptedBytes, 0, encryptedBytes.Length);
        //        }
        //        return System.Text.Encoding.UTF8.GetString(ms.ToArray());
        //    }
        //}

    }

}
