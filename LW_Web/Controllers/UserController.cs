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
    public class UserController : Controller
    {

        private readonly LWDbContext _context;

        public UserController()
        {
            _context = new LWDbContext();
        }


        // GET: User
        public ActionResult Index()
        {
            var UserRecords = _context.tblUsers
                         .OrderBy(a => a.LastName)
                         .ToList();

            return View("UserList", UserRecords);
        }

        // GET: User/Details/5
        public ActionResult Details(int? id)
        {
            if (id == null)
            {
                return new HttpStatusCodeResult(HttpStatusCode.BadRequest);
            }
            clsUserRecord R = _context.tblUsers.Find(id);
            if (R == null)
            {
                return HttpNotFound();
            }
            return View("UserEdit", R);
        }

        // GET: User/Create
        public ActionResult Create()
        {
            clsUserRecord R = new clsUserRecord();
            R.UserID = -10;  // -10 means create user
            return View("UserEdit", R);
        }

        // GET: User/Edit/5
        public ActionResult Edit(int? id)
        {
            if (id == null) { return new HttpStatusCodeResult(HttpStatusCode.BadRequest); }

            clsUserRecord R = _context.tblUsers.Find(id);
            if (R == null) { return HttpNotFound(); }

            if (clsSecurity.isSuperAdmin() || clsSecurity.LoggedInUserID() == R.UserID)
            {
                R.password_enc = clsSecurity.DecryptString(R.password_enc);  // decrypt the password for viewing
                return View("UserEdit", R);
            }
            else
            {
                return View("Dashboard", new DashboardModel() { ErrorMsg = clsWebFormHelper.ErrorBoxMsgHTML("You do not have rights to edit user accounts.") });
            }

        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Edit(clsUserRecord updatedRecord)
        {
            if (ModelState.IsValid)
            {
                if (updatedRecord.UserID == -10)  // Create the record
                {
                    updatedRecord.password_enc = clsSecurity.EncryptString(updatedRecord.password_enc);
                    _context.tblUsers.Add(updatedRecord);
                    _context.SaveChanges();
                    return RedirectToAction("Index");
                }
                // edit the record
                {
                    var record = _context.tblUsers.Find(updatedRecord.UserID);
                    if (record != null)
                    {
                        record.LastName = updatedRecord.LastName;
                        record.FirstName = updatedRecord.FirstName;
                        record.EmailAddress = updatedRecord.EmailAddress;
                        record.password_enc = clsSecurity.EncryptString(updatedRecord.password_enc);
                        // Only Super Admins can update this -- also for forms that have disabled checkboxes we need to not update these the same
                        // Only a Super Admin can update all of these in any case - even if the same user is logged in
                        if (clsSecurity.isSuperAdmin())  // Update them, otherwise they stay the same
                        {
                            record.isProjectManager = updatedRecord.isProjectManager;
                            record.isLegalTeam = updatedRecord.isLegalTeam;
                            record.isAdmin = updatedRecord.isAdmin;
                            record.isSuperAdmin = updatedRecord.isSuperAdmin;
                            record.isDisabled = updatedRecord.isDisabled;
                        }
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
