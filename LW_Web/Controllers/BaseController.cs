using LW_Security;
using System.Web.Mvc;

namespace LW_Web.Controllers
{
    public class BaseController : Controller
    {
        protected override void OnActionExecuting(ActionExecutingContext filterContext)
        {
            ViewBag.UserFirstName = clsSecurity.LoggedInUserFirstName();
            ViewBag.UserLevel = clsSecurity.LoggedInUserLevel();

            base.OnActionExecuting(filterContext);
        }
    }
}