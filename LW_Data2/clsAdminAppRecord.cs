using System.ComponentModel.DataAnnotations;

namespace LW_Data
{
    public class clsAdminAppRecord
    {
        [Key]
        public int AppID { get; set; }

        public string AppName { get; set; }
        public string URL { get; set; }
        public string LogoFilePath { get; set; }
    }
}
