using System;
using System.Collections.Generic;
using System.Linq;

namespace LW_Data
{
    public class clsPhysicalInvHelper
    {
        private readonly LWDbContext _context;  // Class-level field

        // Public constructor to instantiate _context
        public clsPhysicalInvHelper()
        {
            _context = new LWDbContext();
        }

        // Method should return a list of records
        public List<clsPhysicalInventoryRecord> GetAllPIRecords(int numToTake)
        {
            return _context.tblPhysicalInventory
                    .Where(a => a.AsOfDate.HasValue && !string.IsNullOrEmpty(a.Code))
                    .OrderBy(a => a.Code)
                    .Take(numToTake) // Take only the records for the current page
                    .ToList();
        }

        public List<clsPhysicalInventoryRecord> GetFilteredRecords(int numToTake, DateTime? FilterAsOfDate, string FilterItemCode )
        {
            var records = _context.tblPhysicalInventory.AsQueryable();
            records = records.Where(r => r.AsOfDate != null);   // We should never have NULL PayDates, but filter in case

            if (FilterAsOfDate.HasValue)
            {
                records = records.Where(r => r.AsOfDate == FilterAsOfDate.Value);
            }

            if (!string.IsNullOrEmpty(FilterItemCode))
            {
                records = records.Where(r => r.Code.Contains(FilterItemCode));
            }

            return records.Take(numToTake).ToList();
        }

        public clsPhysicalInventoryRecord GetPIRecord(int PIRowID)
        {
            return _context.tblPhysicalInventory.Find(PIRowID);
        }

        /// <summary>
        /// ModBy and PIRowID is required - Uses the SaveToDB in the clsPIRecord suing StoredProcedure
        /// </summary>
        /// <param name="updatedRecord"></param>
        /// <returns></returns>
        public bool SaveToDB(clsPhysicalInventoryRecord updatedRecord, string ModByFirstName)
        {
            clsPhysicalInventoryRecord record = new clsPhysicalInventoryRecord();   

            if (updatedRecord.PIRowID > 0) { // Pull the row and then save changes otherwise it's a new record
                record = _context.tblPhysicalInventory.Find(updatedRecord.PIRowID);
            }  

            record.AsOfDate = updatedRecord.AsOfDate;
            record.Code = updatedRecord.Code;
            record.PhysicalCount = updatedRecord.PhysicalCount;
            record.Description = updatedRecord.Description;

            return record.SaveToDB(ModByFirstName);   // Use the SaveToDB in the Record Class so we can use the Stored Procedure
        }

        public bool DeleteFromDB(int PIRowID)
        {
            var record = _context.tblPhysicalInventory.Find(PIRowID);
            if (record != null)
            {
                _context.tblPhysicalInventory.Remove(record);
                _context.SaveChanges();

                return true;
            }
            return false;
        }

    }
}

