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
    public class LegalReportingController : BaseController
    {
        private readonly LWDbContext _context;

        public LegalReportingController()
        {
            _context = new LWDbContext();
        }

        // GET: Home
        public ActionResult Index()
        {
            LegalReportingPageModel mdl = new LegalReportingPageModel();

            mdl.Properties = _context.tblProperties
                .Where(p => !p.isInactive && _context.tblPropertyUnits.Any(u => u.yardiPropertyRowID == p.yardiPropertyRowID && !u.isExcluded))
                .OrderBy(p => p.buildingCode)
                .Select(p => new SelectListItem
                {
                    Value = p.buildingCode,
                    Text = string.Concat(p.buildingCode, " - ", (p.addr1_Co ?? "n/a").ToUpper()) // Concatenate in the DB query
                })
                .ToList();

            mdl.Properties.Insert(0, new SelectListItem { Value = "", Text = "== PROPERTIES ==========" });
            mdl.Properties.Insert(0, new SelectListItem { Value = "List-Posting", Text = "Posting" });
            mdl.Properties.Insert(0, new SelectListItem { Value = "List-Aquinas", Text = "Aquinas" });   
            mdl.Properties.Insert(0, new SelectListItem { Value = "", Text = "== LISTS ===============" });

            mdl.selectedBuildingCode = "List-Posting";   // Make the default option -- The Posting List, All Properties in this list
            return View("LegalReportingPage", mdl);
        }

        [HttpPost]
        public ActionResult GetTenantArrearsReport(LegalReportingPageModel model)
        {
            Server.ScriptTimeout = 1200;

            clsReportHelper R = new clsReportHelper();
            string ReportDate = model.ArrearsReportDate;  // becomes month end

            if (string.IsNullOrEmpty(ReportDate))
            {
                ViewBag.Message = R.error_message;
                model.Error_log = "<div class=\"alert alert-danger\"><strong>*</strong> Enter a Reporting Date (it will be rounded up to month end).</div>";
                return View("LegalReportingPage", model);
            }

            DateTime ReportDateDTTM = DateTime.Parse(ReportDate);
            string NewFileName = "Tenant_Arrears_" + ReportDateDTTM.ToString("yyyy-MM") + ".xlsx";
            string fileNameAndPath = Server.MapPath("~/_Downloads/" + NewFileName);

            if (R.FillExcel_TenantArrearsReport(NewFileName, ReportDateDTTM, model.selectedBuildingCode))
            {
                model.Error_log = "";
                return File(fileNameAndPath, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", NewFileName);
            }
            else
            {
                ViewBag.Message = R.error_message;
                model.Error_log = "<div class=\"alert alert-danger\"><strong>Error!</strong> Error creating download file.</div>";
                return View("LegalReportingPage", model);
            }

        }


    }
}