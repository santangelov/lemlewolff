using LW_Data;
using MailKit;
using MailKit.Net.Imap;
using MailKit.Search;
using MailKit.Security;
using Microsoft.Office.Interop.Excel;
using MimeKit;
using Org.BouncyCastle.Asn1.X509;
using System;
using System.Configuration;
using System.Data;
using System.IO;
using System.Linq;
using System.Net;
using System.Runtime.InteropServices.WindowsRuntime;
using System.Security.Authentication;
using System.Security.Cryptography;
using System.Text.RegularExpressions;
using System.Web.Hosting;
using System.Web.UI.WebControls;

namespace LW_Common
{

    public class EmailImporter
    {
        public string err_msg { get; set; } = "";
        public string success_msg { get; set; } = "";

        private readonly string _imapServer = ConfigurationManager.AppSettings["Import_imapServer"];
        private readonly int _imapPort = int.Parse(ConfigurationManager.AppSettings["Import_imapPort"]);
        private readonly bool _IMAPuseSsl = bool.Parse(ConfigurationManager.AppSettings["Import_UseSsl"]);
        private readonly string _username = ConfigurationManager.AppSettings["Import_imapUserName"];
        private readonly string _password = ConfigurationManager.AppSettings["Import_imapPassword"];
        private readonly string _YardiEmailAddress = ConfigurationManager.AppSettings["YardiEmailAddress"];
        private readonly string _saveDirectory = HostingEnvironment.MapPath(ConfigurationManager.AppSettings["FileUploadFolder"]);
        private readonly string _RegexFileNamePattern = ConfigurationManager.AppSettings["Import_ExportRegexFilePattern"];

        public bool CheckEmailAndImport()
        {
            Regex _filenamePattern = new Regex(_RegexFileNamePattern, RegexOptions.IgnoreCase);
            err_msg = "";
            bool retVal = true;

            using (var client = new MailKit.Net.Imap.ImapClient())
            {
                client.SslProtocols = SslProtocols.Tls12 | SslProtocols.Tls13;
                client.CheckCertificateRevocation = false;
                client.Connect(_imapServer, _imapPort, SecureSocketOptions.SslOnConnect);
                client.Authenticate(_username, _password);

                var inbox = client.Inbox;
                inbox.Open(FolderAccess.ReadWrite);

                // Search for messages with subject "Scheduler Reports"
                var uids = inbox.Search(SearchQuery.SubjectContains("Scheduler Reports"));
                if (uids.Count > 0)
                {
                    // Get the most recent message matching the subject
                    var lastUid = uids.Last();  // Use .Last() to get the latest one
                    var message = inbox.GetMessage(lastUid);

                    // Clear out the working folder
                    clsFunc.DeleteMatchingFiles(_saveDirectory, _RegexFileNamePattern);

                    // Save attachments that match the regex
                    foreach (var attachment in message.Attachments)
                    {
                        if (attachment is MimeKit.MimePart part)
                        {
                            if (_filenamePattern.IsMatch(part.FileName))
                            {
                                var filePath = Path.Combine(_saveDirectory, message.Date.ToString("yyyy-MM-dd_") + part.FileName);
                                using (var stream = File.Create(filePath))
                                {
                                    part.Content.DecodeTo(stream);
                                }
                            }
                        }
                    }

                    // Delete or move the message so it is not processed any further
                    IMailFolder archiveOrTrashFolder = null;
                    try
                    {
                        archiveOrTrashFolder = inbox.GetSubfolder("Import_Archive");
                    }
                    catch
                    {
                        archiveOrTrashFolder = inbox.Create("Import_Archive", true);
                    }
                    archiveOrTrashFolder.Open(FolderAccess.ReadWrite);

                    // Re-open inbox in ReadWrite mode, as it may have been closed by the server
                    if (!inbox.IsOpen || inbox.Access != FolderAccess.ReadWrite) inbox.Open(FolderAccess.ReadWrite);

                    inbox.MoveTo(uids, archiveOrTrashFolder);
                } 
                else 
                {                     
                    err_msg = "No emails found with subject 'Scheduler Reports'.";
                    clsUtilities.SendEmail("vinny@pixelmarsala.com", "LW Data Load Completed [NO FILES]", "<strong>ERRORS:<br></strong>" + @err_msg + "<br><br><strong>SUCCESS:</strong><br>" + success_msg.Replace("successfully.", "successfully.<br>"));
                    return true;
                }

                client.Disconnect(true);
            }

            // Process the saved files as before
            var files = Directory.GetFiles(_saveDirectory)
                                 .OrderBy(f => Path.GetFileName(f))
                                 .ToList();

            string archiveFolder = Path.Combine(_saveDirectory, "_Archive");
            Directory.CreateDirectory(archiveFolder);

            string emailLog = "";

            foreach (var filePath in files)
            {
                string fileName = Path.GetFileName(filePath);
                int fileNum = ExtractFileNumber(fileName);
                clsYardiHelper Y = new clsYardiHelper();

                // Run the appropriate import function
                int limitRowsForDebugging = -1;
#if DEBUG
                limitRowsForDebugging = 250; // Limit rows for debugging
#endif

                switch (fileNum)
                {
                    case 1:
                        if (!Y.Import_YardiWO_File(filePath, limitRowsForDebugging)) { err_msg += "FILE #1: " + Y.Error_Log; retVal = false; } else { success_msg += "FILE #1: " + fileName + ";" + Y.RowsProcessed.ToString() + " rows imported successfully.\n"; }
                        break;
                    case 2:
                        if (!Y.Import_YardiPO_File(filePath, limitRowsForDebugging)) { err_msg += "FILE #2: " + Y.Error_Log; retVal = false; } else { success_msg += "FILE #2: " + fileName + ";" + Y.RowsProcessed.ToString() + " rows imported successfully.\n"; }
                        break;
                    case 3:
                        if (!Y.Import_YardiWO_InventoryFile(filePath, limitRowsForDebugging)) { err_msg += "FILE #3: " + Y.Error_Log; retVal = false; } else { success_msg += "FILE #3: " + fileName + ";" + Y.RowsProcessed.ToString() + " rows imported successfully.\n"; }
                        break;
                    case 4:
                        if (!Y.Import_YardiPO_InventoryFile(filePath, limitRowsForDebugging)) { err_msg += "FILE #4: " + Y.Error_Log; retVal = false; } else { success_msg += "FILE #4: " + fileName + ";" + Y.RowsProcessed.ToString() + " rows imported successfully.\n"; }
                        break;
                    case 5:
                        if (!Y.Import_YardiWO_GeneralFile(filePath, limitRowsForDebugging)) { err_msg += "FILE #5: " + Y.Error_Log; retVal = false; } else { success_msg += "FILE #5: " + fileName + ";" + Y.RowsProcessed.ToString() + " rows imported successfully.\n"; }
                        break;
                    case 6:
                        if (!Y.Import_YardiProperty_File(filePath, limitRowsForDebugging)) { err_msg += "FILE #6: " + Y.Error_Log; retVal = false; } else { success_msg += "FILE #6: " + fileName + ";" + Y.RowsProcessed.ToString() + " rows imported successfully.\n"; }
                        break;
                    default:
                        continue;
                }

                try
                {
                    string timestamp = DateTime.Now.ToString("yyyyMMdd_HHmmss");
                    string archivedFileName = $"{timestamp}_{fileName}";
                    string archivedFilePath = Path.Combine(archiveFolder, archivedFileName);
                    File.Move(filePath, archivedFilePath);
                }
                catch 
                {
                    // Log error if needed
                }   

            }

            if (err_msg == "")
            {
                err_msg = "No errors.";
            }   
            if (success_msg == "")
            {
                success_msg = "No files processed.";
            }

            // Send email with results to me and John
            string body = "<strong>ERRORS:<br></strong>" + @err_msg + "<br><br><strong>SUCCESS:</strong><br>" + success_msg.Replace("successfully.", "successfully.<br>");
            clsUtilities.SendEmail("vinny@pixelmarsala.com", "LW Data Load Completed", body, "jrebuth@lemlewolff.com");
            return retVal;
        }

        private static int ExtractFileNumber(string fileName)
        {
            // Define the capturing group around File0[1-6]
            // -- LW_Portal_Export-File01_amc.xlsx
            string pattern = @"File(\d{2})_";

            Match match = Regex.Match(fileName, pattern);

            if (match.Success)
            {
                return int.Parse(match.Groups[1].Value); // "01", "02", ..., "06"
            }

            return -1;
        }
    }
}
