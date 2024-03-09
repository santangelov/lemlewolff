using System;
using System.IO;

namespace LW_Settings
{
    public class clsLoggingHelper
    {
        public static void WriteToAppLog(string message)
        {
            using (System.IO.StreamWriter file = File.AppendText(AppDomain.CurrentDomain.BaseDirectory + @"\activitylog.log"))
            {
                file.WriteLine(DateTime.Now.ToString("MM-dd-yy hh:mm") + ": " + message);
            }
        }
    }
}
