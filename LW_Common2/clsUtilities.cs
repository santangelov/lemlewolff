using Newtonsoft.Json;
using System;
using System.Configuration;
using System.Data;
using System.Linq;
using MailKit.Net.Smtp;
using MimeKit;
using System.Runtime.Caching;
using System.Text;
using System.Threading.Tasks;
using System.Net;

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

        public static bool SendEmail(string ToEmail, string Subject, string BodyHTML)
        {
            // Set these settings in the web.config file: SMTPServer, SMTPPort, FromEmailAddress, FromEmailPassword
            // Example: <add key="SMTPServer" value="smtp.gmail.com" />

            string SMTPServer = ConfigurationManager.AppSettings["SMTPServer"];
            int SMTPPort = int.Parse(ConfigurationManager.AppSettings["SMTPPort"]);
            string FromEmailAddress = ConfigurationManager.AppSettings["FromEmailAddress"];
            string FromEmailPassword = ConfigurationManager.AppSettings["FromEmailPassword"];
            bool SMTPEnableSSL = bool.Parse(ConfigurationManager.AppSettings["SMTPEnableSSL"]);

            System.Net.Mail.SmtpClient client = new System.Net.Mail.SmtpClient(SMTPServer, SMTPPort);
            client.UseDefaultCredentials = false;
            client.Credentials = new System.Net.NetworkCredential(FromEmailAddress, FromEmailPassword);
            client.EnableSsl = SMTPEnableSSL;
            client.Timeout = 12000;

            System.Net.Mail.MailMessage mailMessage = new System.Net.Mail.MailMessage(FromEmailAddress, ToEmail);
            mailMessage.IsBodyHtml = true;
            mailMessage.Subject = Subject;
            mailMessage.Body = BodyHTML;

//#if DEBUG
            // Disable certificate validation (should be for testing only - but Rackspace is only working disabling validation)
            ServicePointManager.ServerCertificateValidationCallback = (sender, certificate, chain, sslPolicyErrors) => true;
//#endif
            ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12;

            try
            {
                client.Send(mailMessage);
                return true;
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.ToString());
                return false;
            }

        }
}

}
