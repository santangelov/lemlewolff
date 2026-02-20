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

    }
}
