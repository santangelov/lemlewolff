using System;
using System.Data;
using System.Linq;
using System.Net;
using System.Web.Mvc;
using LW_Data;
using LW_Security;

namespace LW_Web.Controllers
{
    public class LaborerController : Controller
    {

        private readonly LWDbContext _context;

        public LaborerController()
        {
            _context = new LWDbContext(); 
        }


        // GET: Laborer
        public ActionResult Index()
        {
            var LaborerRecords = _context.tblLaborers
                         .OrderBy(a => a.LastName)
                         .ToList();

            return View("LaborerList", LaborerRecords);
        }

        // GET: Laborer/Details/5
        public ActionResult Details(int? id)
        {
            if (id == null)
            {
                return new HttpStatusCodeResult(HttpStatusCode.BadRequest);
            }
            clsLaborerRecord R = _context.tblLaborers.Find(id);
            if (R == null)
            {
                return HttpNotFound();
            }
            return View("LaborerEdit", R);
        }

        // GET: Laborer/Create
        public ActionResult Create()
        {
            clsLaborerRecord R = new clsLaborerRecord();
            R.LaborerID = -10;  // -10 means create Laborer
            R.IsSupervisor = false;
            R.LWSmJobMinRateAdj = (decimal?)1.00;
            R.LWOTRate = (decimal?)1.00;
            R.LWMaterialRate = (decimal?)0.00;
            R.IncludeForInventory = true;
            R.BonusFactor = (decimal?)0.00;
            R.IsCoopSupplier = false;
            return View("LaborerEdit", R);
        }

        // GET: Laborer/Edit/5
        public ActionResult Edit(int? id)
        {
            if (id == null) { return new HttpStatusCodeResult(HttpStatusCode.BadRequest); }

            clsLaborerRecord R = _context.tblLaborers.Find(id);
            if (R == null)
            {
                return HttpNotFound();
            }
            return View("LaborerEdit", R);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Edit(clsLaborerRecord updatedRecord)
        {
            if (ModelState.IsValid)
            {
                if (updatedRecord.LaborerID == -10)  // Create the record
                {
                    _context.tblLaborers.Add(updatedRecord);
                    _context.SaveChanges();
                    return RedirectToAction("Index");
                }
                  // edit the record
                {
                    var record = _context.tblLaborers.Find(updatedRecord.LaborerID);
                    if (record != null)
                    {
                        record.LastName = updatedRecord.LastName;
                        record.FirstName = updatedRecord.FirstName;
                        record.BonusFactor = updatedRecord.BonusFactor;
                        record.IncludeForInventory = updatedRecord.IncludeForInventory;
                        record.IsCoopSupplier = updatedRecord.IsCoopSupplier;
                        record.IsSupervisor = updatedRecord.IsSupervisor;
                        record.LWMaterialRate = updatedRecord.LWMaterialRate;
                        record.LWOTRate = updatedRecord.LWOTRate;
                        record.LWSalariedHourlyRate = updatedRecord.LWSalariedHourlyRate;
                        record.LWSmJobMinRateAdj = updatedRecord.LWSmJobMinRateAdj;
                        record.WageIncrease2022 = updatedRecord.WageIncrease2022;

                        _context.SaveChanges();
                    }
                    else
                    {
                        return Json(new { success = false, message = "Record not found." });
                    }
                }
            }
            return RedirectToAction("Index");
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                _context.Dispose();
            }
            base.Dispose(disposing);
        }
    }
}
