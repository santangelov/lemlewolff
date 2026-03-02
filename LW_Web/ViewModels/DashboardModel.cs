using LW_Common;
using System;
using System.ComponentModel;

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
            
            System.Data.DataRow arrearsDateResolution = EmailImporter.GetArrearsDateResolution(DateTime.Today);
            object resolvedDateValue = arrearsDateResolution == null ? null : arrearsDateResolution["ARAsOf_Resolved"];
            DateTime resolvedDate = clsFunc.CastToDateTime(resolvedDateValue, DateTime.MinValue);
            ArrearsDataLoadedThrough = resolvedDate == DateTime.MinValue ? "Not available" : resolvedDate.ToString("M/d/yy");
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
