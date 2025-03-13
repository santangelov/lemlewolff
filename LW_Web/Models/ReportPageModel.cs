using LW_Common;
using LW_Security;
using System.Collections.Generic;
using System.ComponentModel;
using System.Web;
using System.Web.Mvc;

namespace LW_Web.Models
{
    public class ReportPageModel
    {
        public ReportPageModel() { 
            
            // Security
            if (clsSecurity.isUserLoggedIn() && !(clsSecurity.isSuperAdmin() || clsSecurity.isUserAdmin()))
            {
                DisableWOReports = true;
                DisableINVReports = true;
                DisableItemReviewReport = true;
            }
            
        }

        public bool DisableWOReports { get; set; } = false;
        public bool DisableINVReports { get; set; } = false;
        public bool DisableItemReviewReport { get; set; } = false;
        public bool DisableVacancyCoverSheets { get; set; } = false;

        [DisplayName("Analysis Report Start Date (inclusive)")]
        public string StartDateA { get; set; }

        [DisplayName("Analysis Report End Date (not-inclusive)")]
        public string EndDateA { get; set; }

        [DisplayName("Inventory Report Start Date (inclusive)")]
        public string StartDateI { get; set; }

        [DisplayName("Inventory Report End Date (not-inclusive)")]
        public string EndDateI { get; set; }

        [DisplayName("PO Inventory Item Review Report Start Date (inclusive)")]
        public string StartDatePOI { get; set; }

        [DisplayName("PO Inventory Item Review Report End Date (not-inclusive)")]
        public string EndDatePOI { get; set; }

        [DisplayName("Range Loaded: ")]
        public string LoadedRangeText { get; set; }

        [DisplayName("Property")]
        public List<SelectListItem> Properties { get; set; }
        public string selectedBuildingCode { get; set; }   // Selected Property

        [DisplayName("Apartment Number")]
        public List<SelectListItem> AptNumbers { get; set; }
        public string selectedAptNumber { get; set; }   // Selected Apartment


        public string Error_log { get; set; }    // Imports
        public string Error_log2 { get; set; }   // Maintenance
        public string Error_log3 { get; set; }   // Reports
        public string Error_logPOI { get; set; }   // PO Inventory Item Report Errors
        public string Error_logVAC { get; set; }   // Vacancy Cover Sheet
    }
}