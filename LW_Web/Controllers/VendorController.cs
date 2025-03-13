using LW_Common;
using LW_Data;
using LW_Security;
using LW_Web.Models;
using System.Data;
using System.Linq;
using System.Net;
using System.Web.Mvc;

namespace LW_Web.Controllers
{
    public class VendorController : Controller
    {

        private readonly LWDbContext _context;

        public VendorController()
        {
            _context = new LWDbContext();
        }


        // GET: Vendor
        public ActionResult Index()
        {
            if (!clsSecurity.isUserLoggedIn())
            {
                return View("Login", new LoginModel() { Error_log = "ERROR: Not logged in." });
            }

            if (clsSecurity.isUserAdmin() == false && clsSecurity.isSuperAdmin() == false)
            {
                return View("Dashboard", new DashboardModel() { ErrorMsg = clsWebFormHelper.ErrorBoxMsgHTML("ERROR: You do not have access view or edit Vendor data.") });
            }


            var VendorRecords = _context.tblVendors
                         .OrderBy(a => a.VendorName)
                         .ToList();

            return View("VendorList", VendorRecords);
        }

        // GET: Vendor/Details/5
        public ActionResult Details(int? id)
        {
            if (id == null)
            {
                return new HttpStatusCodeResult(HttpStatusCode.BadRequest);
            }
            clsVendorRecord R = _context.tblVendors.Find(id);
            if (R == null)
            {
                return HttpNotFound();
            }
            return View("VendorEdit", R);
        }

        // GET: Vendor/Create
        public ActionResult Create()
        {
            clsVendorRecord R = new clsVendorRecord();
            R.VendorID = -10;  // -10 means create Vendor
            R.isSubcontractor = true;
            return View("VendorEdit", R);
        }

        // GET: Vendor/Edit/5
        public ActionResult Edit(int? id)
        {
            if (id == null) { return new HttpStatusCodeResult(HttpStatusCode.BadRequest); }

            clsVendorRecord R = _context.tblVendors.Find(id);
            if (R == null)
            {
                return HttpNotFound();
            }
            return View("VendorEdit", R);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Edit(clsVendorRecord updatedRecord)
        {
            if (ModelState.IsValid)
            {
                if (updatedRecord.VendorID == -10)  // Create the record
                {
                    _context.tblVendors.Add(updatedRecord);
                    _context.SaveChanges();
                    return RedirectToAction("Index");
                }
                // edit the record
                {
                    var record = _context.tblVendors.Find(updatedRecord.VendorID);
                    if (record != null)
                    {
                        record.VendorName = updatedRecord.VendorName;
                        record.VendorCode = updatedRecord.VendorCode;
                        record.isSubcontractor = updatedRecord.isSubcontractor;
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
