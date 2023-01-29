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
        public ImportFilesModel(string selectedValue = "")
        {
            ImportFileList = new List<SelectListItem>();
            ImportFileList.Add(new SelectListItem { Text = "ADP", Value = "ADP", Selected=(selectedValue == "ADP" ? true : false) });
            ImportFileList.Add(new SelectListItem { Text = "AMC Time", Value = "AMC", Selected = (selectedValue == "AMC" ? true : false) });
            ImportFileList.Add(new SelectListItem { Text = "Sortly", Value = "Sortly", Selected = (selectedValue == "Sortly" ? true : false) });
            ImportFileList.Add(new SelectListItem { Text = "Yardi", Value = "Yardi", Selected = (selectedValue == "Yardi" ? true : false) });
        }

        [DisplayName("ImportFileList")]
        public List<SelectListItem> ImportFileList { get; set; }

        [DisplayName("file")]
        public HttpPostedFileBase UploadedFile { get; set; }

        [DisplayName("Name of Worksheet (if more than 1)")]
        public string WorkSheetName { get; set; }

        public string Error_log { get; set; }
    }
}