using System;
using System.Linq;
using System.Web.Mvc;
using LW_Data;

namespace LW_Web.Controllers
{
    public class ApiController : Controller
    {
        private readonly LWDbContext _dbContext;

        // Constructor to initialize the DbContext
        public ApiController()
        {
            _dbContext = new LWDbContext();
        }

        // GET: /API/Properties
        [HttpGet]
        public JsonResult Properties()
        {
            var properties = _dbContext.tblProperties
                .Select(p => new
                {
                    p.yardiPropertyRowID,
                    p.addr1_Co,
                    p.fullAddress_calc,
                    p.isInactive,
                    p.buildingCode
                })
                .Take(100)
                .ToList();

            return Json(properties, JsonRequestBehavior.AllowGet);
        }

        // GET: /API/MaintenanceRequests
        [HttpGet]
        public JsonResult MaintenanceRequests()
        {
            var maintenanceRequests = new[]
            {
                new
                {
                    Id = 1,
                    Name = "John Doe",
                    Email = "johndoe@example.com",
                    Phone = "123-456-7890",
                    Address = "123 Main St, Springfield",
                    IssueType = "Plumbing",
                    Description = "Leaking faucet in the kitchen.",
                    PreferredDate = DateTime.Now.AddDays(2),
                    Urgency = "High",
                    Permission = true,
                    Status = "pending",
                    CreatedAt = DateTime.Now.AddDays(-1)
                },
                new
                {
                    Id = 2,
                    Name = "Jane Smith",
                    Email = "janesmith@example.com",
                    Phone = "987-654-3210",
                    Address = "456 Elm St, Springfield",
                    IssueType = "Electrical",
                    Description = "Power outage in the living room.",
                    PreferredDate = DateTime.Now.AddDays(3),
                    Urgency = "Medium",
                    Permission = false,
                    Status = "in-progress",
                    CreatedAt = DateTime.Now.AddDays(-2)
                }
            }.ToList();


            return Json(maintenanceRequests, JsonRequestBehavior.AllowGet);
        }
    }
}
