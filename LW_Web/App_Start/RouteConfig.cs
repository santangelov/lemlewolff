using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using System.Web.Routing;

namespace LW_Web
{
    public class RouteConfig
    {
        public static void RegisterRoutes(RouteCollection routes)
        {
            routes.IgnoreRoute("{resource}.axd/{*pathInfo}");

            routes.MapRoute(
                name: "Import",
                url: "Import/{action}/{filetype}",
                defaults: new { controller = "Import", action = "ImportFiles", filetype = UrlParameter.Optional });
            
            routes.MapRoute(
                name: "ImportInventory",
                url: "ImportInventory/{action}/{filetype}",
                defaults: new { controller = "ImportInventory", action = "ImportInventoryFiles", filetype = UrlParameter.Optional });

            routes.MapRoute(
                name: "Reports",
                url: "Reports/{action}/{filetype}",
                defaults: new { controller = "Reports", action = "Reports", filetype = UrlParameter.Optional });

            routes.MapRoute(
                name: "Default",
                url: "{controller}/{action}/{id}",
                defaults: new { controller = "Home", action = "Index", id = UrlParameter.Optional });
        }
    }
}
