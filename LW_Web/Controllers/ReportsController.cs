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
