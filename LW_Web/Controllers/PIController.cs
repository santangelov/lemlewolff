using LW_Data;
using LW_Security;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web.Mvc;

namespace LW_Web.Controllers
{
    public class PIController : Controller
    {
        private readonly LWDbContext _context;

        public PIController()
        {
            _context = new LWDbContext();
        }

        public ActionResult Index()
        {
            var PIRecords = _context.tblPhysicalInventory
                                .Where(a => a.AsOfDate.HasValue && a.Code != "")
                                .OrderBy(a => a.Code)
                                //.Skip((pageNumber - 1) * 75) // Skip records for previous pages
                                .Take(150) // Take only the records for the current page
                                .ToList();

            return View("PhysicalInvEdit", PIRecords);
        }

        [HttpPost]
        public ActionResult Update(clsPhysicalInventoryRecord updatedRecord)
        {
            // Do not process this record if there is no Date or Item Code
            if (updatedRecord.Code == "" || !updatedRecord.AsOfDate.HasValue)
            {
                return Json(new { success = false, message = "Missing Date and/or Item Code" });
            }

            var record = _context.tblPhysicalInventory.Find(updatedRecord.PIRowID);
            if (record != null)
            {
                record.PIRowID = updatedRecord.PIRowID;
                record.AsOfDate = updatedRecord.AsOfDate;
                record.Code = updatedRecord.Code;
                record.PhysicalCount = updatedRecord.PhysicalCount;
                record.Description = updatedRecord.Description;
                record.modBy = clsSecurity.LoggedInUserFirstName();
                record.modDate = DateTime.Now;

                _context.SaveChanges();
                return Json(record);
            }
            return Json(new { success = false, message = "Record not found." });
        }

        [HttpPost]
        public ActionResult Delete(clsPhysicalInventoryRecord updatedRecord)
        {
            var record = _context.tblPhysicalInventory.Find(updatedRecord.PIRowID);
            if (record != null)
            {
                _context.tblPhysicalInventory.Remove(record);
                _context.SaveChanges();
                return Json(record);
            }
            return Json(new { success = false, message = "Delete Error." });
        }

        [HttpPost]
        public ActionResult FilterRows(string action, DateTime? FilterAsOfDate, string FilterItemCode)
        {
            if (action == "clear")
            {
                return RedirectToAction("Index");
            }

            // Fetch filtered records 
            if (_context?.tblPhysicalInventory == null)
            {
                throw new InvalidOperationException("The database context or tblPhysicalInventory is not properly initialized.");
            }

            var records = _context.tblPhysicalInventory.AsQueryable();
            records = records.Where(r => r.AsOfDate != null);   // We should never have NULL PayDates, but filter in case

            if (FilterAsOfDate.HasValue)
            {
                records = records.Where(r => r.AsOfDate == FilterAsOfDate.Value);
                ViewBag.FilterAsOfDate = FilterAsOfDate.Value;
            }

            if (!string.IsNullOrEmpty(FilterItemCode))
            {
                records = records.Where(r => r.Code.Contains(FilterItemCode));
                ViewBag.FilterItemCode = FilterItemCode;
            }

            // Materialize the query after filtering
            List<clsPhysicalInventoryRecord> filteredRecords = records.Take(150).ToList();

            return View("PhysicalInvEdit", filteredRecords);
        }

        public ActionResult AddRecord()
        {
            return View("PhysicalInvAdd");
        }

        [HttpPost]
        public ActionResult AddRecord(clsPhysicalInventoryRecord newRecord)
        {
            if (ModelState.IsValid)
            {
                clsPhysicalInventoryRecord I = new clsPhysicalInventoryRecord();

                I.AsOfDate = (DateTime)newRecord.AsOfDate;
                I.Code = (string)newRecord.Code;
                I.Description = (string)newRecord.Description;
                I.PhysicalCount = (int)newRecord.PhysicalCount;
                I.CreatedBy = clsSecurity.LoggedInUserFirstName();
                I.CreateDate = DateTime.Now;
                if (I.SaveToDB())
                {
                    TempData["SuccessMessage"] = "New record added successfully!";
                }
                else
                {
                    TempData["ErrorMessage"] = "Failed to add the new record.";
                }

                return RedirectToAction("Index");
            }

            TempData["ErrorMessage"] = "Failed to add the new record. Please try again.";
            return View("PhysicalInvAdd");
        }


    }
}