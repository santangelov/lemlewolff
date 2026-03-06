using System;
using System.Configuration;
using System.Web.Mvc;
using LW_Common;

namespace LW_Web.Controllers
{
    public class VacancyApiController : Controller
    {
        private readonly string _accountId;
        private readonly string _password;

        public VacancyApiController()
        {
            _accountId = ConfigurationManager.AppSettings["VacancyApiAccountId"];
            _password = ConfigurationManager.AppSettings["VacancyApiPassword"];
        }

        [AcceptVerbs(HttpVerbs.Get | HttpVerbs.Post)]
        public ActionResult VacancyCoverSheet(string selectedBuildingCode, string selectedAptNumber)
        {
            if (!IsAuthorized(Request.Headers["Authorization"]))
            {
                Response.AddHeader("WWW-Authenticate", "Basic realm=\"VacancyAPI\"");
                return new HttpStatusCodeResult(401, "Unauthorized");
            }

            if (string.IsNullOrEmpty(selectedBuildingCode) || string.IsNullOrEmpty(selectedAptNumber))
            {
                return new HttpStatusCodeResult(400, "Property code and apartment number are required.");
            }

            clsReportHelper reportHelper = new clsReportHelper();
            string buildingCode = selectedBuildingCode;
            string aptNumber = selectedAptNumber;

            string newFileName = $"VacancyCoverSheet_{buildingCode}_{aptNumber}_{DateTime.Now:yyyyMMdd}.xlsx";
            string fileNameAndPath = Server.MapPath("~/_Downloads/" + newFileName);

            if (reportHelper.FillExcel_VacancyCoverSheet(newFileName, buildingCode, aptNumber))
            {
                return File(fileNameAndPath, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", newFileName);
            }

            return new HttpStatusCodeResult(500, "Error creating download file.");
        }

        private bool IsAuthorized(string authorizationHeader)
        {
            return clsApiAuthHelper.IsBasicAuthorized(authorizationHeader, _accountId, _password);
        }
    }
}
