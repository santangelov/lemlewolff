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
            var mdl = new LegalReportingPageModel();
            PopulateProperties(mdl);

            mdl.selectedBuildingCode = "List-Posting";
            return View("LegalReportingPage", mdl);
        }

        private void PopulateProperties(LegalReportingPageModel mdl)
        {
            mdl.Properties = _context.tblProperties
                .Where(p => !p.isInactive && _context.tblPropertyUnits.Any(u => u.yardiPropertyRowID == p.yardiPropertyRowID && !u.isExcluded))
                .OrderBy(p => p.buildingCode)
                .Select(p => new SelectListItem
                {
                    Value = p.buildingCode,
                    Text = string.Concat(p.buildingCode, " - ", (p.addr1_Co ?? "n/a").ToUpper())
                })
                .ToList();

            mdl.Properties.Insert(0, new SelectListItem { Value = "", Text = "== PROPERTIES ==========" });
            mdl.Properties.Insert(0, new SelectListItem { Value = "List-Posting", Text = "Posting" });
            mdl.Properties.Insert(0, new SelectListItem { Value = "List-Aquinas", Text = "Aquinas" });
            mdl.Properties.Insert(0, new SelectListItem { Value = "", Text = "== LISTS ===============" });
        }

        [HttpPost]
        public ActionResult GetTenantArrearsReport(LegalReportingPageModel model)
        {
            Server.ScriptTimeout = 1200;

            // IMPORTANT: repopulate for any return View(...)
            PopulateProperties(model);

            var R = new clsReportHelper();

            if (string.IsNullOrEmpty(model.ArrearsReportDate))
            {
                model.Error_log = "<div class=\"alert alert-danger\"><strong>*</strong> Enter a Reporting Date (it will be rounded up to month end).</div>";
                return View("LegalReportingPage", model);
            }

            if (!DateTime.TryParse(model.ArrearsReportDate, out var ReportDateDTTM))
            {
                model.Error_log = "<div class=\"alert alert-danger\"><strong>*</strong> Enter a valid Reporting Date (mm/dd/yyyy).</div>";
                return View("LegalReportingPage", model);
            }

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