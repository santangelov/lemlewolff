
using LW_Data;
using LW_Security;
using System.Linq;
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
        private readonly LWDbContext _context;

        public ExternalAppsController()
        {
            _context = new LWDbContext();
        }

        // GET: ExternalApps
        public ActionResult Index()
        {
            if (!clsSecurity.isUserLoggedIn())
            {
                return RedirectToAction("Index", "Login");
            }

            var apps = _context.tblAdminApps
                                .OrderBy(a => a.AppName)
                                .ToList();

            return View(apps);
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                _context.Dispose();
            }
            base.Dispose(disposing);

        }
    }
}
