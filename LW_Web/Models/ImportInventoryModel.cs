﻿using System;
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
    public class ImportInventoryModel
    {
        public ImportInventoryModel()
        {
            ImportFileList = new List<SelectListItem>();
            ImportFileList.Add(new SelectListItem { Text = "3 - Yardi Work Orders for Inventory (CSV)", Value = "YardiWO", Selected = (SelectedFile == "YardiWO" ? true : false) });
            ImportFileList.Add(new SelectListItem { Text = "4 - Yardi POs (CSV)", Value = "YardiPO", Selected = (SelectedFile == "YardiPO" ? true : false) });
            ImportFileList.Add(new SelectListItem { Text = "5 - Yardi Work Orders for Historical Data (CSV)", Value = "YardiWOH", Selected = (SelectedFile == "YardiWOH" ? true : false) });


            // Look up the Import Dates
            clsReportHelper RH = new clsReportHelper();
            YardiWODateRangeLoaded = clsReportHelper.GetFileDateRangeValues("YardiWO_Inventory").DateRangeAsString;
            YardiPODateRangeLoaded = clsReportHelper.GetFileDateRangeValues("YardiPO_Inventory").DateRangeAsString;
            YardiWOGeneralDateRangeLoaded = clsReportHelper.GetFileDateRangeValues("YardiWO_GeneralFile").DateRangeAsString;
        }

        [DisplayName("Import File List")]
        public List<SelectListItem> ImportFileList { get; set; }

        [DisplayName("Selected File")]
        public string SelectedFile { get; set; }

        [DisplayName("The File")]
        public HttpPostedFileBase UploadedFile { get; set; }

        [DisplayName("Name of Worksheet (if more than 1)")]
        public string WorkSheetName { get; set; }

        [DisplayName("Start Date (inclusive)")]
        public string StartDate { get; set; }

        [DisplayName("End Date (not-inclusive)")]
        public string EndDate { get; set; }

        [DisplayName("Range Loaded: ")]
        public string LoadedRangeText { get; set; }

        [DisplayName("Yardi WO Date Range Loaded")]
        public string YardiWODateRangeLoaded { get; set; }

        [DisplayName("Yardi WO Date Range Loaded")]
        public string YardiPODateRangeLoaded { get; set; }

        [DisplayName("Yardi WO General Date Range Loaded")]
        public string YardiWOGeneralDateRangeLoaded { get; set; }

        public string Error_log { get; set; }    // Imports
        public string Error_log2 { get; set; }   // Maintenance
        public string Error_log3 { get; set; }   // Reports

    }
}