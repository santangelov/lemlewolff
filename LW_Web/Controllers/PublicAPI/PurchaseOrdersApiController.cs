using System;
using System.Configuration;
using System.Web.Mvc;
using LW_Common;
using LW_Data;
using LW_Web.ActionResults;

namespace LW_Web.Controllers
{
    [RoutePrefix("api/purchase-orders")]
    public class PurchaseOrdersApiController : Controller
    {
        private readonly string _accountId;
        private readonly string _password;
        private readonly clsPurchaseOrdersData _purchaseOrdersData;

        public PurchaseOrdersApiController()
        {
            _accountId = ConfigurationManager.AppSettings["VacancyApiAccountId"];
            _password = ConfigurationManager.AppSettings["VacancyApiPassword"];
            _purchaseOrdersData = new clsPurchaseOrdersData();
        }

        [HttpGet]
        [Route("")]
        public ActionResult GetPurchaseOrders(string woNumber = null)
        {
            if (!IsAuthorized(Request.Headers["Authorization"]))
            {
                Response.AddHeader("WWW-Authenticate", "Basic realm=\"WorkOrderAPI\"");
                return new HttpStatusCodeResult(401, "Unauthorized");
            }

            try
            {
                var result = _purchaseOrdersData.GetPurchaseOrders(woNumber);
                return new MyJsonResult { Data = result };
            }
            catch (Exception ex)
            {
                Response.StatusCode = 500;
                return Json(new { message = "Unexpected error while retrieving purchase orders.", detail = ex.Message }, JsonRequestBehavior.AllowGet);
            }
        }

        [HttpGet]
        [Route("{poNumber}")]
        public ActionResult GetPurchaseOrderByNumber(string poNumber)
        {
            if (!IsAuthorized(Request.Headers["Authorization"]))
            {
                Response.AddHeader("WWW-Authenticate", "Basic realm=\"WorkOrderAPI\"");
                return new HttpStatusCodeResult(401, "Unauthorized");
            }

            if (string.IsNullOrWhiteSpace(poNumber) || poNumber.Contains(","))
            {
                Response.StatusCode = 400;
                return Json(new { message = "A single poNumber is required." }, JsonRequestBehavior.AllowGet);
            }

            try
            {
                var result = _purchaseOrdersData.GetByPONumber(poNumber.Trim());
                if (result == null)
                {
                    return HttpNotFound("Purchase order not found.");
                }

                return new MyJsonResult { Data = result };
            }
            catch (Exception ex)
            {
                Response.StatusCode = 500;
                return Json(new { message = "Unexpected error while retrieving purchase order.", detail = ex.Message }, JsonRequestBehavior.AllowGet);
            }
        }

        private bool IsAuthorized(string authorizationHeader)
        {
            return clsApiAuthHelper.IsBasicAuthorized(authorizationHeader, _accountId, _password);
        }
    }
}
