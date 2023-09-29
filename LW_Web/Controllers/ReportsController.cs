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
        public ActionResult GetWOAnalysisReport(bool pass = true)
        {
            Server.ScriptTimeout = 1200;
            ImportFilesModel model = new ImportFilesModel();

            clsReportHelper R = new clsReportHelper();
            string NewFileName = "WOAnalysis_" + DateTime.Now.ToString("yy-MM-dd") + ".xlsx";

            if (R.FillExcel_WOAnalysisReport(NewFileName))
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
        public ActionResult Reports()
        {
            Reportsmodel model = new Reportsmodel();

            // Read form Response 
            string StartDate = Request["StartDate"];
            string EndDate = Request["EndDate"];
            ViewBag.Message = "";

            SqlCommand cmd = new SqlCommand();
            cmd.Parameters.AddWithValue("@StartDate", StartDate);
            cmd.Parameters.AddWithValue("@EndDate", EndDate);

            DataTable dt = new DataTable();
            clsDataHelper H = new clsDataHelper();
            dt = H.GetDataTableCMD("spReport_Master2", ref cmd);

            if (H.data_err_msg != "")
            {
                model.Error_log = "<span style=color:red;>" + H.data_err_msg + "</span>";
                ViewBag.Message = clsWebFormHelper.ErrorBoxMsgHTML("Error processing");
            }
            else
            {
                string document = LW_Common.clsUtilities.DataTableToDelimitedFile(ref dt, "\t");

                if (document.StartsWith("ERROR:") || document == "")
                {
                    model.Error_log = document;
                    ViewBag.Message = clsWebFormHelper.ErrorBoxMsgHTML("Error creating export file");
                }

                var stream = new MemoryStream(Encoding.UTF8.GetBytes(document ?? ""));
                return File(stream, "text/tab-separated-values", "MASTER-" + DateTime.Now.ToString("yyyyMMdd-hhmmss") + ".xls");
            }

            return View(model);
        }
    }
}
