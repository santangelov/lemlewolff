using LW_Common;
using LW_Data;
using LW_Web.Models;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.ComponentModel.Composition.Primitives;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Reflection;
using System.Text;
using System.Web;
using System.Web.Mvc;

namespace LW_Web.Controllers
{
    public class ReportsController : Controller
    {
        // GET: Reports
        [HttpGet]
        public ActionResult Reports(bool pass = true)
        {
            Reportsmodel model = new Reportsmodel();
            model.Error_log = "";
            return View(model);
        }

        [HttpPost]
        public ActionResult GetWOAnalysisReport(ImportFilesModel model)
        {
            Server.ScriptTimeout = 1200;

            clsReportHelper R = new clsReportHelper();
            string StartDate = model.StartDate;  // Inclusive
            string EndDate = model.EndDate;   // Not-Inclusive
            string NewFileName = "WOAnalysis_" + DateTime.Now.ToString("yy-MM-dd") + ".xlsx";

            if (R.FillExcel_WOAnalysisReport(NewFileName, StartDate, EndDate))
            {
                ViewBag.Message3 = "<div class=\"alert alert-success\"><strong><a href=\"\\_Downloads\\" + NewFileName + "\" target='_blank'>Download " + NewFileName + "</a></strong></div>";
                model.Error_log3 = "";
            }
            else
            {
                ViewBag.Message3 = R.error_message;
                model.Error_log3 = "<div class=\"alert alert-danger\"><strong>Error!</strong> Error creating download file.</div>";
            }

            return View("ImportFile", model);
        }

        [HttpPost]
        public ActionResult GetInventoryReport(ImportInventoryModel model)
        {
            Server.ScriptTimeout = 1200;

            clsReportHelper R = new clsReportHelper();
            string StartDate = model.StartDate;  // Inclusive
            string EndDate = model.EndDate;   // Not-Inclusive
            string NewFileName = "Inventory_ByDay_" + DateTime.Parse(StartDate).ToString("yy-MM-dd") + " to " + DateTime.Parse(EndDate).ToString("yy-MM-dd") + ".xlsx";

            if (R.FillExcel_InventoryDailyPivotReport(NewFileName, StartDate, EndDate))
            {
                ViewBag.Message3 = "<div class=\"alert alert-success\"><strong><a href=\"\\_Downloads\\" + NewFileName + "\" target='_blank'>Download " + NewFileName + "</a></strong></div>";
                model.Error_log3 = "";
            }
            else
            {
                ViewBag.Message3 = R.error_message;
                model.Error_log3 = "<div class=\"alert alert-danger\"><strong>Error!</strong> Error creating download file.</div>";
            }

            return View("ImportInventoryFiles", model);
        }

    }
}
