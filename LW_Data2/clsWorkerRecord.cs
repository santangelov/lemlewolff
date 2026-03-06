using System.ComponentModel.DataAnnotations;

namespace LW_Data
{
    public class clsWorkerRecord
    {
        [Key]
        public int WorkerID { get; set; }
        public string CompanyCode { get; set; }
        public string ADPFileNumber { get; set; }
        public string DisplayName { get; set; }
        public bool IsActive { get; set; }
    }
}
