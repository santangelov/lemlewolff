﻿using LW_Common;
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
    public class ReportsController : BaseController
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

            DateTime StartDate_dt = clsFunc.CastToDateTime(StartDate, new DateTime(1900, 1, 1));
            DateTime EndDate_dt = clsFunc.CastToDateTime(EndDate, new DateTime(2099, 1, 1));

            string NewFileName = "PortalReport_WOAnalysis_" + StartDate_dt.ToString("yyyyMMdd") + "-" + EndDate_dt.ToString("yyyyMMdd") + ".xlsm";

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

            if (string.IsNullOrEmpty(StartDate) || string.IsNullOrEmpty(EndDate)) 
            {
                ViewBag.Message3 = R.error_message;
                model.Error_log3 = "<div class=\"alert alert-danger\"><strong>*</strong> Choose a Date Range.</div>";
                return View("ImportInventoryFiles", model);
            }

            string NewFileName = "PortalReport_InventoryByDay_" + DateTime.Parse(StartDate).ToString("yyyyMMdd") + " to " + DateTime.Parse(EndDate).ToString("yyyyMMdd") + ".xlsx";

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
