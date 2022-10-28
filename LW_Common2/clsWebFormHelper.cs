using System;
using System.Collections.Generic;

namespace LW_Common
{
    public class clsWebFormHelper
    {
        public static string SuccessBoxMsgHTML(string msg)
        {
            return "<div class=\"alert alert-success\" role=\"alert\"><strong>" + msg + "</strong></div>";
        }

        public static string ErrorBoxMsgHTML(string msg)
        {
            return "<div class=\"alert alert-danger\" role=\"alert\"><strong>" + msg + "</strong></div>";
        }
    }
}
