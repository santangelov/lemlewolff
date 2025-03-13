using LW_Web.Models;
using System.Web.Mvc;

namespace LW_Web.Controllers
{
    public class DashboardController : Controller
    {
        // GET: Home
        public ActionResult Index()
        {
            DashboardModel m = new DashboardModel();
            return View("Dashboard", m);
        }
    }
}