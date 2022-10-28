using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.ComponentModel;
using System.Web.Mvc;

namespace LW_Web.Models
{
    public class ImportFilesModel
    {
        public ImportFilesModel()
        {
            ImportFileList = new List<SelectListItem>();
        }

        [DisplayName("ImportFileList")]
        public List<SelectListItem> ImportFileList
        {
            get;
            set;
        }

        
    }
}