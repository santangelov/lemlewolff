﻿using Newtonsoft.Json;
using System;
using System.Data;
using System.Linq;
using System.Runtime.Caching;
using System.Text;

namespace LW_Common
{

    public class clsCounter
    {
        public string counterFlag { get; set; }
        public string Count { get; set; }
        public string Message { get; set; }
    }

    public class clsUtilities
    {
        public string err_msg = "";

        /// <summary>
        /// The Counters are stored in memory cache
        /// </summary>
        /// <param name="CounterName"></param>
        /// <param name="counterText"></param>
        public static void WriteToCounter(string CounterName, string counterText)
        {
            clsCounter C = new clsCounter { Count = counterText };

            ObjectCache cache = MemoryCache.Default;
            var cacheItemPolicy = new CacheItemPolicy { AbsoluteExpiration = DateTimeOffset.Now.AddSeconds(30.0), };

            if (!cache.Contains("Counter_" + CounterName))
            {
                cache.Add("Counter_" + CounterName, JsonConvert.SerializeObject(C), cacheItemPolicy);
            }
            else
            {
                cache.Set("Counter_" + CounterName, JsonConvert.SerializeObject(C), cacheItemPolicy);
            }
        }
        public static clsCounter ReadCounter(string CounterName)
        {
            ObjectCache cache = MemoryCache.Default;

            try
            {
                if (!cache.Contains("Counter_" + CounterName))
                {
                    return new clsCounter { Message = "...", Count = "..." };
                }
                else
                {
                    return JsonConvert.DeserializeObject<clsCounter>(cache.Get("Counter_" + CounterName).ToString());
                }
            }
            catch (Exception)
            {
                return new clsCounter { Message = "Counter Read error..." };
            }

        }
        public static string DataTableToDelimitedFile(ref DataTable dt, string Delimiter)
        {
            try
            {
                var builder = new StringBuilder();
                // The headers
                string[] columnNames = dt.Columns.Cast<DataColumn>().Select(x => x.ColumnName).ToArray();
                builder.AppendLine(String.Join("\t", columnNames));

                // The Data
                foreach (DataRow row in dt.Rows)
                {
                    builder.AppendLine(String.Join("\t", row.ItemArray));
                }
                //File.WriteAllText(outFile, builder.ToString());
                return builder.ToString();
            }
            catch (Exception e)
            {
                return "ERROR: " + e.Message;
            }
        }
    }

}
