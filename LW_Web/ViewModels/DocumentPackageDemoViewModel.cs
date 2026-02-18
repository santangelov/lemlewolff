using System;
using System.Collections.Generic;
using System.Web.Mvc;

namespace LW_Web.ViewModels
{
    public class DocumentPackageDemoViewModel
    {
        public List<SelectListItem> Buildings { get; set; } = new List<SelectListItem>();
        public List<SelectListItem> Units { get; set; } = new List<SelectListItem>();
        public int? SelectedBuildingId { get; set; }
        public string SelectedUnitIds { get; set; }
        public bool IncludeCoverSheet { get; set; } = true;
        public string ErrorMessageHtml { get; set; }
        public List<DocumentPackageHistoryItemViewModel> PrintHistory { get; set; } = new List<DocumentPackageHistoryItemViewModel>();
    }

    public class DocumentPackageHistoryItemViewModel
    {
        public int PrintHistoryId { get; set; }
        public DateTime CreatedDate { get; set; }
        public string CreatedByUser { get; set; }
        public int UnitCount { get; set; }
        public string FileName { get; set; }
    }
}
