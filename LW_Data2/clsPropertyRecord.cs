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
        //public string addr2 { get; set; }
        //public string addr3 { get; set; }
        //public string addr4 { get; set; }
        //public string city { get; set; }
        //public string stateCode { get; set; }
        //public string zipCode { get; set; }
        public bool isInactive { get; set; }
        public string fullAddress_calc { get; set; }  // calculated field in database
        public bool isInList_Posting { get; set; }  
    }


}
