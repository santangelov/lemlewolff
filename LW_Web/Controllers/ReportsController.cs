using LW_Common;
using LW_Web.Models;
using System;
using System.Web.Mvc;

namespace LW_Web.Controllers
{
    public class ReportsController : BaseController
    {

        [HttpPost]
        public ActionResult GetWOAnalysisReport(ReportPageModel model)
        {
            Server.ScriptTimeout = 1200;

            clsReportHelper R = new clsReportHelper();
            string StartDate = model.StartDateA;  // Inclusive
            string EndDate = model.EndDateA;   // Not-Inclusive

            if (string.IsNullOrEmpty(StartDate) || string.IsNullOrEmpty(EndDate))
            {
                ViewBag.Message = R.error_message;
                model.Error_log = "<div class=\"alert alert-danger\"><strong>*</strong> Choose a Date Range.</div>";
                return View("ReportPage", model);
            }

            DateTime StartDate_dt = clsFunc.CastToDateTime(StartDate, new DateTime(1900, 1, 1));
            DateTime EndDate_dt = clsFunc.CastToDateTime(EndDate, new DateTime(2099, 1, 1));

            string NewFileName = "PortalReport_WOAnalysis_" + StartDate_dt.ToString("yyyyMMdd") + "-" + EndDate_dt.ToString("yyyyMMdd") + ".xlsm";

            if (R.FillExcel_WOAnalysisReport(NewFileName, StartDate, EndDate))
            {
                ViewBag.Message = "<div class=\"alert alert-success\"><strong><a href=\"\\_Downloads\\" + NewFileName + "\" target='_blank'>Download " + NewFileName + "</a></strong></div>";
                model.Error_log = "";
            }
            else
            {
                ViewBag.Message = R.error_message;
                model.Error_log = "<div class=\"alert alert-danger\"><strong>Error!</strong> Error creating download file.</div>";
            }

            return View("ReportPage", model);
        }

        [HttpPost]
        public ActionResult GetInventoryReport(ReportPageModel model)
        {
            Server.ScriptTimeout = 1200;

            clsReportHelper R = new clsReportHelper();
            string StartDate = model.StartDateI;  // Inclusive
            string EndDate = model.EndDateI;   // Not-Inclusive

            if (string.IsNullOrEmpty(StartDate) || string.IsNullOrEmpty(EndDate))
            {
                ViewBag.Message3 = R.error_message;
                model.Error_log3 = "<div class=\"alert alert-danger\"><strong>*</strong> Choose a Date Range.</div>";
                return View("ReportPage", model);
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

            return View("ReportPage", model);
        }

        [HttpPost]
        public ActionResult GetPOInvItemReviewReport(ReportPageModel model)
        {
            Server.ScriptTimeout = 1200;

            clsReportHelper R = new clsReportHelper();
            string StartDate = model.StartDatePOI;  // Inclusive
            string EndDate = model.EndDatePOI;   // Not-Inclusive

            if (string.IsNullOrEmpty(StartDate) || string.IsNullOrEmpty(EndDate))
            {
                ViewBag.MessagePOI = R.error_message;
                model.Error_logPOI = "<div class=\"alert alert-danger\"><strong>*</strong> Choose a Date Range.</div>";
                return View("ReportPage", model);
            }

            string NewFileName = "PortalReport_POInventoryItemReview_" + DateTime.Parse(StartDate).ToString("yyyyMMdd") + " to " + DateTime.Parse(EndDate).ToString("yyyyMMdd") + ".xlsx";

            if (R.FillExcel_POInventoryItemReviewReport(NewFileName, StartDate, EndDate))
            {
                ViewBag.MessagePOI = "<div class=\"alert alert-success\"><strong><a href=\"\\_Downloads\\" + NewFileName + "\" target='_blank'>Download " + NewFileName + "</a></strong></div>";
                model.Error_logPOI = "";
            }
            else
            {
                ViewBag.MessagePOI = R.error_message;
                model.Error_logPOI = "<div class=\"alert alert-danger\"><strong>Error!</strong> Error creating download file.</div>";
            }

            return View("ReportPage", model);
        }

    }
}
