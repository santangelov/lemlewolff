using System;
using System.ComponentModel.DataAnnotations;
using System.Security.Policy;
using System.ComponentModel.DataAnnotations.Schema;

namespace LW_Data
{
    public class clsPropertyUnitRecord
    {
        [Key]
        public int yardiUnitRowID { get; set; }
        public int yardiPropertyRowID { get; set; }

        public string AptNumber { get; set; }
        public int Bedrooms { get; set; }
        public decimal? rent { get; set; }
        public decimal? SqFt { get; set; }
        public string UnitStatus { get; set; }
        public DateTime? LastMoveInDate { get; set; }
        public DateTime? LastMoveOutDate { get; set; }
        public bool isExcluded { get; set; } = false;
        
        public string StatusBasedOnDates { get; set; }
    }
}
