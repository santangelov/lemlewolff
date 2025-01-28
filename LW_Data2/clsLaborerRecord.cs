using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

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
        public decimal? LWSalariedHourlyRate { get; set; }
        public decimal? LWSmJobMinRateAdj { get; set; }
        public decimal? LWOTRate { get; set; }
        public decimal? LWMaterialRate { get; set; }
        public decimal? WageIncrease2022 { get; set; }
        [Required]
        public bool IncludeForInventory { get; set; } = true;
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
