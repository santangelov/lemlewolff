using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Web;

namespace LW_Web.Models
{
    public class LoginModel
    {

        public LoginModel() { }
        public string Error_log { get; set; }    // Imports

        [DisplayName("Email Address")]
        public string EmailAddress { get; set; }

        [DisplayName("Password")]
        public string Password { get; set; }

        [DisplayName("Remember me")]
        public bool RememberMe { get; set; }

    }
}