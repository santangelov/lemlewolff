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
    public class ImportFilesModel
    {
        public ImportFilesModel()
        {
            ImportFileList = new List<SelectListItem>();
            ImportFileList.Add(new SelectListItem { Text = "ADP", Value = "ADP", Selected=(SelectedFile == "ADP" ? true : false) });
            ImportFileList.Add(new SelectListItem { Text = "Sortly (xlsx)", Value = "Sortly", Selected = (SelectedFile == "Sortly" ? true : false) });
            ImportFileList.Add(new SelectListItem { Text = "Yardi Work Orders (CSV)", Value = "YardiWO", Selected = (SelectedFile == "YardiWO" ? true : false) });
            ImportFileList.Add(new SelectListItem { Text = "Yardi POs (CSV)", Value = "YardiPO", Selected = (SelectedFile == "YardiPO" ? true : false) });
        }

        [DisplayName("Import File List")]
        public List<SelectListItem> ImportFileList { get; set; }

        [DisplayName("Selected File")]
        public string SelectedFile { get; set; }

        [DisplayName("The File")]
        public HttpPostedFileBase UploadedFile { get; set; }

        [DisplayName("Name of Worksheet (if more than 1)")]
        public string WorkSheetName { get; set; }

        public string Error_log { get; set; }    // Imports
        public string Error_log2 { get; set; }   // Maintenance
        public string Error_log3 { get; set; }   // Reports

        [DisplayName("Delete data before loading.")]
        public bool DeleteDataFirst { get; set; }
    }
}