using LW_Common;
using LW_Data;
using LW_Web.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;
using System.Web.Mvc;

namespace LW_Web.Controllers
{
    public class ReportsController : BaseController
    {
        private readonly LWDbContext _context;  // Class-level field
        public ReportsController()
        {
            _context = new LWDbContext();
        }

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
            string fileNameAndPath = Server.MapPath("~/_Downloads/" + NewFileName);

            if (R.FillExcel_WOAnalysisReport(NewFileName, StartDate, EndDate))
            {
                //ViewBag.Message = "<div class=\"alert alert-success\"><strong><a href=\"\\_Downloads\\" + NewFileName + "\" target='_blank'>Download " + NewFileName + "</a></strong></div>";
                model.Error_log = "";
                return File(fileNameAndPath, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", NewFileName);
            }
            else
            {
                ViewBag.Message = R.error_message;
                model.Error_log = "<div class=\"alert alert-danger\"><strong>Error!</strong> Error creating download file.</div>";
                return View("ReportPage", model);
            }

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
            string fileNameAndPath = Server.MapPath("~/_Downloads/" + NewFileName);

            if (R.FillExcel_InventoryDailyPivotReport(NewFileName, StartDate, EndDate))
            {
                //ViewBag.Message3 = "<div class=\"alert alert-success\"><strong><a href=\"\\_Downloads\\" + NewFileName + "\" target='_blank'>Download " + NewFileName + "</a></strong></div>";
                model.Error_log3 = "";
                return File(fileNameAndPath, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", NewFileName);
            }
            else
            {
                ViewBag.Message3 = R.error_message;
                model.Error_log3 = "<div class=\"alert alert-danger\"><strong>Error!</strong> Error creating download file.</div>";
                return View("ReportPage", model);
            }

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
            string fileNameAndPath = Server.MapPath("~/_Downloads/" + NewFileName);

            if (R.FillExcel_POInventoryItemReviewReport(NewFileName, StartDate, EndDate))
            {
                //ViewBag.MessagePOI = "<div class=\"alert alert-success\"><strong><a href=\"\\_Downloads\\" + NewFileName + "\" target='_blank'>Download " + NewFileName + "</a></strong></div>";
                model.Error_logPOI = "";
                return File(fileNameAndPath, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", NewFileName);
            }
            else
            {
                ViewBag.MessagePOI = R.error_message;
                model.Error_logPOI = "<div class=\"alert alert-danger\"><strong>Error!</strong> Error creating download file.</div>";
                return View("ReportPage", model);
            }

        }

        [HttpPost]
        public ActionResult GetVacancyCoverSheet(ReportPageModel model)
        {
            Server.ScriptTimeout = 1200;

            clsReportHelper R = new clsReportHelper();
            string BuildingCode = model.selectedBuildingCode;
            string AptNumber = model.selectedAptNumber;  

            if (string.IsNullOrEmpty(BuildingCode) || string.IsNullOrEmpty(AptNumber))
            {
                ViewBag.MessageVAC = R.error_message;
                model.Error_logVAC = "<div class=\"alert alert-danger\"><strong>*</strong> Choose a Property and Apartment.</div>";
                return View("ReportPage", model);
            }

            string NewFileName = "VacancyCoverSheet_" + BuildingCode + "_" + AptNumber + "_" + DateTime.Now.ToString("yyyyMMdd") + ".xlsx";
            string fileNameAndPath = Server.MapPath("~/_Downloads/" + NewFileName);

            if (R.FillExcel_VacancyCoverSheet(NewFileName, BuildingCode, AptNumber))
            {
                model.Error_logVAC = "";
                return File(fileNameAndPath, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", NewFileName);
            }
            else
            {
                ViewBag.MessageVAC = R.error_message;
                model.Error_logVAC = "<div class=\"alert alert-danger\"><strong>Error!</strong> Error creating download file.</div>";

                model.selectedBuildingCode = BuildingCode;
                model.selectedAptNumber = AptNumber;

                // Excluding properties that have all EXCLUDED units
                model.Properties = _context.tblProperties
                    .Where(p => !p.isInactive && _context.tblPropertyUnits.Any(u => u.yardiPropertyRowID == p.yardiPropertyRowID && !u.isExcluded))
                    .OrderBy(p => p.buildingCode)
                    .Select(p => new SelectListItem
                    {
                        Value = p.buildingCode,
                        Text = string.Concat(p.buildingCode, " - ", (p.addr1_Co ?? "n/a").ToUpper()) // Concatenate in the DB query
                    })
                    .ToList();

                model.AptNumbers = GetApartmentsByProperty_List(BuildingCode);

                return View("ReportPage", model);
            }

        }

        public List<SelectListItem> GetApartmentsByProperty_List(string lookupBuildingCode)
        {
            if (string.IsNullOrEmpty(lookupBuildingCode))
            {
                return new List<SelectListItem>();
            }

            var apartments = (from u in _context.tblPropertyUnits
                              join p in _context.tblProperties
                              on u.yardiPropertyRowID equals p.yardiPropertyRowID
                              where (p.buildingCode == lookupBuildingCode && !u.isExcluded)
                              orderby u.AptNumber
                              select new SelectListItem
                              {
                                  Value = u.AptNumber.ToString(),
                                  Text = u.AptNumber + (u.StatusBasedOnDates == "Vacant" ? " (Vacant)" : "")
                              })
                              .ToList();

            return apartments;
        }

        [HttpGet]
        public JsonResult GetApartmentsByProperty(string lookupBuildingCode)
        {
            var apartments = GetApartmentsByProperty_List(lookupBuildingCode);
            return Json(apartments, JsonRequestBehavior.AllowGet);
        }

    }
}
