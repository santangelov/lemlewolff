using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace LW_Data
{
    public class clsADPRecord    // : IEnumerable<KeyValuePair<string, object>>
    {
        [Key]
        public int ADPRowID { get; set; }

        public string CompanyCode { get; set; }

        // Include LaborerID and a foreign key connection to the Laborer record
        public int? LaborerID { get; set; }
        [ForeignKey("LaborerID")]
        public virtual clsLaborerRecord Laborer { get; set; }

        public string PayrollName { get; set; }
        public string FileNumber { get; set; }
        public DateTime? TimeIn { get; set; }
        public DateTime? TimeOut { get; set; }
        public string Location { get; set; }
        public string WONumber { get; set; }
        public string Department { get; set; }
        [Required]
        public DateTime PayDate { get; set; }
        public string PayCode { get; set; }
        public decimal? Hours { get; set; }
        public decimal? Dollars { get; set; }
        public string TimeDescription { get; set; }
        public string WODescription { get; set; }
        public decimal? Dollars_Calculated { get; }
        public string CreatedBy { get; set; }
        public DateTime CreateDate { get; set; }
        public bool isLockedForUpdates { get; set; }
    }
}
