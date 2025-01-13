using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace LW_Data
{
    public class clsUserRecord
    {
        [Key]
        public int UserID { get; set; }

        [Required]
        public string EmailAddress {get; set;}

        public string FirstName {get; set;}
        public string LastName {get; set;}
        public string password_enc {get; set;}
        public bool isAdmin { get; set; } = false;
        public bool isSuperAdmin { get; set; } = false;
        public bool isDisabled { get; set; } = false;
    }
}
