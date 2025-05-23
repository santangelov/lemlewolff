﻿using LW_Common;
using LW_Data;
using System;
using System.Data;
using System.IO;
using System.Linq;
using System.Runtime.Remoting.Contexts;
using System.Security.Cryptography;
using System.Text;
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
        public bool MatchedOnTempPW { get; set; }

        public static bool isUserLoggedIn()
        {
            return clsFunc.CastToBool(HttpContext.Current.Session["IsLoggedIn"], false);
        }
        public static bool isProjectManager()
        {
            return clsFunc.CastToBool(HttpContext.Current.Session["isProjectManager"], false);
        }
        public static bool isSuperAdmin()
        {
            return clsFunc.CastToBool(HttpContext.Current.Session["IsSuperAdminLoggedIn"], false);
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
            HttpContext.Current.Session["IsProjectManagerLoggedIn"] = null;
            HttpContext.Current.Session["IsAdminLoggedIn"] = null;
            HttpContext.Current.Session["IsSuperAdminLoggedIn"] = null;
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
                    MatchedOnTempPW = clsFunc.CastToBool(r["MatchedOnTempPW"], false);

                    HttpContext.Current.Session["IsProjectManagerLoggedIn"] = r["isProjectManager"];
                    HttpContext.Current.Session["IsAdminLoggedIn"] = r["isAdmin"];
                    HttpContext.Current.Session["IsSuperAdminLoggedIn"] = r["isSuperAdmin"];
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

        static string GenerateRandomPassword()
        {
            Random rand = new Random();
            int randomNumber = rand.Next(100000, 900001); // Upper bound is exclusive
            return randomNumber.ToString();
        }

        public bool changePassword(string emailAddress, string Password1, string Password2)
        {
            if (string.IsNullOrEmpty(emailAddress) || string.IsNullOrEmpty(Password1) || string.IsNullOrEmpty(Password2)) { this.ErrorMsg = "All fields are required."; return false; }
            if (Password1 != Password2) { this.ErrorMsg = "Passwords do not match."; return false; }

            string newPW_enc = EncryptString(Password1);

            clsUserRecord user = new clsUserRecord();
            user.GetUserByEmail(emailAddress);
            if (user.UserID == 0) { this.ErrorMsg = "User not found."; return false; }
            if (user.isDisabled) { this.ErrorMsg = "User is disabled."; return false; } 
            if (!user.ChangePassword(newPW_enc))
            {
                this.ErrorMsg = "Error changing password."; return false;
            }

            return true;
        }

        public bool InitiateForgotPassword(string emailAddress)
        {
            if (string.IsNullOrEmpty(emailAddress)) { return false; }

            string pw_enc = EncryptString(GenerateRandomPassword());
            clsDataHelper dh = new clsDataHelper();
            dh.cmd.Parameters.AddWithValue("@emailAddress", emailAddress);
            dh.cmd.Parameters.AddWithValue("@forgotPassword", 1);
            dh.cmd.Parameters.AddWithValue("@tempPassword_enc", pw_enc);
            // Save the new temp password 
            dh.ExecuteSPCMD("spUserUpdate");

            clsUserRecord user = new clsUserRecord();
            user.GetUserByEmail(emailAddress);
            if (user is null || user.UserID == 0) { this.ErrorMsg = "User not found."; return false; }

            string body = "<p>Your temporary password is: <strong>" + DecryptString(pw_enc) + "</strong><p><p>If you did not request a password reset, please ignore this email or contact our support team immediately.</p>";  

            /* Email the user the new password - returns false if cannot send email */
            return clsUtilities.SendEmail(emailAddress, "Password Reset", body);
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

    }

}
