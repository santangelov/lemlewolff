using System.Data.Entity;

namespace LW_Data
{
    public class LWDbContext : DbContext
    {
        public LWDbContext() : base("name=LWSQLConnStrRW") { }

        // Define a DbSet for each table in your database
        public DbSet<clsADPRecord> tblADP { get; set; }
        public DbSet<clsLaborerRecord> tblLaborers { get; set; }
        public DbSet<clsUserRecord> tblUsers { get; set; }
        public DbSet<clsPhysicalInventoryRecord> tblPhysicalInventory { get; set; }
        public DbSet<clsVendorRecord> tblVendors { get; set; }

        protected override void OnModelCreating(DbModelBuilder modelBuilder)
        {
            // Configure mappings for each table to link the CLASS name to the actual TABLE name in the database
            base.OnModelCreating(modelBuilder);
            modelBuilder.Entity<clsADPRecord>().ToTable("tblADP", "dbo");
            modelBuilder.Entity<clsLaborerRecord>().ToTable("tblLaborers", "dbo");
            modelBuilder.Entity<clsUserRecord>().ToTable("tblUsers", "dbo");
            modelBuilder.Entity<clsPhysicalInventoryRecord>().ToTable("tblPhysicalInventory", "dbo");
            modelBuilder.Entity<clsVendorRecord>().ToTable("tblVendors", "dbo");
        }
    }
}
