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
    public class ImportInventoryModel
    {
        public ImportInventoryModel()
        {
            ImportFileList = new List<SelectListItem>();
            ImportFileList.Add(new SelectListItem { Text = "Yardi Work Orders for Inventory (CSV)", Value = "YardiWO", Selected = (SelectedFile == "YardiWO" ? true : false) });
            ImportFileList.Add(new SelectListItem { Text = "Yardi POs (CSV)", Value = "YardiPO", Selected = (SelectedFile == "YardiPO" ? true : false) });
            ImportFileList.Add(new SelectListItem { Text = "Yardi Work Orders for Historical Data (CSV)", Value = "YardiWOH", Selected = (SelectedFile == "YardiWOH" ? true : false) });

            // Get the Range of dates from the loaded data
            clsDataHelper dh = new clsDataHelper();
            DataTable t = dh.GetDataTable("spInventoryReportStats");

            if (string.IsNullOrEmpty(t.Rows[0]["EarliestDate"].ToString()) || string.IsNullOrEmpty(t.Rows[0]["LatestDate"].ToString()) )
            {
                this.LoadedRangeText = "No Data Loaded (or error in the DateOfSale column)";
            } 
            else
            {
                string _StartDateLoaded = DateTime.Parse(clsFunc.CastToStr(t.Rows[0]["EarliestDate"])).ToString("MM/dd/yyyy");
                string _EndDateLoaded   = DateTime.Parse(clsFunc.CastToStr(t.Rows[0]["LatestDate"])).ToString("MM/dd/yyyy");
                if (String.IsNullOrEmpty(this.StartDate)) this.StartDate = _StartDateLoaded;
                if (String.IsNullOrEmpty(this.EndDate)) this.EndDate = _EndDateLoaded;
                this.LoadedRangeText = "Date Range Loaded: " + StartDate + " to " + EndDate;
            } 
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

        public string Error_log { get; set; }    // Imports
        public string Error_log2 { get; set; }   // Maintenance
        public string Error_log3 { get; set; }   // Reports

    }
}