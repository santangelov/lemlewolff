using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Security.Policy;

namespace LW_Data
{
    public class clsPropertyRecord
    {
        [Key]
        public int yardiPropertyRowID { get; set; }

        [Required]
        public string buildingCode { get; set; }

        public string addr1_Co { get; set; }
        public bool isInactive { get; set; }
        public string fullAddress_calc { get; set; }  // calculated field in database
        public bool isInList_Posting { get; set; }
        public bool isInList_Aquinas { get; set; }
    }


}
