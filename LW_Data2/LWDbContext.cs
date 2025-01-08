using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Data.Entity;

namespace LW_Data
{
    public class LWDbContext : DbContext
    {
        public LWDbContext() : base("name=LWSQLConnStrRW") { }

        // Define a DbSet for each table in your database
        public DbSet<clsADPRecord> tblADP { get; set; }
        public DbSet<clsLaborerRecord> tblLaborers { get; set; }


        protected override void OnModelCreating(DbModelBuilder modelBuilder)
        {
            // Configure mappings if necessary (optional)
            base.OnModelCreating(modelBuilder);
            modelBuilder.Entity<clsADPRecord>().ToTable("tblADP", "dbo");
            modelBuilder.Entity<clsLaborerRecord>().ToTable("tblLaborers", "dbo");
        }
    }
}
