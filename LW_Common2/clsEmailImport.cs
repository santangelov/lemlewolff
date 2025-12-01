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

#if DEBUG
        private readonly string _LogFile = @"C:\Users\Vincent\Documents\BUSINESS\Lemle And Wolff\LOADS\WEEKLY LOADS\YardiImportLog.txt";
#else 
        private readonly string _LogFile = @"F:\inetpub\wwwroot\lemlewolff.net\_Logs\YardiImportLog.txt";
#endif

        private readonly string _EmailResults_TO = ConfigurationManager.AppSettings["EmailAddress_YardiImportConfirmationEmil"];
        private readonly string _EmailResults_CC = ConfigurationManager.AppSettings["EmailAddressCC1_YardiImportConfirmationEmil"];
        private readonly string _EmailResults_CC2 = ConfigurationManager.AppSettings["EmailAddressCC2_YardiImportConfirmationEmil"];
        private readonly string _EmailResults_CC3 = ConfigurationManager.AppSettings["EmailAddressCC3_YardiImportConfirmationEmil"];

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
                    err_msg = DateTime.Now.ToString("MM/dd/yyyy hh:mm:ss") + ": Check Email (Yardi imports): No emails found with subject 'Scheduler Reports'.\n";
                    System.IO.File.AppendAllText(_LogFile, err_msg, System.Text.Encoding.Unicode);
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
                        clsGeneralImportHelper.ClearTempImportTable(clsGeneralImportHelper.TableCodes.YardiWO);
                        if (!Y.Import_YardiWO_File(filePath, limitRowsForDebugging)) { err_msg += "<span style=\"color: red;\">FILE #1: </span>" + Y.Error_Log; retVal = false; } else { success_msg += "<span style=\"color: green;\">FILE #1: </span>" + fileName + ";" + Y.RowsProcessed.ToString() + " rows imported successfully.\n"; }
                        break;
                    case 2:
                        clsGeneralImportHelper.ClearTempImportTable(clsGeneralImportHelper.TableCodes.YardiPO);
                        if (!Y.Import_YardiPO_File(filePath, limitRowsForDebugging)) { err_msg += "<span style=\"color: red;\">FILE #2: </span>" + Y.Error_Log; retVal = false; } else { success_msg += "<span style=\"color: green;\">FILE #2: </span>" + fileName + ";" + Y.RowsProcessed.ToString() + " rows imported successfully.\n"; }
                        break;
                    case 3:
                        clsGeneralImportHelper.ClearTempImportTable(clsGeneralImportHelper.TableCodes.InventoryWO);
                        if (!Y.Import_YardiWO_InventoryFile(filePath, limitRowsForDebugging)) { err_msg += "<span style=\"color: red;\">FILE #3: </span>" + Y.Error_Log; retVal = false; } else { success_msg += "<span style=\"color: green;\">FILE #3: </span>" + fileName + ";" + Y.RowsProcessed.ToString() + " rows imported successfully.\n"; }
                        break;
                    case 4:
                        clsGeneralImportHelper.ClearTempImportTable(clsGeneralImportHelper.TableCodes.InventoryPO);
                        if (!Y.Import_YardiPO_InventoryFile(filePath, limitRowsForDebugging)) { err_msg += "<span style=\"color: red;\">FILE #4: </span>" + Y.Error_Log; retVal = false; } else { success_msg += "<span style=\"color: green;\">FILE #4: </span>" + fileName + ";" + Y.RowsProcessed.ToString() + " rows imported successfully.\n"; }
                        break;
                    case 5:
                        clsGeneralImportHelper.ClearTempImportTable(clsGeneralImportHelper.TableCodes.YardiWO2);
                        if (!Y.Import_YardiWO_GeneralFile(filePath, limitRowsForDebugging)) { err_msg += "<span style=\"color: red;\">FILE #5: </span>" + Y.Error_Log; retVal = false; } else { success_msg += "<span style=\"color: green;\">FILE #5: </span>" + fileName + ";" + Y.RowsProcessed.ToString() + " rows imported successfully.\n"; }
                        break;
                    case 6:
                        if (!Y.Import_YardiProperty_File(filePath, limitRowsForDebugging)) { err_msg += "<span style=\"color: red;\">FILE #6: </span>" + Y.Error_Log; retVal = false; } else { success_msg += "<span style=\"color: green;\">FILE #6: </span>" + fileName + ";" + Y.RowsProcessed.ToString() + " rows imported successfully.\n"; }
                        break;
                    case 7:
                        clsGeneralImportHelper.ClearTempImportTable(clsGeneralImportHelper.TableCodes.Tenants07);
                        if (!Y.Import_Staging_Tenants(filePath, limitRowsForDebugging)) { err_msg += "<span style=\"color: red;\">FILE #7: </span>" + Y.Error_Log; retVal = false; } else { success_msg += "<span style=\"color: green;\">FILE #7: </span>" + fileName + ";" + Y.RowsProcessed.ToString() + " rows imported successfully.\n"; }
                        break;
                    case 8:
                        clsGeneralImportHelper.ClearTempImportTable(clsGeneralImportHelper.TableCodes.CaseActions08);
                        if (!Y.Import_Staging_LegalCaseActions(filePath, limitRowsForDebugging)) { err_msg += "<span style=\"color: red;\">FILE #8: </span>" + Y.Error_Log; retVal = false; } else { success_msg += "<span style=\"color: green;\">FILE #8: </span>" + fileName + ";" + Y.RowsProcessed.ToString() + " rows imported successfully.\n"; }
                        break;
                    case 9:
                        clsGeneralImportHelper.ClearTempImportTable(clsGeneralImportHelper.TableCodes.CaseHeaders09);
                        if (!Y.Import_Staging_LegalCaseHeaders(filePath, limitRowsForDebugging)) { err_msg += "<span style=\"color: red;\">FILE #9: </span>" + Y.Error_Log; retVal = false; } else { success_msg += "<span style=\"color: green;\">FILE #9: </span>" + fileName + ";" + Y.RowsProcessed.ToString() + " rows imported successfully.\n"; }
                        break;
                    case 10:
                        clsGeneralImportHelper.ClearTempImportTable(clsGeneralImportHelper.TableCodes.DailyARbyTenant10);
                        if (!Y.Import_Staging_TenantARSummary(filePath, limitRowsForDebugging)) { err_msg += "<span style=\"color: red;\">FILE #10: </span>" + Y.Error_Log; retVal = false; } else { success_msg += "<span style=\"color: green;\">FILE #10: </span>" + fileName + ";" + Y.RowsProcessed.ToString() + " rows imported successfully.\n"; }
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

            // Send email with results - Set recipients in Web.Config
            string body = "<p>Hello Team,</p><p>This automated message reports the results of the Yardi data import completed at " + DateTime.Now.ToString("MM/dd/yyyy h:mm tt") + ".</p><p><strong>ERRORS:<br></strong>" + @err_msg + "<br><br><strong>SUCCESS:</strong><br>" + success_msg.Replace("successfully.", "successfully.<br>") + "</p>";
            string signature = "<p><br>LemleWolff Online Portal<br>\r\nonlineportal@lemlewolff.net<br>\r\nportal.lemlewolff.net</p>";
            string footerMsg = "<p><br><br><center><i style=\"color:#666;\">This is an automated email from the Lemle & Wolff Yardi Importer.</i></center></p>";
            string subjectTag = (err_msg == "No errors.") ? "[OK]" : "[ERROR]";  
            clsUtilities.SendEmail(_EmailResults_TO, "LW Data Load Completed " + subjectTag, body + signature + footerMsg, _EmailResults_CC, _EmailResults_CC2, _EmailResults_CC3);
            System.IO.File.AppendAllText(_LogFile, DateTime.Now.ToString("yyyy/MM/dd hh:mm") + ": " + body, System.Text.Encoding.Unicode);
            System.IO.File.AppendAllText(_LogFile, DateTime.Now.ToString("yyyy/MM/dd hh:mm") + ": Done.", System.Text.Encoding.Unicode);

            return retVal;
        }
        
        private static int ExtractFileNumber(string fileName)
        {
            // Define the capturing group around File0[1-6]
            // -- LW_Portal_Export-File01_amc.xlsx,   LW_Portal_Export-File10_amc.xlsx
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
