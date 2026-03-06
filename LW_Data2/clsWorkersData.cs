using System.Collections.Generic;
using System.Linq;

namespace LW_Data
{
    public class clsWorkersData
    {
        public List<clsWorkerRecord> GetWorkers()
        {
            using (var db = new LWDbContext())
            {
                return db.tblWorkers
                    .Where(w => w.IsActive)
                    .OrderBy(w => w.DisplayName)
                    .ThenBy(w => w.CompanyCode)
                    .ThenBy(w => w.ADPFileNumber)
                    .ToList();
            }
        }
    }
}
