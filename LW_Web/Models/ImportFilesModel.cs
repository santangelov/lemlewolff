using LW_Common;
using System.Collections.Generic;
using System.ComponentModel;
using System.Web;
using System.Web.Mvc;

namespace LW_Web.Models
{
    public class ImportFilesModel
    {
        public ImportFilesModel()
        {
            ImportFileList = new List<SelectListItem>();
            ImportFileList.Add(new SelectListItem { Text = "ADP", Value = "ADP", Selected = (SelectedFile == "ADP" ? true : false) });
            ImportFileList.Add(new SelectListItem { Text = "Sortly (xlsx)", Value = "Sortly", Selected = (SelectedFile == "Sortly" ? true : false) });
            ImportFileList.Add(new SelectListItem { Text = "Physical Count Import (xlsx)", Value = "PC", Selected = (SelectedFile == "PC" ? true : false) });
            ImportFileList.Add(new SelectListItem { Text = "1 - Yardi Work Orders (CSV)", Value = "YardiWO", Selected = (SelectedFile == "YardiWO" ? true : false) });
            ImportFileList.Add(new SelectListItem { Text = "2 - Yardi POs (CSV)", Value = "YardiPO", Selected = (SelectedFile == "YardiPO" ? true : false) });
            ImportFileList.Add(new SelectListItem { Text = "3 - Yardi Work Orders for Inventory (CSV)", Value = "YardiWO2", Selected = (SelectedFile == "YardiWO2" ? true : false) });
            ImportFileList.Add(new SelectListItem { Text = "4 - Yardi Inventory POs (CSV)", Value = "YardiPO2", Selected = (SelectedFile == "YardiPO2" ? true : false) });
            ImportFileList.Add(new SelectListItem { Text = "5 - Yardi Work Orders for Historical Data (CSV)", Value = "YardiWOH", Selected = (SelectedFile == "YardiWOH" ? true : false) });
            ImportFileList.Add(new SelectListItem { Text = "6 - Properties and Units (CSV)", Value = "YardiPAU", Selected = (SelectedFile == "YardiPAU" ? true : false) });

            // Look up the Import Dates
            clsReportHelper RH = new clsReportHelper();
            SortlyDateRangeLoaded = clsReportHelper.GetFileDateRangeValues("Sortly").DateRangeAsString;
            YardiWODateRangeLoaded = clsReportHelper.GetFileDateRangeValues("YardiWO_File").DateRangeAsString;
            YardiPODateRangeLoaded = clsReportHelper.GetFileDateRangeValues("YardiPO_File").DateRangeAsString;
            YardiWO2DateRangeLoaded = clsReportHelper.GetFileDateRangeValues("YardiWO_Inventory").DateRangeAsString;
            YardiPO2DateRangeLoaded = clsReportHelper.GetFileDateRangeValues("YardiPO_Inventory").DateRangeAsString;
            YardiWOGeneralDateRangeLoaded = clsReportHelper.GetFileDateRangeValues("YardiWO_GeneralFile").DateRangeAsString;
            YardiPropertyAndUnitDateRangeLoaded = clsReportHelper.GetFileDateRangeValues("YardiPropertyFile").DateRangeAsString;
            ADPDateRangeLoaded = clsReportHelper.GetFileDateRangeValues("ADP").DateRangeAsString;
        }

        [DisplayName("Import File List")]
        public List<SelectListItem> ImportFileList { get; set; }

        [DisplayName("Selected File")]
        public string SelectedFile { get; set; }

        [DisplayName("The File")]
        public HttpPostedFileBase UploadedFile { get; set; }

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

        [DisplayName("Yardi WO Date Range Loaded")]
        public string YardiWO2DateRangeLoaded { get; set; }

        [DisplayName("Yardi WO Date Range Loaded")]
        public string YardiPO2DateRangeLoaded { get; set; }

        [DisplayName("Yardi WO General Date Range Loaded")]
        public string YardiWOGeneralDateRangeLoaded { get; set; }

        [DisplayName("Yardi Property and Unit File Loaded")]
        public string YardiPropertyAndUnitDateRangeLoaded { get; set; }

        [DisplayName("ADP Date Range Loaded")]
        public string ADPDateRangeLoaded { get; set; }

        public string Error_log { get; set; }    // Imports
        public string Error_log2 { get; set; }   // Maintenance
        public string Error_log3 { get; set; }   // Reports

    }
}