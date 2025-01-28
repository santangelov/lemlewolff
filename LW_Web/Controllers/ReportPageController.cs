using LW_Common;
using LW_Web.Models;
using System.Web.Mvc;

namespace LW_Web.Controllers
{
    public class ReportPageController : BaseController
    {
        // GET: Home
        public ActionResult Index()
        {
            ReportPageModel mdl = new ReportPageModel();
            return View("ReportPage", mdl);
        }

        [HttpPost]
        public ActionResult Counter(string fileType)
        {
            clsCounter C = clsUtilities.ReadCounter(fileType);
            return Json(C);
        }

    }
}