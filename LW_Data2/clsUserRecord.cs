using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Security.Cryptography.Xml;

namespace LW_Data
{
    public class clsUserRecord
    {
        [Key]
        public int UserID { get; set; } = 0;

        [Required]
        public string EmailAddress { get; set; }

        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string password_enc { get; set; }
        public bool isProjectManager { get; set; } = false;
        public bool isAdmin { get; set; } = false;
        public bool isSuperAdmin { get; set; } = false;
        public bool isDisabled { get; set; } = false;
        public string tempPassword_enc { get; set; }

        public bool GetUserByEmail(string email)
        {
            using (LWDbContext db = new LWDbContext())
            {
                clsUserRecord user = db.tblUsers.FirstOrDefault(u => u.EmailAddress == email);
                if (user is null) { return false; }
                this.UserID = user.UserID;
                this.EmailAddress = user.EmailAddress;
                this.FirstName = user.FirstName;
                this.LastName = user.LastName;
                this.password_enc = user.password_enc;
                this.isProjectManager = user.isProjectManager;
                this.isAdmin = user.isAdmin;
                this.isSuperAdmin = user.isSuperAdmin;
                this.isDisabled = user.isDisabled;
                this.tempPassword_enc = user.tempPassword_enc;
            }
            return true;
        }

        public bool ChangePassword(string newPassword_enc)
        {
            using (LWDbContext db = new LWDbContext())
            {
                clsUserRecord user = db.tblUsers.FirstOrDefault(u => u.UserID == this.UserID);
                if (user is null) { return false; }
                user.password_enc = newPassword_enc;
                user.tempPassword_enc = null;
                db.SaveChanges();
            }
            return true;
        }       
    }
}
