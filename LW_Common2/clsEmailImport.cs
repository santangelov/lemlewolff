using LW_Data;
using MailKit;
using MailKit.Net.Imap;
using MailKit.Search;
using MailKit.Security;
using Microsoft.Office.Interop.Excel;
using MimeKit;
using Org.BouncyCastle.Asn1.X509;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Net;
using System.Runtime.InteropServices.WindowsRuntime;
using System.Security.Authentication;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using System.Web.Hosting;
using System.Web.UI.WebControls;

namespace LW_Common
{

    public class EmailImporter
    {
        public const int TotalEmailFilesToImport = 10;              // Set this number according to how many files are expected to be imported from email
        public const int TotalEmailFilesToImport_Monthly = 4;       // Monthly counts are less (4 files instead of 10)
        // Guardrail + importer notes:
        // - Filename acceptance remains strict and unchanged (REGEX_FILE_PATTERN).
        // - Attachment saving behavior is unchanged (uses the existing filename).
        // - No new AppSettings were introduced for the guardrail schedule or remediation list.
        public const string REGEX_FILE_PATTERN = @"^\d{4}-\d{2}-\d{2}_LW_Portal_Export-File\d{2}_amc\.xlsx$";

        public string err_msg { get; set; } = "";
        public string success_msg { get; set; } = "";

        private readonly string _imapServer = ConfigurationManager.AppSettings["Import_imapServer"];
        private readonly int _imapPort = int.Parse(ConfigurationManager.AppSettings["Import_imapPort"]);
        private readonly bool _IMAPuseSsl = bool.Parse(ConfigurationManager.AppSettings["Import_UseSsl"]);
        private readonly string _username = ConfigurationManager.AppSettings["Import_imapUserName"];
        private readonly string _password = ConfigurationManager.AppSettings["Import_imapPassword"];
        private readonly string _YardiEmailAddress = ConfigurationManager.AppSettings["YardiEmailAddress"];
        private readonly string _saveDirectory = HostingEnvironment.MapPath(ConfigurationManager.AppSettings["FileUploadFolder"]);

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
            Regex _filenamePattern = new Regex(REGEX_FILE_PATTERN, RegexOptions.IgnoreCase);
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
                    clsFunc.DeleteMatchingFiles(_saveDirectory, REGEX_FILE_PATTERN);

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
            int fileCount = 0;

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
                        if (!Y.Import_YardiWO_File(filePath, limitRowsForDebugging)) { err_msg += "<span style=\"color: red;\">FILE #1: </span>" + Y.Error_Log; retVal = false; } else { success_msg += "<span style=\"color: green;\">FILE #1: </span>" + fileName + "; &nbsp;" + Y.RowsProcessed.ToString("#,##0") + " rows imported successfully.\n"; }
                        break;
                    case 2:
                        clsGeneralImportHelper.ClearTempImportTable(clsGeneralImportHelper.TableCodes.YardiPO);
                        if (!Y.Import_YardiPO_File(filePath, limitRowsForDebugging)) { err_msg += "<span style=\"color: red;\">FILE #2: </span>" + Y.Error_Log; retVal = false; } else { success_msg += "<span style=\"color: green;\">FILE #2: </span>" + fileName + "; &nbsp;" + Y.RowsProcessed.ToString("#,##0") + " rows imported successfully.\n"; }
                        break;
                    case 3:
                        clsGeneralImportHelper.ClearTempImportTable(clsGeneralImportHelper.TableCodes.InventoryWO);
                        if (!Y.Import_YardiWO_InventoryFile(filePath, limitRowsForDebugging)) { err_msg += "<span style=\"color: red;\">FILE #3: </span>" + Y.Error_Log; retVal = false; } else { success_msg += "<span style=\"color: green;\">FILE #3: </span>" + fileName + "; &nbsp;" + Y.RowsProcessed.ToString("#,##0") + " rows imported successfully.\n"; }
                        break;
                    case 4:
                        clsGeneralImportHelper.ClearTempImportTable(clsGeneralImportHelper.TableCodes.InventoryPO);
                        if (!Y.Import_YardiPO_InventoryFile(filePath, limitRowsForDebugging)) { err_msg += "<span style=\"color: red;\">FILE #4: </span>" + Y.Error_Log; retVal = false; } else { success_msg += "<span style=\"color: green;\">FILE #4: </span>" + fileName + "; &nbsp;" + Y.RowsProcessed.ToString("#,##0") + " rows imported successfully.\n"; }
                        break;
                    case 5:
                        clsGeneralImportHelper.ClearTempImportTable(clsGeneralImportHelper.TableCodes.YardiWO2);
                        if (!Y.Import_YardiWO_GeneralFile(filePath, limitRowsForDebugging)) { err_msg += "<span style=\"color: red;\">FILE #5: </span>" + Y.Error_Log; retVal = false; } else { success_msg += "<span style=\"color: green;\">FILE #5: </span>" + fileName + "; &nbsp;" + Y.RowsProcessed.ToString("#,##0") + " rows imported successfully.\n"; }
                        break;
                    case 6:
                        if (!Y.Import_YardiProperty_File(filePath, limitRowsForDebugging)) { err_msg += "<span style=\"color: red;\">FILE #6: </span>" + Y.Error_Log; retVal = false; } else { success_msg += "<span style=\"color: green;\">FILE #6: </span>" + fileName + "; &nbsp;" + Y.RowsProcessed.ToString("#,##0") + " rows imported successfully.\n"; }
                        break;
                    case 7:
                        clsGeneralImportHelper.ClearTempImportTable(clsGeneralImportHelper.TableCodes.Tenants07);
                        if (!Y.Import_Staging_Tenants(filePath, limitRowsForDebugging)) { err_msg += "<span style=\"color: red;\">FILE #7: </span>" + Y.Error_Log; retVal = false; } else { success_msg += "<span style=\"color: green;\">FILE #7: </span>" + fileName + "; &nbsp;" + Y.RowsProcessed.ToString("#,##0") + " rows imported successfully.\n"; }
                        break;
                    case 8:
                        clsGeneralImportHelper.ClearTempImportTable(clsGeneralImportHelper.TableCodes.CaseActions08);
                        if (!Y.Import_Staging_LegalCaseActions(filePath, limitRowsForDebugging)) { err_msg += "<span style=\"color: red;\">FILE #8: </span>" + Y.Error_Log; retVal = false; } else { success_msg += "<span style=\"color: green;\">FILE #8: </span>" + fileName + "; &nbsp;" + Y.RowsProcessed.ToString("#,##0") + " rows imported successfully.\n"; }
                        break;
                    case 9:
                        clsGeneralImportHelper.ClearTempImportTable(clsGeneralImportHelper.TableCodes.CaseHeaders09);
                        if (!Y.Import_Staging_LegalCaseHeaders(filePath, limitRowsForDebugging)) { err_msg += "<span style=\"color: red;\">FILE #9: </span>" + Y.Error_Log; retVal = false; } else { success_msg += "<span style=\"color: green;\">FILE #9: </span>" + fileName + "; &nbsp;" + Y.RowsProcessed.ToString("#,##0") + " rows imported successfully.\n"; }
                        break;
                    case 10:
                        clsGeneralImportHelper.ClearTempImportTable(clsGeneralImportHelper.TableCodes.DailyARbyTenant10);
                        if (!Y.Import_Staging_TenantARSummary(filePath, limitRowsForDebugging)) { err_msg += "<span style=\"color: red;\">FILE #10: </span>" + Y.Error_Log; retVal = false; } else { success_msg += "<span style=\"color: green;\">FILE #10: </span>" + fileName + "; &nbsp;" + Y.RowsProcessed.ToString("#,##0") + " rows imported successfully.\n"; }
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

                fileCount += 1;
            }

            bool countMismatch = (fileCount != TotalEmailFilesToImport && fileCount != TotalEmailFilesToImport_Monthly);

            // Be sure to run the Stored Procedures to process all imports
            bool addcountMismatchWarning = false;

            // Run Pre-Processing of data
            if (retVal && !countMismatch)
            {
                string errMsgOut = "";
                if (!clsReportHelper.RunAllReportSQL_Public(out errMsgOut))
                {
                    err_msg += "<span style=\"color: red;\">Data Error: </span>" + errMsgOut;
                    retVal = false;                 // IMPORTANT: fail the job
                }
            }
            else
            {
                if (countMismatch) addcountMismatchWarning = true;
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
            string subjectTag = (err_msg == "No errors.") ? "[OK]" : "[ERROR]";
            string body = "<p>Hello Team,</p><p>This automated message reports the results of the Yardi data import completed at " + DateTime.Now.ToString("MM/dd/yyyy h:mm tt") + ".</p><p><strong>ERRORS:<br></strong>" + @err_msg + "<br><br><strong>SUCCESS:</strong><br>" + success_msg.Replace("successfully.", "successfully.<br>") + "</p>";
            string signature = "<p><br>LemleWolff Online Portal<br>\r\nonlineportal@lemlewolff.net<br>\r\nportal.lemlewolff.net</p>";
            string footerMsg = "<p><br><br><center><i style=\"color:#666;\">This is an automated email from the Lemle & Wolff Yardi Importer.</i></center></p>";

            // In case later we add more warnings this will handle adding the subject tag correctly
            if (addcountMismatchWarning)
            {
                if (subjectTag == "[OK]")
                {
                    subjectTag = "[WARNING]";
                }
                else
                {
                    if (subjectTag == "[ERROR]")
                    {
                        subjectTag = "[ERROR & WARNING]";
                    }
                    else
                    {
                        subjectTag = "[WARNING]";
                    }
                }
            }

            if (addcountMismatchWarning)
            {
                if (countMismatch) body = "<p>WARNING: The expected number of files (Daily runs: " + TotalEmailFilesToImport.ToString() + "; Monthly runs: " + TotalEmailFilesToImport_Monthly.ToString() + ";) were not received. Please check the Yardi export process. " + fileCount.ToString() + " received.</p>" + body;
            }

            clsUtilities.SendEmail(_EmailResults_TO, "LW Data Load Completed " + subjectTag, body + signature + footerMsg, _EmailResults_CC, _EmailResults_CC2, _EmailResults_CC3);

            // ---------------------------------------------------------------------------------
            // Guardrail coverage check (Arrears Tracker)
            //
            // Purpose:
            //  - Quickly validate that the AR daily snapshot and tenant snapshot date resolution logic is still aligned
            //    after a successful import.
            //  - Confirm that the last 3 closed month-ends exist as true month-end snapshots.
            //
            // When it runs:
            //  - Only after a *successful* import (no errors + no file-count mismatch warning)
            //  - Only on a lightweight cadence (1st/2nd/15th of the month) to avoid noisy emails.
            //
            // Action:
            //  - If the QA fails, send a separate email to _EmailResults_TO with details.
            // ---------------------------------------------------------------------------------
            try
            {
                bool importsSucceeded = (retVal == true)
                                        && string.Equals(err_msg ?? "", "No errors.", StringComparison.OrdinalIgnoreCase)
                                        && (countMismatch == false);

                if (importsSucceeded && ShouldRunArrearsGuardrailQa(DateTime.Today))
                {
                    ArrearsGuardrailQaResult qa = RunArrearsGuardrailQa(DateTime.Today);

                    if (qa.Pass == false)
                    {
                        string subj = "LW Import Guardrail FAILED - Arrears Snapshot Validation";
                        clsUtilities.SendEmail(_EmailResults_TO, subj, qa.HtmlBody, _EmailResults_CC, _EmailResults_CC2, _EmailResults_CC3);
                    }
                }
            }
            catch (Exception exQa)
            {
                // We do not want this QA to interfere with the import pipeline.
                // If it errors out, log it and move on.
                //clsUtilities.AppendToTextFile("\r\n[Arrears Guardrail QA ERROR] " + DateTime.Now.ToString() + "\r\n" + exQa.ToString(), logFilename);
            }

            // ---------------------------------------------------------------------------------
            // ARREARS TRACKER GUARDRAIL QA
            //
            // Purpose:
            //   Catch "quiet" issues where imports technically succeed, but the data coverage becomes
            //   incomplete (missing day(s), missing month-end, etc.). This helps avoid bad arrears
            //   reports going out later.
            //
            // Behavior:
            //   - Runs only when the import is fully successful (no errors, no file-count mismatch)
            //   - Runs only on a small schedule (1st/15th) to keep the nightly job fast and quiet
            //   - Sends an email ONLY if the guardrail fails
            // ---------------------------------------------------------------------------------
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

        // -----------------------------------------------------------------------------
        // Arrears Tracker Guardrail QA
        // -----------------------------------------------------------------------------
        private class ArrearsGuardrailQaResult
        {
            public bool Pass { get; set; }
            public string HtmlBody { get; set; }
        }

        private static bool ShouldRunArrearsGuardrailQa(DateTime today)
        {
            // Keep it quiet/cheap: run only on a small schedule.
            //  - Day 1: catches month-end issues early
            //  - Day 15: mid-month sanity check
            int d = today.Day;
            return (d == 1 || d == 15);
        }

        private static ArrearsGuardrailQaResult RunArrearsGuardrailQa(DateTime runDate)
        {
            var result = new ArrearsGuardrailQaResult { Pass = true, HtmlBody = "" };

            // Validate both:
            //  1) Daily behavior (requested date resolves to latest <= requested)
            //  2) Coverage for the last 3 *closed* month-ends (must exist as true month-ends)
            DateTime monthEnd1 = new DateTime(runDate.Year, runDate.Month, 1).AddDays(-1);            // prior month end
            DateTime monthEnd2 = new DateTime(monthEnd1.Year, monthEnd1.Month, 1).AddDays(-1);
            DateTime monthEnd3 = new DateTime(monthEnd2.Year, monthEnd2.Month, 1).AddDays(-1);

            var checks = new List<DateTime>
            {
                runDate.Date,
                monthEnd1,
                monthEnd2,
                monthEnd3
            };

            var rowsForEmail = new List<Dictionary<string, object>>();
            bool anyFail = false;
            var failNotes = new List<string>();

            using (SqlConnection conn = clsDataHelper.sqlconn(true))
            {
                if (conn.State != ConnectionState.Open) conn.Open();

                foreach (DateTime requested in checks)
                {
                    DataRow r = ExecArrearsQaRow(conn, requested);

                    if (r == null)
                    {
                        anyFail = true;
                        failNotes.Add($"No result returned from dbo.spQA_ArrearsTracker_DateResolution for RequestedAsOfDate={requested:yyyy-MM-dd}.");
                        continue;
                    }

                    bool pass = clsFunc.CastToBool(r["Pass"]);
                    string reason = clsFunc.CastToStr(r["FailReason"]);

                    // Extra strict rules for the month-end guardrail:
                    // the resolved AR snapshot + tenant snapshot must land on the requested month-end.
                    if (requested == monthEnd1 || requested == monthEnd2 || requested == monthEnd3)
                    {
                        DateTime requestedMonthEnd = clsFunc.CastToDateTime(r["RequestedMonthEnd"], DateTime.MinValue);
                        DateTime arResolved = clsFunc.CastToDateTime(r["ARAsOf_Resolved"], DateTime.MinValue);
                        DateTime tenantResolved = clsFunc.CastToDateTime(r["TenantSnapAsOf_Resolved"], DateTime.MinValue);

                        if (requestedMonthEnd != requested.Date)
                        {
                            pass = false;
                            reason = AppendReason(reason, $"RequestedMonthEnd is {requestedMonthEnd:yyyy-MM-dd} (expected {requested:yyyy-MM-dd})");
                        }

                        if (arResolved != requested.Date)
                        {
                            pass = false;
                            reason = AppendReason(reason, $"ARAsOf_Resolved is {arResolved:yyyy-MM-dd} (expected {requested:yyyy-MM-dd})");
                        }

                        if (tenantResolved != requested.Date)
                        {
                            pass = false;
                            reason = AppendReason(reason, $"TenantSnapAsOf_Resolved is {tenantResolved:yyyy-MM-dd} (expected {requested:yyyy-MM-dd})");
                        }

                        // True month-end check
                        if (requested.Date != new DateTime(requested.Year, requested.Month, DateTime.DaysInMonth(requested.Year, requested.Month)))
                        {
                            pass = false;
                            reason = AppendReason(reason, "Requested date is not a true month-end (date calculation issue)");
                        }
                    }

                    if (!pass)
                    {
                        anyFail = true;
                        failNotes.Add($"FAIL for RequestedAsOfDate={requested:yyyy-MM-dd}: {reason}");
                    }

                    rowsForEmail.Add(new Dictionary<string, object>
                    {
                        ["RequestedAsOfDate"] = requested.ToString("yyyy-MM-dd"),
                        ["LatestDaily"] = clsFunc.CastToStr(r["LatestDaily"]),
                        ["Cutoff90"] = clsFunc.CastToStr(r["Cutoff90"]),
                        ["ResolutionMode"] = clsFunc.CastToStr(r["ResolutionMode"]),
                        ["RequestedMonthEnd"] = clsFunc.CastToStr(r["RequestedMonthEnd"]),
                        ["ARAsOf_Resolved"] = clsFunc.CastToStr(r["ARAsOf_Resolved"]),
                        ["ARRows_ResolvedDate"] = clsFunc.CastToStr(r["ARRows_ResolvedDate"]),
                        ["TenantSnapAsOf_Resolved"] = clsFunc.CastToStr(r["TenantSnapAsOf_Resolved"]),
                        ["TenantSnapRows_ResolvedDate"] = clsFunc.CastToStr(r["TenantSnapRows_ResolvedDate"]),
                        ["Pass"] = pass ? "1" : "0",
                        ["FailReason"] = reason
                    });
                }
            }

            result.Pass = !anyFail;
            result.HtmlBody = BuildArrearsGuardrailEmailHtml(runDate, rowsForEmail, failNotes, REGEX_FILE_PATTERN);
            return result;
        }

        private static DataRow ExecArrearsQaRow(SqlConnection conn, DateTime requestedAsOfDate)
        {
            using (SqlCommand cmd = new SqlCommand("dbo.spQA_ArrearsTracker_DateResolution", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.Add(new SqlParameter("@RequestedAsOfDate", SqlDbType.Date) { Value = requestedAsOfDate.Date });

                var dt = new System.Data.DataTable();
                using (var da = new SqlDataAdapter(cmd))
                {
                    da.Fill(dt);
                }

                if (dt.Rows.Count < 1) return null;
                return dt.Rows[0];
            }
        }

        private static string BuildArrearsGuardrailEmailHtml(DateTime runDate, List<Dictionary<string, object>> rows, List<string> failNotes, string regexFileNamePattern)
        {
            var sb = new StringBuilder();

            sb.Append("<div style='font-family: Arial, Helvetica, sans-serif; font-size: 13px;'>");
            sb.Append("<h2 style='margin:0 0 10px 0;'>Arrears Tracker Guardrail Check</h2>");
            sb.Append($"<p style='margin:0 0 10px 0;'><strong>Run date:</strong> {runDate:yyyy-MM-dd}</p>");

            if (failNotes != null && failNotes.Count > 0)
            {
                sb.Append("<div style='padding:10px; border:1px solid #c00; background:#fff5f5; margin:0 0 10px 0;'>");
                sb.Append("<strong>Result:</strong> FAIL<br/>");
                sb.Append("<ul style='margin:8px 0 0 18px; padding:0;'>");
                foreach (string n in failNotes)
                    sb.Append("<li>" + System.Web.HttpUtility.HtmlEncode(n) + "</li>");
                sb.Append("</ul></div>");

                // What to do now (actionable remediation for non-technical recipients)
                if (rows != null && rows.Count > 0)
                {
                    var r0 = rows[0];
                    string resolutionMode = clsFunc.CastToStr(r0.ContainsKey("ResolutionMode") ? r0["ResolutionMode"] : "");
                    string requestedAsOf = clsFunc.CastToStr(r0.ContainsKey("RequestedAsOfDate") ? r0["RequestedAsOfDate"] : "");
                    string requestedMonthEnd = clsFunc.CastToStr(r0.ContainsKey("RequestedMonthEnd") ? r0["RequestedMonthEnd"] : "");
                    string arAsOf = clsFunc.CastToStr(r0.ContainsKey("ARAsOf_Resolved") ? r0["ARAsOf_Resolved"] : "");
                    string tenantSnapAsOf = clsFunc.CastToStr(r0.ContainsKey("TenantSnapAsOf_Resolved") ? r0["TenantSnapAsOf_Resolved"] : "");

                    sb.Append("<div style='padding:10px; border:1px solid #ddd; background:#fafafa; margin:0 0 10px 0;'>");
                    sb.Append("<strong>What to do now</strong><br/>");
                    sb.Append("<ol style='margin:8px 0 0 18px; padding:0;'>");

                    // 1) Re-run the right export(s)
                    sb.Append("<li><strong>Re-run the Yardi export email for the missing date(s).</strong>");
                    sb.Append("<div style='margin-top:4px; color:#333;'>");
                    sb.Append("This guardrail uses: <strong>Daily AR snapshot</strong> as of <strong>" + System.Web.HttpUtility.HtmlEncode(arAsOf) + "</strong> and <strong>Tenant month-end snapshot</strong> as of <strong>" + System.Web.HttpUtility.HtmlEncode(tenantSnapAsOf) + "</strong>.");
                    sb.Append("</div>");
                    sb.Append("<ul style='margin:8px 0 0 18px; padding:0;'>");

                    DateTime arResolvedDate = ResolveGuardrailDate(arAsOf, runDate);
                    DateTime tenantResolvedDate = ResolveGuardrailDate(tenantSnapAsOf, runDate);
                    int[] remediationFiles = new[] { 10, 6, 7, 8, 9 };

                    foreach (int fileNum in remediationFiles)
                    {
                        DateTime resolvedDate = (fileNum == 10) ? arResolvedDate : tenantResolvedDate;
                        string expectedFileName = BuildExpectedExportFileName(resolvedDate, fileNum);
                        sb.Append("<li>File #" + fileNum.ToString("00") + " — Expected filename: <strong>" + System.Web.HttpUtility.HtmlEncode(expectedFileName) + "</strong></li>");
                    }

                    sb.Append("</ul>");

                    // 2) Filename expectations
                    sb.Append("</li><li><strong>Make sure the attachment filenames match what the importer expects.</strong>");
                    sb.Append("<div style='margin-top:4px; color:#333;'>");
                    sb.Append("The current filename pattern is: <code>" + System.Web.HttpUtility.HtmlEncode(regexFileNamePattern ?? "") + "</code>");
                    sb.Append("</div>");
                    sb.Append("</li>");

                    // 3) Re-run imports + re-check
                    sb.Append("<li><strong>Re-run the nightly import process</strong> (or reprocess the export email), then re-run this QA check for the same requested date (<strong>" + System.Web.HttpUtility.HtmlEncode(requestedAsOf) + "</strong>).");
                    sb.Append("<div style='margin-top:4px; color:#666;'>");
                    sb.Append("If the requested date is older than 90 days, month-end is used (requested month-end: <strong>" + System.Web.HttpUtility.HtmlEncode(requestedMonthEnd) + "</strong>).");
                    sb.Append("</div>");
                    sb.Append("</li>");

                    sb.Append("</ol>");
                    sb.Append("</div>");
                }
            }
            else
            {
                sb.Append("<div style='padding:10px; border:1px solid #0a0; background:#f3fff3; margin:0 0 10px 0;'>");
                sb.Append("<strong>Result:</strong> PASS</div>");
            }

            // Table
            sb.Append("<table cellpadding='6' cellspacing='0' style='border-collapse:collapse; width:100%; border:1px solid #ddd;'>");
            sb.Append("<tr style='background:#f2f2f2;'>");
            string[] cols = new[]
            {
                "RequestedAsOfDate","LatestDaily","Cutoff90","ResolutionMode","RequestedMonthEnd",
                "ARAsOf_Resolved","ARRows_ResolvedDate","TenantSnapAsOf_Resolved","TenantSnapRows_ResolvedDate","Pass","FailReason"
            };
            foreach (string c in cols)
                sb.Append("<th align='left' style='border-bottom:1px solid #ddd;'>" + System.Web.HttpUtility.HtmlEncode(c) + "</th>");
            sb.Append("</tr>");

            foreach (var row in rows)
            {
                bool pass = string.Equals(clsFunc.CastToStr(row.ContainsKey("Pass") ? row["Pass"] : ""), "1", StringComparison.OrdinalIgnoreCase);
                sb.Append("<tr" + (pass ? "" : " style='background:#fff5f5;'") + ">");
                foreach (string c in cols)
                {
                    string val = "";
                    if (row.ContainsKey(c) && row[c] != null) val = row[c].ToString();
                    sb.Append("<td style='border-top:1px solid #eee; vertical-align:top;'>" + System.Web.HttpUtility.HtmlEncode(val) + "</td>");
                }
                sb.Append("</tr>");
            }
            sb.Append("</table>");

            sb.Append("<p style='margin:10px 0 0 0; color:#666;'>This email is sent only when the guardrail fails (unless you run it manually).</p>");
            sb.Append("</div>");

            return sb.ToString();
        }

        private static string AppendReason(string existing, string add)
        {
            existing = existing ?? "";
            if (string.IsNullOrWhiteSpace(existing)) return add;
            return existing + "; " + add;
        }

        private static DateTime ResolveGuardrailDate(string dateValue, DateTime fallbackDate)
        {
            DateTime resolved;
            if (DateTime.TryParse(dateValue, out resolved))
            {
                return resolved.Date;
            }

            return fallbackDate.Date;
        }

        private static string BuildExpectedExportFileName(DateTime asOfDate, int fileNumber)
        {
            return $"{asOfDate:yyyy-MM-dd}_LW_Portal_Export-File{fileNumber:00}_amc.xlsx";
        }
    }
}
