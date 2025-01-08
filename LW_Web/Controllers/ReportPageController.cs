using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Net;
using System.Reflection;
using System.Runtime.Remoting.Contexts;
using System.Web;
using System.Web.Mvc;
using System.Web.WebPages;
using LW_Common;
using LW_Data;
using LW_Web.Models;

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