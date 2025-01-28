using System.ComponentModel;

namespace LW_Web.Models
{
    public class ReportPageModel
    {
        public ReportPageModel() { }

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

        public string Error_log { get; set; }    // Imports
        public string Error_log2 { get; set; }   // Maintenance
        public string Error_log3 { get; set; }   // Reports
        public string Error_logPOI { get; set; }   // PO Inventory Item Report Errors
    }
}