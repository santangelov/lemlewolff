using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LW_Data
{
    public class clsSortlyModels
    {
        public class SortlyFolder
        {
            public int Id { get; set; }
            public string Name { get; set; }
        }

        public class SortlyItem
        {
            public int Id { get; set; }
            public string Name { get; set; }
            public string Type { get; set; }    
            public string FolderPath { get; set; }
            public decimal? price { get; set; }  
            public decimal? quantity { get; set; }   
            public string notes { get; set; }   
            public string sid { get; set; }
        }

        public class SortlyMetaData
        {
            public bool HasMore { get; set; }
            public int CurrentPage { get; set; }
            public int TotalPages { get; set; }
        }

        public class SortlyResponse<T>
        {
            public List<T> Data { get; set; }
            public SortlyMetaData Meta { get; set; }
        }
    }
}
