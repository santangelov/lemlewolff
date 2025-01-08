using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.ComponentModel;
using System.Web.Mvc;
using System.Reflection;
using System.ComponentModel.DataAnnotations;
using LW_Data;
using System.Data;
using System.Data.SqlClient;
using LW_Common;

namespace LW_Web.Models
{
    public class ReportPageModel
    {
        public ReportPageModel()
        {
            //ImportFileList = new List<SelectListItem>();
            //ImportFileList.Add(new SelectListItem { Text = "3 - Yardi Work Orders for Inventory (CSV)", Value = "YardiWO", Selected = (SelectedFile == "YardiWO" ? true : false) });
            //ImportFileList.Add(new SelectListItem { Text = "4 - Yardi POs (CSV)", Value = "YardiPO", Selected = (SelectedFile == "YardiPO" ? true : false) });
            //ImportFileList.Add(new SelectListItem { Text = "5 - Yardi Work Orders for Historical Data (CSV)", Value = "YardiWOH", Selected = (SelectedFile == "YardiWOH" ? true : false) });


            // Look up the Import Dates
            //clsReportHelper RH = new clsReportHelper();
            //YardiWODateRangeLoaded = clsReportHelper.GetFileDateRangeValues("YardiWO_Inventory").DateRangeAsString;
            //YardiPODateRangeLoaded = clsReportHelper.GetFileDateRangeValues("YardiPO_Inventory").DateRangeAsString;
            //YardiWOGeneralDateRangeLoaded = clsReportHelper.GetFileDateRangeValues("YardiWO_GeneralFile").DateRangeAsString;
        }
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