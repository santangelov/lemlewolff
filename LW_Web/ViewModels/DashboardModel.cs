using LW_Common;
using System;
using System.ComponentModel;
using System.IO;
using System.Linq;
using System.Web;

namespace LW_Web.ViewModels
{
    public class DashboardModel
    {
        public DashboardModel()
        {
            SortlyDateRangeLoaded = clsReportHelper.GetFileDateRangeValues("Sortly").DateRangeAsString;
            YardiWODateRangeLoaded = clsReportHelper.GetFileDateRangeValues("YardiWO_File").DateRangeAsString;
            YardiPODateRangeLoaded = clsReportHelper.GetFileDateRangeValues("YardiPO_File").DateRangeAsString;
            YardiWO2DateRangeLoaded = clsReportHelper.GetFileDateRangeValues("YardiWO_Inventory").DateRangeAsString;
            YardiPO2DateRangeLoaded = clsReportHelper.GetFileDateRangeValues("YardiPO_Inventory").DateRangeAsString;
            YardiWOGeneralDateRangeLoaded = clsReportHelper.GetFileDateRangeValues("YardiWO_GeneralFile").DateRangeAsString;
            YardiPropertyAndUnitDateRangeLoaded = clsReportHelper.GetFileDateRangeValues("YardiPropertyFile").DateRangeAsString;
            ADPDateRangeLoaded = clsReportHelper.GetFileDateRangeValues("ADP").DateRangeAsString;

            DashboardAsOfTimestamp = DateTime.Now.ToString("M/d/yy h:mm tt");
            SetArrearsReportingTimestamps();
        }

        private void SetArrearsReportingTimestamps()
        {
            string downloadsPath = HttpContext.Current.Server.MapPath("~/_Downloads");
            if (!Directory.Exists(downloadsPath))
            {
                ArrearsLatestReportDate = "No report found";
                ArrearsLatestGeneratedAt = "No report found";
                ArrearsLatestFileName = "No report found";
                return;
            }

            FileInfo latestArrearsFile = new DirectoryInfo(downloadsPath)
                .GetFiles("Tenant_Arrears_*.xlsx")
                .OrderByDescending(f => f.LastWriteTime)
                .FirstOrDefault();

            if (latestArrearsFile == null)
            {
                ArrearsLatestReportDate = "No report found";
                ArrearsLatestGeneratedAt = "No report found";
                ArrearsLatestFileName = "No report found";
                return;
            }

            ArrearsLatestGeneratedAt = latestArrearsFile.LastWriteTime.ToString("M/d/yy h:mm tt");
            ArrearsLatestFileName = latestArrearsFile.Name;

            string reportDateText = Path.GetFileNameWithoutExtension(latestArrearsFile.Name).Replace("Tenant_Arrears_", "");
            ArrearsLatestReportDate = DateTime.TryParse(reportDateText, out DateTime parsedDate)
                ? parsedDate.ToString("M/d/yy")
                : reportDateText;
        }

        public string SortlyDateRangeLoaded { get; set; }
        public string YardiWODateRangeLoaded { get; set; }
        public string YardiPODateRangeLoaded { get; set; }
        public string YardiWO2DateRangeLoaded { get; set; }
        public string YardiPO2DateRangeLoaded { get; set; }
        public string YardiWOGeneralDateRangeLoaded { get; set; }
        public string YardiPropertyAndUnitDateRangeLoaded { get; set; }
        public string ADPDateRangeLoaded { get; set; }

        public string DashboardAsOfTimestamp { get; set; }
        public string ArrearsDataLoadedThrough { get; set; }

        public string ErrorMsg { get; set; }
    }
}
