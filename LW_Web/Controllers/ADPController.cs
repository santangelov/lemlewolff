using LW_Web.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using LW_Data;

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
            var records = _context.tblADP.ToList();
            return View("ADPEdit", records);
        }

        [HttpPost]
        public ActionResult Update(clsADPRecord updatedRecord)
        {
            var record = _context.tblADP.Find(updatedRecord.ADPRowID);
            if (record != null)
            {
                record.CompanyCode = updatedRecord.CompanyCode;
                record.LaborerID = updatedRecord.LaborerID;
                record.PayrollName = updatedRecord.PayrollName;
                record.FileNumber = updatedRecord.FileNumber;
                record.TimeIn = updatedRecord.TimeIn;
                record.TimeOut = updatedRecord.TimeOut;
                record.Location = updatedRecord.Location;
                record.WONumber = updatedRecord.WONumber;
                record.Department = updatedRecord.Department;
                record.PayDate = updatedRecord.PayDate;
                record.PayCode = updatedRecord.PayCode;
                record.Hours = updatedRecord.Hours;
                record.Dollars = updatedRecord.Dollars;
                record.TimeDescription = updatedRecord.TimeDescription;
                record.WODescription = updatedRecord.WODescription;
                record.isLockedForUpdates = updatedRecord.isLockedForUpdates;

                _context.SaveChanges();
                return Json(record);
            }
            return Json(new { success = false, message = "Record not found." });
        }
    }
}