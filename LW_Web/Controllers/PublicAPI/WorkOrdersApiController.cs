using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Linq;
using System.Web.Mvc;
using LW_Data;
using LW_Common;
using LW_Web.ActionResults;

namespace LW_Web.Controllers
{
    [RoutePrefix("api/work-orders")]
    public class WorkOrdersApiController : Controller
    {
        private readonly string _accountId;
        private readonly string _password;
        private readonly clsWorkOrdersData _workOrdersData;
        private readonly clsPurchaseOrdersData _purchaseOrdersData;

        public WorkOrdersApiController()
        {
            _accountId = ConfigurationManager.AppSettings["VacancyApiAccountId"];
            _password = ConfigurationManager.AppSettings["VacancyApiPassword"];
            _workOrdersData = new clsWorkOrdersData();
            _purchaseOrdersData = new clsPurchaseOrdersData();
        }

        [HttpPost]
        [Route("query")]
        public ActionResult Query(WorkOrderSearchRequest request)
        {
            if (!IsAuthorized(Request.Headers["Authorization"]))
            {
                Response.AddHeader("WWW-Authenticate", "Basic realm=\"WorkOrderAPI\"");
                return new HttpStatusCodeResult(401, "Unauthorized");
            }

            request = request ?? new WorkOrderSearchRequest();

            bool hasFilters =
                (request.Categories != null && request.Categories.Any(x => !string.IsNullOrWhiteSpace(x))) ||
                request.CompletionDateIsBlank.HasValue ||
                request.WONumber.HasValue ||
                (request.BuildingNums != null && request.BuildingNums.Any(x => !string.IsNullOrWhiteSpace(x))) ||
                !string.IsNullOrWhiteSpace(request.JobStatus) ||
                request.IsAssigned.HasValue ||
                request.AssignedToID.HasValue;

            if (!hasFilters)
            {
                return JsonError(400,
                    "At least one filter is required (Categories, CompletionDateIsBlank, WONumber, BuildingNums, JobStatus, IsAssigned, or AssignedToID). Returning all work orders is not allowed.");
            }

            try
            {
                var workOrders = _workOrdersData.GetWorkOrdersForApi(
                    ToFilter(request),
                    request.IncludeWOItems.GetValueOrDefault(false),
                    request.IncludePOs.GetValueOrDefault(false));

                if (request.IncludePOs.GetValueOrDefault(false) && workOrders.Count > 0)
                {
                    var poCacheByWONumber = new Dictionary<string, List<Dictionary<string, object>>>(StringComparer.OrdinalIgnoreCase);

                    foreach (var workOrder in workOrders)
                    {
                        string woNumber = workOrder.ContainsKey("WONumber") && workOrder["WONumber"] != null
                            ? Convert.ToString(workOrder["WONumber"])
                            : null;

                        if (string.IsNullOrWhiteSpace(woNumber))
                        {
                            workOrder["PurchaseOrders"] = new List<Dictionary<string, object>>();
                            continue;
                        }

                        if (!poCacheByWONumber.ContainsKey(woNumber))
                        {
                            poCacheByWONumber[woNumber] = _purchaseOrdersData.GetByWONumber(woNumber);
                        }

                        workOrder["PurchaseOrders"] = poCacheByWONumber[woNumber];
                    }
                }

                return new MyJsonResult { Data = workOrders };
            }
            catch (SqlException ex) when (ex.Number == 229 && request.IncludeWOItems.GetValueOrDefault(false))
            {
                return JsonError(403,
                    "The configured database user does not have permission to read work order items (dbo.tblWorkOrderItems).",
                    "Grant SELECT on dbo.tblWorkOrderItems, or set IncludeWOItems=false.");
            }
            catch (Exception ex)
            {
                return JsonError(500, "Unexpected error while processing request.", ex.Message);
            }
        }

        [HttpPost]
        [Route("assign")]
        public ActionResult Assign(WorkOrderAssignRequest request)
        {
            if (!IsAuthorized(Request.Headers["Authorization"]))
            {
                Response.AddHeader("WWW-Authenticate", "Basic realm=\"WorkOrderAPI\"");
                return new HttpStatusCodeResult(401, "Unauthorized");
            }

            if (request == null || string.IsNullOrWhiteSpace(request.WONumber))
            {
                return JsonError(400, "woNumber is required.");
            }

            try
            {
                int rowsAffected = _workOrdersData.AssignByWONumber(request.WONumber.Trim(), request.AssignedToID);
                return new MyJsonResult
                {
                    Data = new
                    {
                        woNumber = request.WONumber,
                        assignedToID = request.AssignedToID,
                        rowsAffected
                    }
                };
            }
            catch (Exception ex)
            {
                return JsonError(500, "Unexpected error while assigning work order.", ex.Message);
            }
        }



        private static WorkOrderQueryFilter ToFilter(WorkOrderSearchRequest request)
        {
            return new WorkOrderQueryFilter
            {
                Categories = request.Categories,
                CompletionDateIsBlank = request.CompletionDateIsBlank,
                WONumber = request.WONumber,
                BuildingNums = request.BuildingNums,
                JobStatus = request.JobStatus,
                ItemCodes = request.ItemCodes,
                FilterItemCategories = request.FilterItemCategories,
                IsAssigned = request.IsAssigned,
                AssignedToID = request.AssignedToID
            };
        }

        private ActionResult JsonError(int statusCode, string message, string detail = null)
        {
            Response.StatusCode = statusCode;
            Response.TrySkipIisCustomErrors = true;

            if (string.IsNullOrWhiteSpace(detail))
            {
                return Json(new { message }, JsonRequestBehavior.AllowGet);
            }

            return Json(new { message, detail }, JsonRequestBehavior.AllowGet);
        }

        private bool IsAuthorized(string authorizationHeader)
        {
            return clsApiAuthHelper.IsBasicAuthorized(authorizationHeader, _accountId, _password);
        }
    }

    public class WorkOrderSearchRequest
    {
        public List<string> Categories { get; set; }
        public bool? CompletionDateIsBlank { get; set; }
        public int? WONumber { get; set; }
        public List<string> BuildingNums { get; set; }
        public string JobStatus { get; set; }
        public List<string> ItemCodes { get; set; }
        public List<string> FilterItemCategories { get; set; }
        public bool? IncludeWOItems { get; set; }
        public bool? IsAssigned { get; set; }
        public int? AssignedToID { get; set; }
        public bool? IncludePOs { get; set; }
    }

    public class WorkOrderAssignRequest
    {
        public string WONumber { get; set; }
        public int? AssignedToID { get; set; }
    }
}
