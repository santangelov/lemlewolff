using LW_Web.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using LW_Data;
using LW_Security;
using System.Data;

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
            // { a.ADPRowID, a.PayDate, a.LaborerID, a.TimeIn, a.TimeOut, a.Hours, a.isLockedForUpdates }) // Include only necessary fields
            var adpRecords = _context.tblADP
                                     .Where(a => a.LaborerID != null)
                                     .OrderByDescending(a => a.PayDate)
                                     .Take(75)
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
                record.TimeOut = updatedRecord.TimeOut;
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
        public ActionResult FilterRows(int? FilterLaborerID, DateTime? FilterPayDate)
        {
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
            var records = _context.tblADP.AsQueryable();

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

            // Ensure you materialize the query after filtering
            var filteredRecords = records.ToList();

            // Pass the data to the view
            ViewBag.Laborers = laborers;

            return View("ADPEdit", records.ToList());
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