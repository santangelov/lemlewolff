﻿using System.Web.Mvc;
using System.Web.Routing;

namespace LW_Web
{
    public class RouteConfig
    {
        public static void RegisterRoutes(RouteCollection routes)
        {
            routes.IgnoreRoute("{resource}.axd/{*pathInfo}");
            //routes.MapMvcAttributeRoutes();

            routes.MapRoute(
                name: "Import",
                url: "Import/{action}/{filetype}",
                defaults: new { controller = "Import", action = "ImportFile", filetype = UrlParameter.Optional });

            routes.MapRoute(
                name: "ReportPage",
                url: "ReportPage/{action}/{filetype}",
                defaults: new { controller = "ReportPage", action = "Index", filetype = UrlParameter.Optional });

            routes.MapRoute(
                name: "Default",
                url: "{controller}/{action}/{id}",
                defaults: new { controller = "Home", action = "Index", id = UrlParameter.Optional });

            routes.MapRoute(
                name: "Reports",
                url: "{controller}/{action}/{id}",
                defaults: new { controller = "Reports", action = "Index", id = UrlParameter.Optional });

            routes.MapRoute(
                name: "Dashboard",
                url: "{controller}/{action}/{id}",
                defaults: new { controller = "Dashboard", action = "Index", id = UrlParameter.Optional });

        }
    }
}
