using System;
using System.IO;
using System.Text.RegularExpressions;

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
            catch 
            {
                return defaultValue;
            }
        }

        public static DateTime GetEndOfMonth(DateTime? startDate)
        {
            var basis = (startDate ?? DateTime.Today).Date; // if null, use current month
            return new DateTime(basis.Year, basis.Month, DateTime.DaysInMonth(basis.Year, basis.Month));
        }

        /// <summary>
        /// Convert Object or String to an Int, rounding the value if it is a double.
        /// </summary>
        /// <param name="value"></param>
        /// <returns></returns>
        public static int ToRoundedInt(object value)
        {
            if (value == null || string.IsNullOrWhiteSpace(value.ToString()))
                return 0; // or handle as needed

            double d;
            if (double.TryParse(value.ToString(), out d))
                return (int)Math.Round(d);

            return 0; // or handle as needed
        }

        public static int DeleteMatchingFiles(string folderPath, string RegExFilePattern)
        {
            Regex FilePatternReg = new Regex(RegExFilePattern, RegexOptions.IgnoreCase | RegexOptions.Compiled);

            if (!Directory.Exists(folderPath))
            {
                Console.WriteLine($"Folder not found: {folderPath}");
                return 0;
            }

            int deletedCount = 0;

            foreach (var filePath in Directory.GetFiles(folderPath))
            {
                string fileName = Path.GetFileName(filePath);

                if (FilePatternReg.IsMatch(fileName))
                {
                    try
                    {
                        File.Delete(filePath);
                        Console.WriteLine("Deleted: " + fileName);
                        deletedCount++;
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"Failed to delete {fileName}: {ex.Message}");
                    }
                }
            }

            return deletedCount;
        }

        public static bool CastToBool(object value, bool defaultValue = false)
        {
            if (value == null || value == DBNull.Value)
            {
                return defaultValue;
            }

            if (value is bool boolValue)
            {
                return boolValue;
            }

            if (value is int intValue)
            {
                return intValue == 1;
            }

            string strValue = value.ToString().Trim().ToLower();
            if (strValue == "true" || strValue == "1")
            {
                return true;
            }

            return false;
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
            catch 
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
            catch 
            {
                return defaultValue;
            }
        }

        public static string CastToStr(object value, string defaultValue = "")
        {
            if (value == null) { return defaultValue; }

            try
            {
                if (string.IsNullOrEmpty(value.ToString()))
                {
                    return defaultValue;
                }
                else { return value.ToString(); }
            }
            catch 
            {
                return defaultValue;
            }
        }



    }
}
