using System.Web.Mvc;

namespace LW_Web.Controllers
{
    public class ExternalAppsController : Controller
    {
        // GET: ExternalApps
        public ActionResult Index()
        {
            return View("ExternalApps");
        }
    }
}
