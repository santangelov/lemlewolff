using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace LW_Data
{
    public class clsVendorRecord
    {
        [Key]
        public int VendorID { get; set; } = -1;
        [StringLength(20)]
        [Required]
        public string VendorCode { get; set; }
        [StringLength(50)]
        [Required]
        public string VendorName { get; set; }
        [Required]
        public bool isSubcontractor { get; set; } = true;
    }
}
