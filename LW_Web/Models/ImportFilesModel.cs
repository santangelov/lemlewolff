using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.ComponentModel;
using System.Web.Mvc;
using System.Reflection;
using System.ComponentModel.DataAnnotations;
using LW_Common;

namespace LW_Web.Models
{
    public class ImportFilesModel
    {
        public ImportFilesModel()
        {
            ImportFileList = new List<SelectListItem>();
            ImportFileList.Add(new SelectListItem { Text = "ADP", Value = "ADP", Selected=(SelectedFile == "ADP" ? true : false) });
            ImportFileList.Add(new SelectListItem { Text = "Sortly (xlsx)", Value = "Sortly", Selected = (SelectedFile == "Sortly" ? true : false) });
            ImportFileList.Add(new SelectListItem { Text = "Yardi Work Orders (CSV)", Value = "YardiWO", Selected = (SelectedFile == "YardiWO" ? true : false) });
            ImportFileList.Add(new SelectListItem { Text = "Yardi POs (CSV)", Value = "YardiPO", Selected = (SelectedFile == "YardiPO" ? true : false) });

            // Look up the Import Dates
            clsReportHelper RH = new clsReportHelper();
            SortlyDateRangeLoaded = clsReportHelper.GetFileDateRangeValues("Sortly").DateRangeAsString;
            YardiWODateRangeLoaded = clsReportHelper.GetFileDateRangeValues("YardiWO_File").DateRangeAsString;
            YardiPODateRangeLoaded = clsReportHelper.GetFileDateRangeValues("YardiPO_File").DateRangeAsString;
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

        [DisplayName("Sortly Date Range Loaded")]
        public string SortlyDateRangeLoaded { get; set; }

        [DisplayName("Yardi WO Date Range Loaded")]
        public string YardiWODateRangeLoaded { get; set; }

        [DisplayName("Yardi WO Date Range Loaded")]
        public string YardiPODateRangeLoaded { get; set; }

        public string Error_log { get; set; }    // Imports
        public string Error_log2 { get; set; }   // Maintenance
        public string Error_log3 { get; set; }   // Reports

    }
}