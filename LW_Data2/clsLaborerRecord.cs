using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LW_Data
{
    public class clsLaborerRecord
    {
        [Key]
        public int LaborerID { get; set; }

        [Required]
        [StringLength(250)]
        public string LastName { get; set; }

        [StringLength(250)]
        public string FirstName { get; set; }

        [Column(TypeName = "decimal(10, 2)")]
        public decimal? LWSalariedHourlyRate { get; set; }

        [Column(TypeName = "decimal(10, 2)")]
        public decimal? LWSmJobMinRateAdj { get; set; }

        [Column(TypeName = "decimal(10, 2)")]
        public decimal? LWOTRate { get; set; }

        [Column(TypeName = "decimal(10, 2)")]
        public decimal? LWMaterialRate { get; set; }

        [Column(TypeName = "decimal(10, 2)")]
        public decimal? WageIncrease2022 { get; set; }

        [Required]
        public bool IncludeForInventory { get; set; } = true;

        [Column(TypeName = "decimal(10, 2)")]
        public decimal? BonusFactor { get; set; } = 0;

        [Required]
        public bool IsSupervisor { get; set; } = false;

        [Required]
        public bool IsCoopSupplier { get; set; } = false;

        // Read-only property for FullName_Calc (not directly mapped to the database)
        [NotMapped]
        public string FullName => $"{LastName}{(string.IsNullOrEmpty(FirstName) ? "" : ", " + FirstName)}";
    }
}
