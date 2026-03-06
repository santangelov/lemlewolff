using System;
using System.Configuration;
using System.Web.Mvc;
using LW_Data;
using LW_Common;
using LW_Web.ActionResults;

namespace LW_Web.Controllers
{
    [RoutePrefix("api")]
    public class WorkersApiController : Controller
    {
        private readonly string _accountId;
        private readonly string _password;
        private readonly clsWorkersData _workersData;

        public WorkersApiController()
        {
            _accountId = ConfigurationManager.AppSettings["VacancyApiAccountId"];
            _password = ConfigurationManager.AppSettings["VacancyApiPassword"];
            _workersData = new clsWorkersData();
        }

        [HttpGet]
        [Route("workers")]
        public ActionResult GetWorkers()
        {
            if (!IsAuthorized(Request.Headers["Authorization"]))
            {
                Response.AddHeader("WWW-Authenticate", "Basic realm=\"WorkOrderAPI\"");
                return new HttpStatusCodeResult(401, "Unauthorized");
            }

            var workers = _workersData.GetWorkers();
            return new MyJsonResult
            {
                Data = workers.ConvertAll(w => new
                {
                    w.WorkerID,
                    DisplayName = w.DisplayName,
                    CompanyCode = w.CompanyCode,
                    ADPFileNumber = w.ADPFileNumber
                })
            };
        }

        private bool IsAuthorized(string authorizationHeader)
        {
            return clsApiAuthHelper.IsBasicAuthorized(authorizationHeader, _accountId, _password);
        }
    }
}
