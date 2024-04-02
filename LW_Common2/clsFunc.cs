using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Runtime.Serialization.Formatters.Binary;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace LW_Common
{
    public sealed class clsFunc
    {
        public static int CastToInt(object value, int defaultValue)
        {
            try
            {
                int i = 0;
                if (value == null || value == DBNull.Value || !int.TryParse(value.ToString(), out i))
                {
                    return defaultValue;
                }
                else { return i; }
            }
            catch (Exception ex)
            {
                return defaultValue;
            }
        }

        public static bool CastToBool(object value, bool defaultValue = false)
        {
            try
            {
                bool d = false;
                if (value == null || value == DBNull.Value || !bool.TryParse(value.ToString(), out d))
                {
                    return defaultValue;
                }
                else { return bool.Parse(value.ToString()); }
            }
            catch (Exception ex)
            {
                return defaultValue;
            }
        }

        public static DateTime CastToDateTime(object value, DateTime defaultValue)
        {
            try
            {
                DateTime d;
                if (value == null || value == DBNull.Value || !DateTime.TryParse(value.ToString(), out d))
                {
                    return defaultValue;
                }
                else { return DateTime.Parse(value.ToString()); }
            }
            catch (Exception ex)
            {
                return defaultValue;
            }
        }


        public static decimal CastToDec(object value, decimal defaultValue)
        {
            try
            {
                decimal d = 0;
                if (value == null || value == DBNull.Value || !decimal.TryParse(value.ToString(), out d))
                {
                    return defaultValue;
                }
                else { return decimal.Parse(value.ToString()); }
            }
            catch (Exception ex)
            {
                return defaultValue;
            }
        }

        public static string CastToStr(object value, string defaultValue = "")
        {
            try
            {
                if (string.IsNullOrEmpty(value.ToString()))
                {
                    return defaultValue;
                }
                else { return value.ToString(); }
            }
            catch (Exception ex)
            {
                return defaultValue;
            }
        }



    }
}
