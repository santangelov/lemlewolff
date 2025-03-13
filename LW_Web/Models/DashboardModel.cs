using LW_Common;
using System.Collections.Generic;
using System.ComponentModel;
using System.Web;
using System.Web.Mvc;

namespace LW_Web.Models
{
    public class DashboardModel
    {
        public DashboardModel()
        {
            // Look up the Import Dates
            clsReportHelper RH = new clsReportHelper();
            SortlyDateRangeLoaded = clsReportHelper.GetFileDateRangeValues("Sortly").DateRangeAsString;
            YardiWODateRangeLoaded = clsReportHelper.GetFileDateRangeValues("YardiWO_File").DateRangeAsString;
            YardiPODateRangeLoaded = clsReportHelper.GetFileDateRangeValues("YardiPO_File").DateRangeAsString;
            YardiWO2DateRangeLoaded = clsReportHelper.GetFileDateRangeValues("YardiWO_Inventory").DateRangeAsString;
            YardiPO2DateRangeLoaded = clsReportHelper.GetFileDateRangeValues("YardiPO_Inventory").DateRangeAsString;
            YardiWOGeneralDateRangeLoaded = clsReportHelper.GetFileDateRangeValues("YardiWO_GeneralFile").DateRangeAsString;
            YardiPropertyAndUnitDateRangeLoaded = clsReportHelper.GetFileDateRangeValues("YardiPropertyFile").DateRangeAsString;
            ADPDateRangeLoaded = clsReportHelper.GetFileDateRangeValues("ADP").DateRangeAsString;
        }

        [DisplayName("Sortly Date Range Loaded")]
        public string SortlyDateRangeLoaded { get; set; }

        [DisplayName("Yardi WO Date Range Loaded")]
        public string YardiWODateRangeLoaded { get; set; }

        [DisplayName("Yardi WO Date Range Loaded")]
        public string YardiPODateRangeLoaded { get; set; }

        [DisplayName("Yardi WO Date Range Loaded")]
        public string YardiWO2DateRangeLoaded { get; set; }

        [DisplayName("Yardi WO Date Range Loaded")]
        public string YardiPO2DateRangeLoaded { get; set; }

        [DisplayName("Yardi WO General Date Range Loaded")]
        public string YardiWOGeneralDateRangeLoaded { get; set; }

        [DisplayName("Yardi Property and Unit File Loaded")]
        public string YardiPropertyAndUnitDateRangeLoaded { get; set; }

        [DisplayName("ADP Date Range Loaded")]
        public string ADPDateRangeLoaded { get; set; }

        public string ErrorMsg { get; set; }    

    }
}