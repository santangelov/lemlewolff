using LW_Common.Documents;
using System.Configuration;
using System.Data.Entity;
using System.Web.Mvc;
using System.Web.Routing;

namespace LW_Web
{
    public class MvcApplication : System.Web.HttpApplication
    {
        protected void Application_Start()
        {
            SyncfusionDocumentEngine.RegisterLicense(ConfigurationManager.AppSettings["SyncfusionLicenseKey"]);

            AreaRegistration.RegisterAllAreas();
            RouteConfig.RegisterRoutes(RouteTable.Routes);
            Database.SetInitializer<LW_Data.LWDbContext>(null);
        }
    }
}
