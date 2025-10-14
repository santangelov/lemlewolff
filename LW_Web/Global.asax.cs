using System.Web.Mvc;
using System.Web.Routing;
using System.Data.Entity;

namespace LW_Web
{
    public class MvcApplication : System.Web.HttpApplication
    {
        protected void Application_Start()
        {
            AreaRegistration.RegisterAllAreas();
            RouteConfig.RegisterRoutes(RouteTable.Routes);
            Database.SetInitializer<LW_Data.LWDbContext>(null);
        }
    }
}
