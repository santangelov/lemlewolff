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
        public string ErrorMessageHtml { get; set; }
    }
}
