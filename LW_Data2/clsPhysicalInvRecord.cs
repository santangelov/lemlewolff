using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Runtime.Remoting.Messaging;

namespace LW_Data
{
    public class clsPhysicalInventoryRecord
    {
        [Key]
        public int PIRowID { get; set; } = -1;
        public DateTime? AsOfDate { get; set; }
        [StringLength(10)]
        public string Code { get; set; }
        public string Description { get; set; }
        public int PhysicalCount { get; set; }
        [StringLength(25)]
        public string CreatedBy { get; set; }
        public DateTime? CreateDate { get; set; }
        [StringLength(25)]
        public string modBy { get; set; }
        public DateTime? modDate { get; set; }

        [NotMapped]
        public string ErrorMessage { get; set; } = "";

        /// <summary>
        /// Uses Stored Procedure spPhysicalInvUpdate to process updates
        /// </summary>
        /// <returns></returns>
        public bool SaveToDB(string EditedByFirstName)
        {
            bool isSuccess = false;
            try
            {
                clsDataHelper dh = new clsDataHelper();
                if (this.PIRowID > 0)
                {
                    dh.cmd.Parameters.AddWithValue("@PIRowID", this.PIRowID);
                    dh.cmd.Parameters.AddWithValue("@modDate", DateTime.Now.ToString());
                    dh.cmd.Parameters.AddWithValue("@modBy", EditedByFirstName);
                }
                else
                {
                    dh.cmd.Parameters.AddWithValue("@createDate", DateTime.Now.ToString());
                    dh.cmd.Parameters.AddWithValue("@createdBy", EditedByFirstName);
                }
                dh.cmd.Parameters.AddWithValue("@AsOfDate", this.AsOfDate);
                dh.cmd.Parameters.AddWithValue("@Code", this.Code);
                dh.cmd.Parameters.AddWithValue("@Description", this.Description);
                dh.cmd.Parameters.AddWithValue("@PhysicalCount", this.PhysicalCount);

                isSuccess = dh.ExecuteSPCMD("spPhysicalInventoryUpdate", true);
            }
            catch (Exception e)
            {
                this.ErrorMessage = e.Message;
                isSuccess = false;
            }

            return isSuccess;
        }

    }
}
