using LW_Common;
using LW_Data;
using LW_Web.Models;
using System.Linq;
using System.Web.Mvc;

namespace LW_Web.Controllers
{
    public class ReportPageController : BaseController
    {
        private readonly LWDbContext _context;

        public ReportPageController()
        {
            _context = new LWDbContext();
        }


        // GET: Home
        public ActionResult Index()
        {
            ReportPageModel mdl = new ReportPageModel();

            // Fill in Properties
            ViewBag.PropertyList = new SelectList(
                _context.tblProperties
                    .Where(p => p.isInactive == false) // Filter inactive properties
                    .OrderBy(p => p.buildingCode)
                    .Select(p => new {
                        Value = p.buildingCode,
                        Text = string.Concat(p.buildingCode, " - ", (p.addr1_Co ?? "n/a").ToUpper()) // Concatenate in the DB query
                    }),
                "Value", "Text"
            );


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