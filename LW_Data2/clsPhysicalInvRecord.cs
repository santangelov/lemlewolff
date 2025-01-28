using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

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
        public bool SaveToDB()
        {
            bool isSuccess = false;
            try
            {
                clsDataHelper dh = new clsDataHelper();
                if (this.PIRowID > 0)
                {
                    dh.cmd.Parameters.AddWithValue("@PIRowID", this.PIRowID);
                    dh.cmd.Parameters.AddWithValue("@modDate", this.modDate);
                    dh.cmd.Parameters.AddWithValue("@modBy", this.modBy);
                }
                else
                {
                    dh.cmd.Parameters.AddWithValue("@createDate", this.CreateDate);
                    dh.cmd.Parameters.AddWithValue("@createdBy", this.CreatedBy);
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
