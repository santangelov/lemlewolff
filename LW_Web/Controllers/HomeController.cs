using LW_Web.Models;
using System.Web.Mvc;

namespace LW_Web.Controllers
{
    public class HomeController : Controller
    {
        // GET: Home
        public ActionResult Index()
        {
            LoginModel mdl = new LoginModel();
            return View("Login", mdl);
        }
    }
}