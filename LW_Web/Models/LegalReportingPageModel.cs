using LW_Common;
using LW_Security;
using System.Collections.Generic;
using System.ComponentModel;
using System.Web;
using System.Web.Mvc;

namespace LW_Web.Models
{
    public class LegalReportingPageModel
    {
        public LegalReportingPageModel() { 
            
            // Security
            if (!(clsSecurity.isUserLoggedIn() && (clsSecurity.isSuperAdmin() || clsSecurity.isLegalTeam())))
            {
                PageAccessDenied = true;
            }
        }

        public bool PageAccessDenied { get; set; } = false;

        [DisplayName("Range Loaded: ")]
        public string LoadedRangeText { get; set; }

        [DisplayName("Tenant Arrears Reporting Month")]
        public string ArrearsReportDate { get; set; }    // will end up being rounded to month end

        [DisplayName("Property")]
        public List<SelectListItem> Properties { get; set; }
        public string selectedBuildingCode { get; set; }   // Selected Property

        public string Error_log { get; set; }    // Imports
    }
}