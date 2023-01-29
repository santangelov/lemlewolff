using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.ComponentModel;
using System.Web.Mvc;
using System.Reflection;
using System.ComponentModel.DataAnnotations;

namespace LW_Web.Models
{
    public class Reportsmodel
    {
        [DisplayName("Start Date")]
        public string StartDate { get; set; }

        [DisplayName("End Date")]
        public string EndDate { get; set; }

        public string Error_log { get; set; } = "";
    }
}