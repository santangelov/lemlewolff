using LW_Common;
using LW_Data;
using LW_Security;
using LW_Web.Models;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Diagnostics.Eventing.Reader;
using System.Linq;
using System.Web.Mvc;

namespace LW_Web.Controllers
{
    public class PIController : Controller
    {
        //private readonly LWDbContext _context;
        private clsPhysicalInvHelper _PIHelper = new clsPhysicalInvHelper();

        public ActionResult Index()
        {
            if (!clsSecurity.isUserLoggedIn())
            {
                return View("Login", new LoginModel() { Error_log = "ERROR: Not logged in." });
            }

            if (clsSecurity.isUserAdmin() == false && clsSecurity.isSuperAdmin() == false)
            {
                return View("Dashboard", new DashboardModel() { ErrorMsg = clsWebFormHelper.ErrorBoxMsgHTML("ERROR: You do not have access view or edit Inventory data.") });
            }


            return View("PhysicalInvEdit", _PIHelper.GetAllPIRecords(150));
        }

        [HttpPost]
        public ActionResult Update(clsPhysicalInventoryRecord updatedRecord)
        {
            // Do not process this record if there is no Date or Item Code
            if (updatedRecord.Code == "" || !updatedRecord.AsOfDate.HasValue)
            {
                return Json(new { success = false, message = "Missing Date and/or Item Code" });
            }

            clsPhysicalInventoryRecord record = _PIHelper.GetPIRecord(updatedRecord.PIRowID);
            if (record != null)
            {
                record.AsOfDate = updatedRecord.AsOfDate;
                record.Code = updatedRecord.Code;
                record.PhysicalCount = updatedRecord.PhysicalCount;
                record.Description = updatedRecord.Description;
                
                _PIHelper.SaveToDB(record, clsSecurity.LoggedInUserFirstName());
                return Json(record);
            }
            return Json(new { success = false, message = "Record not found." });
        }

        [HttpPost]
        public ActionResult Delete(clsPhysicalInventoryRecord updatedRecord)
        {
           bool retVal = _PIHelper.DeleteFromDB(updatedRecord.PIRowID);
           return Json(new { success = retVal });           
        }

        [HttpPost]
        public ActionResult FilterRows(string action, DateTime? FilterAsOfDate, string FilterItemCode)
        {
            if (action == "clear") return RedirectToAction("Index"); 

            // save the default values for the form
            if (FilterAsOfDate.HasValue) ViewBag.FilterAsOfDate = FilterAsOfDate.Value;
            if (!string.IsNullOrEmpty(FilterItemCode)) ViewBag.FilterItemCode = FilterItemCode;

            // Return the View filtered
            return View("PhysicalInvEdit", _PIHelper.GetFilteredRecords(150, FilterAsOfDate, FilterItemCode));
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

                if (_PIHelper.SaveToDB(I, clsSecurity.LoggedInUserFirstName()))
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