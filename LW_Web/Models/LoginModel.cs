using LW_Common;
using LW_Data;
using System.ComponentModel;

namespace LW_Web.Models
{
    public class LoginModel
    {
        // jrebuth@lemlewolff.com // jre5925#lemlewolff

        public LoginModel() { }
        public string Error_log { get; set; }    // Imports
        public string DevEnv_msg = (clsDataHelper.sqlconn(false).ConnectionString.Contains("_dev;") ? clsWebFormHelper.BasicMsgBoxHTML("DEV DATABASE") : "");

        [DisplayName("Email Address")]
        public string EmailAddress { get; set; }

        [DisplayName("Password")]
        public string Password { get; set; }

        [DisplayName("Remember me")]
        public bool RememberMe { get; set; }

    }
}