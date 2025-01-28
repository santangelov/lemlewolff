using LW_Data;
using LW_Security;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web.Mvc;

namespace LW_Web.Controllers
{
    public class ADPController : Controller
    {
        private readonly LWDbContext _context;

        public ADPController()
        {
            _context = new LWDbContext(); // Replace with your DbContext
        }

        public ActionResult Index()
        {
            var adpRecords = _context.tblADP
                                     .Where(a => a.LaborerID != null)
                                     .OrderByDescending(a => a.PayDate)
                                     .Take(150)
                                     .ToList();

            // Fetch all laborers for the dropdown
            var laborers = _context.tblLaborers
                             .OrderBy(l => l.LastName)
                             .ThenBy(l => l.LastName)
                             .Select(l => new SelectListItem
                             {
                                 Value = l.LaborerID.ToString(),
                                 Text = l.LastName + ", " + l.FirstName
                             }).ToList();

            // Prefill the form fields if any were previously selected
            ViewBag.Laborers = laborers;

            return View("ADPEdit", adpRecords);
        }

        [HttpPost]
        public ActionResult Update(clsADPRecord updatedRecord)
        {
            var record = _context.tblADP.Find(updatedRecord.ADPRowID);
            if (record != null)
            {
                record.LaborerID = updatedRecord.LaborerID;
                record.TimeIn = updatedRecord.TimeIn;
                record.WONumber = updatedRecord.WONumber;
                record.Location = updatedRecord.Location;
                record.PayDate = updatedRecord.PayDate;
                record.Hours = updatedRecord.Hours;
                record.Dollars = updatedRecord.Dollars;
                record.isLockedForUpdates = true; // Lock any record that has been updated - create a separate function to unlock

                _context.SaveChanges();
                return Json(record);
            }
            return Json(new { success = false, message = "Record not found." });
        }

        [HttpPost]
        public ActionResult Unlock(clsADPRecord updatedRecord)
        {
            var record = _context.tblADP.Find(updatedRecord.ADPRowID);
            if (record != null)
            {
                record.isLockedForUpdates = false;
                _context.SaveChanges();
                return Json(record);
            }
            return Json(new { success = false, message = "Unlock error." });
        }

        [HttpPost]
        public ActionResult FilterRows(string action, int? FilterLaborerID, DateTime? FilterPayDate, string FilterWONumber)
        {
            if (action == "clear")
            {
                return RedirectToAction("Index");
            }

            // Fetch all laborers for the dropdown
            var laborers = _context.tblLaborers
                             .OrderBy(l => l.LastName)
                             .ThenBy(l => l.LastName)
                             .Select(l => new SelectListItem
                             {
                                 Value = l.LaborerID.ToString(),
                                 Text = l.LastName + ", " + l.FirstName
                             }).ToList();

            // Fetch filtered records if LaborerID is provided
            if (_context?.tblADP == null)
            {
                throw new InvalidOperationException("The database context or tblADP is not properly initialized.");
            }

            var records = _context.tblADP.AsQueryable();
            records = records.Where(r => r.PayDate != null);   // We should never have NULL PayDates, but filter in case

            if (FilterLaborerID.HasValue && FilterLaborerID.Value > 0)
            {
                records = records.Where(r => r.LaborerID == FilterLaborerID.Value);
                ViewBag.SelectedFilteredLaborer = FilterLaborerID.Value;
            }

            if (FilterPayDate.HasValue)
            {
                records = records.Where(r => r.PayDate == FilterPayDate.Value);
                ViewBag.FilterDate = FilterPayDate.Value;
            }

            if (!string.IsNullOrEmpty(FilterWONumber))
            {
                records = records.Where(r => r.WONumber.Contains(FilterWONumber));
                ViewBag.FilterWONumber = FilterWONumber;
            }

            // Materialize the query after filtering
            List<clsADPRecord> filteredRecords = records.Take(150).ToList();

            // Pass data to the view
            ViewBag.Laborers = laborers;

            return View("ADPEdit", filteredRecords);
        }

        public ActionResult AddRecord()
        {
            // Fetch all laborers for the dropdown
            var laborers = _context.tblLaborers
                .OrderBy(l => l.LastName)
                .ThenBy(l => l.FirstName)
                .Select(l => new SelectListItem
                {
                    Value = l.LaborerID.ToString(),
                    Text = l.LastName + ", " + l.FirstName
                })
                .ToList();

            ViewBag.Laborers = laborers;

            return View("ADPAdd"); // Explicitly specify the view name
            //return View(new clsADPRecord());
        }

        [HttpPost]
        public ActionResult AddRecord(clsADPRecord newRecord)
        {
            if (ModelState.IsValid)
            {
                var laborer = _context.tblLaborers.FirstOrDefault(l => l.LaborerID == newRecord.LaborerID);
                if (laborer != null)
                {
                    // Create the PayRollName by combining LastName and FirstName
                    newRecord.PayrollName = laborer.FullName;
                }

                // Add the new record to the database
                _context.tblADP.Add(new clsADPRecord
                {
                    PayDate = (DateTime)newRecord.PayDate,
                    PayrollName = newRecord.PayrollName,
                    LaborerID = newRecord.LaborerID,
                    WONumber = newRecord.WONumber,
                    Department = "ALLTYP",
                    TimeIn = (DateTime)newRecord.TimeIn,
                    TimeOut = (DateTime)newRecord.TimeOut,
                    Hours = newRecord.Hours,
                    Dollars = newRecord.Dollars,
                    isLockedForUpdates = true, // New rows start locked
                    TimeDescription = "Manually Added.",
                    Location = newRecord.Location,
                    PayCode = newRecord.PayCode,
                    FileNumber = newRecord.FileNumber,
                    CompanyCode = newRecord.CompanyCode,
                    CreatedBy = clsSecurity.LoggedInUserFullName(),
                    CreateDate = DateTime.Now
                });

                _context.SaveChanges();
                TempData["SuccessMessage"] = "New record added successfully!";
                return RedirectToAction("Index");
            }

            TempData["ErrorMessage"] = "Failed to add the new record. Please try again.";
            return View("ADPAdd");
        }


    }
}