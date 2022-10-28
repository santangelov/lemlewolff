using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;
using Newtonsoft.Json;
using System.Diagnostics.PerformanceData;
using System.Runtime.Caching;

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
                    return new clsCounter { Message = "No import in progress." };
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
    }
}
