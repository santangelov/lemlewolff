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

        [HttpGet]
        public ActionResult VacancyCoverSheet(string accountId, string password, string selectedBuildingCode, string selectedAptNumber)
        {
            if (!IsAuthorized(accountId, password))
            {
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

        private bool IsAuthorized(string accountId, string password)
        {
            return !string.IsNullOrEmpty(accountId)
                && !string.IsNullOrEmpty(password)
                && string.Equals(accountId, _accountId)
                && string.Equals(password, _password);
        }
    }
}
