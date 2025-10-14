using LW_Common;
using LW_Data;
using LW_Security;
using LW_Web.Models;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Hosting;
using System.Web.Mvc;
using System.Web.WebPages;
using System.Net;

namespace LW_Web.Controllers
{
    public class ImportController : BaseController
    {

        private readonly string _EmailResults_TO = ConfigurationManager.AppSettings["EmailAddress_YardiImportConfirmationEmil"];
        private readonly string _EmailResults_CC = ConfigurationManager.AppSettings["EmailAddressCC1_YardiImportConfirmationEmil"];
        private readonly string _EmailResults_CC2 = ConfigurationManager.AppSettings["EmailAddressCC2_YardiImportConfirmationEmil"];
        private readonly string _EmailResults_CC3 = ConfigurationManager.AppSettings["EmailAddressCC3_YardiImportConfirmationEmil"];

        // Counting errors so we only send error reports on 3 failures in a row
        private static int errorCount = 0;

        /// <summary>
        /// API endpoint to trigger email import, process the latest email, and import all attachments.
        /// </summary>
        [HttpPost]
        public ActionResult ImportLatestEmailAttachments()
        {
            EmailImporter EI = new EmailImporter();
            try
            {
                // This function should connect to the IMAP server, find the latest email,
                // remove the attachments, and process them.
                bool result = EI.CheckEmailAndImport();

                if (result)
                {
                    errorCount = 0; // Reset error count on success
                    return Json(new { success = true, message = "Email import completed.", details = EI.success_msg });
                }
                else
                {
                    clsUtilities.WriteToCounter("EmailImport", "Email import failed: " + EI.err_msg);
                    return Json(new { success = false, message = "Email import failed: " + EI.err_msg });
                }
            }
            catch (Exception ex)
            {
                errorCount++;
                if (errorCount >= 3)
                {
                    // Send email notification on 3 consecutive failures
                    clsUtilities.SendEmail(_EmailResults_TO, "Error in ImportLatestEmailAttachments", "Error (3rd Failure in a row): " + ex.Message + "<br>Details: " + EI.err_msg, _EmailResults_CC, _EmailResults_CC2, _EmailResults_CC3);
                    errorCount = 0; // Reset after sending email
                }
                return Json(new { success = false, message = "Email import failed: " + ex.Message + "; " + EI.err_msg });
           }
        }


        [HttpPost]
        public async Task<ActionResult> ImportSortlyWithAPIAsync()
        {
            // API-specific logic
            var result = await ProcessSortlyImportAsync();
            return Json(new { success = result.success, message = result.message });  // Force the Labels of success and message
        }

        [HttpPost]
        public async Task<ActionResult> ImportSortlyWithViewAsync()
        {
            // Non-API-specific logic
            var result = await ProcessSortlyImportAsync();
            var mdl = new DashboardModel
            {
                ErrorMsg = result.success
                    ? clsWebFormHelper.SuccessBoxMsgHTML(result.message)
                    : clsWebFormHelper.ErrorBoxMsgHTML(result.message)
            };
            return View("Dashboard", mdl);
        }

        // POST: Sortly API Calls - Shared
        private async Task<(bool success, string message)> ProcessSortlyImportAsync()
        {
            clsSortlyHelper sortly = new clsSortlyHelper();

            // Manually create the list of root folder IDs
            var rootFolderIDs = new List<clsSortlyModels.SortlyFolder>
            {
                // Later have this be able to automatically find the folders for the current year and the previous year
                new clsSortlyModels.SortlyFolder { Name = "1-Inventory", Id = 34069965, ParentRootPath="" },
                new clsSortlyModels.SortlyFolder { Name = "4-Today's Work Orders", Id = 37330941, ParentRootPath="" }
            };

            var allItemsWithPaths = new List<clsSortlyModels.SortlyItem>();

            // READ EVERYTHING FROM SORTLY USING THE API 
            foreach (var rootFolderID in rootFolderIDs)
            {
                var itemsWithPaths = await sortly.GetAllItemsWithFullPathAsync(rootFolderID);
                allItemsWithPaths.AddRange(itemsWithPaths);
            }

            // Delete data first
            clsDataHelper dh = new clsDataHelper();
            dh.cmd.Parameters.AddWithValue("@FileType", "Sortly");
            dh.ExecuteSPCMD("spImport_Delete", true, true);

            // INSERT RESULTS INTO THE DB: tblImport_Sortly
            DateTime CreateDate = DateTime.Now;
            foreach (var item in allItemsWithPaths)
            {
                dh.cmd.Parameters.Clear();
                dh.cmd.Parameters.AddWithValue("@ItemName", item.Name);
                dh.cmd.Parameters.AddWithValue("@SortlyID", item.sid);
                dh.cmd.Parameters.AddWithValue("@Quantity", item.quantity ?? 0);
                dh.cmd.Parameters.AddWithValue("@unitPrice", item.price ?? 0);
                dh.cmd.Parameters.AddWithValue("@TotalValue", item.price * (item.quantity ?? 0));
                dh.cmd.Parameters.AddWithValue("@Notes", item.notes ?? "");
                // Split the FolderPath into an array of up to 5 strings
                string[] folderPathParts = item.FolderPath.Split(new string[] { "||" }, 5, StringSplitOptions.None);
                dh.cmd.Parameters.AddWithValue("@PrimaryFolder", folderPathParts[0].ToString().Trim());
                for (int i = 1; i < folderPathParts.Length; i++)
                {
                    dh.cmd.Parameters.AddWithValue("@SubFolderLevel" + i.ToString(), folderPathParts[i].ToString().Trim());
                }
                dh.cmd.Parameters.AddWithValue("@CreatedBy", clsSecurity.LoggedInUserFirstName());
                dh.cmd.Parameters.AddWithValue("@CreateDate", CreateDate);
                dh.cmd.Parameters.AddWithValue("@NoReturn", true);  // Force it to not return data for speed
                bool isSuccess = dh.ExecuteSPCMD("spSortlyWorkOrderUpdate", false);
            }

            // Run the after Stored Procedures to clean up fields
            clsDataHelper sp = new clsDataHelper();
            string WarningMsg = ""; 
            if (!sp.ExecuteSPCMD("spRptBuilder_WOReview_04_SortlyFixes", false)) WarningMsg += " || spRptBuilder_WOReview_04_SortlyFixes: " + sp.data_err_msg;

            if (WarningMsg != "")
            {
                return (false, "Warning: " + WarningMsg);
            }
            else
            {
                return (true, "Success! " + allItemsWithPaths.Count.ToString("#,###") + " row(s) successfully processed. (Sortly)");
                //mdl.ErrorMsg = clsWebFormHelper.SuccessBoxMsgHTML("Success! " + allItemsWithPaths.Count.ToString("#,###") + " row(s) successfully processed. (Sortly)");
            }
            
        }

        // GET: Import
        [HttpGet]
        public ActionResult ImportFile(String filetype)
        {
            if (!clsSecurity.isUserLoggedIn())
            {
                return View("Login", new LoginModel() { Error_log = "ERROR: Not logged in." });
            }

            if (clsSecurity.isUserAdmin()==false && clsSecurity.isSuperAdmin()==false)
            {
                return View("Dashboard", new DashboardModel() { ErrorMsg = clsWebFormHelper.ErrorBoxMsgHTML("ERROR: You do not have access to import data.") });
            }

            return View(new ImportFilesModel());
        }

        [HttpPost]
        public ActionResult ImportFile(ImportFilesModel mdl)   // This will auto-bind the model to the payload
        {
            Server.ScriptTimeout = 1200;
            string _path = "";
            ViewBag.Message = "";

            clsUtilities.WriteToCounter(mdl.SelectedFile, "Uploading Data...");

            if (mdl.UploadedFile == null)
            {
                ViewBag.Message = clsWebFormHelper.ErrorBoxMsgHTML("No File chosen to upload.");
                return View(mdl);
            }

            if (mdl.UploadedFile.ContentLength > 0)
            {
                string _FileName = Path.GetFileName(mdl.UploadedFile.FileName);
                _path = Path.Combine(HostingEnvironment.MapPath(ConfigurationManager.AppSettings["FileUploadFolder"]), _FileName);
                mdl.UploadedFile.SaveAs(_path);
            }

            // Delete data first
            clsDataHelper dh = new clsDataHelper();
            dh.cmd.Parameters.AddWithValue("@FileType", mdl.SelectedFile);
            dh.ExecuteSPCMD("spImport_Delete", true, true);

            try
            {
                // Import the files
                if (mdl.SelectedFile == "Sortly")
                {
                    clsSortlyHelper s = new clsSortlyHelper();

                    // Get the list of WorkSheets
                    List<string> sheetNames = clsExcelHelper.GetWorksheetNames(_path);
                    string openSheetName = sheetNames[0].ToString();
                    //if (sheetNames.Count == 1) openSheetName = sheetNames[0].ToString(); else openSheetName = mdl.WorkSheetName;

                    if (s.Import_Sortly_File(_path, openSheetName))
                    {
                        string msgStr = "Success! " + s.RowsProcessed.ToString() + " row(s) successfully processed. (Sortly)";
                        if (!s.WarningMsg.IsEmpty()) msgStr += s.WarningMsg;

                        ViewBag.Message = clsWebFormHelper.SuccessBoxMsgHTML(msgStr);
                    }
                    else { ViewBag.Message = clsWebFormHelper.ErrorBoxMsgHTML("Error! Error after processing " + s.RowsProcessed.ToString() + " row(s). " + s.WarningMsg + "</span>"); }
                }
                else if (mdl.SelectedFile == "ADP")
                {
                    clsADPHelper s = new clsADPHelper();

                    // Get the list of WorkSheets
                    List<string> sheetNames = clsExcelHelper.GetWorksheetNames(_path);
                    string openSheetName = sheetNames[0].ToString();

                    if (s.Import_ADP_File(_path, openSheetName, false, false))
                    {
                        ViewBag.Message = clsWebFormHelper.SuccessBoxMsgHTML("Success! " + s.RowsProcessed.ToString() + " row(s) successfully processed. [ADP TimeSheet File]");
                        if (s.error_message != "")
                        {
                            ViewBag.Message += clsWebFormHelper.ErrorBoxMsgHTML("With Errors:\n" + s.error_message);
                        }
                    }
                    else { ViewBag.Message = clsWebFormHelper.ErrorBoxMsgHTML("Error! Error after processing " + s.RowsProcessed.ToString() + " row(s). " + s.error_message); }
                }
                else if (mdl.SelectedFile == "ADPLOC")
                {
                    clsADPHelper s = new clsADPHelper();

                    // Get the list of WorkSheets
                    List<string> sheetNames = clsExcelHelper.GetWorksheetNames(_path);
                    string openSheetName = sheetNames[0].ToString();

                    if (s.Import_ADP_TimecardWorkedLocations_File(_path, openSheetName, false, false))
                    {
                        ViewBag.Message = clsWebFormHelper.SuccessBoxMsgHTML("Success! " + s.RowsProcessed.ToString() + " row(s) successfully processed. [ADP Location File]");
                        if (s.error_message != "")
                        {
                            ViewBag.Message += clsWebFormHelper.ErrorBoxMsgHTML("With Errors:\n" + s.error_message);
                        }
                    }
                    else { ViewBag.Message = clsWebFormHelper.ErrorBoxMsgHTML("Error! Error after processing " + s.RowsProcessed.ToString() + " row(s). " + s.error_message); }
                }
                else if (mdl.SelectedFile == "YardiWO")  // ySQL File #1
                {
                    clsYardiHelper y = new clsYardiHelper();
                    if (y.Import_YardiWO_File(_path))
                    {
                        ViewBag.Message = clsWebFormHelper.SuccessBoxMsgHTML("Success! " + y.RowsProcessed.ToString() + " row(s) successfully processed. [1 - Yardi Work Orders]");
                    }
                    else { ViewBag.Message = clsWebFormHelper.ErrorBoxMsgHTML("Error! Error after processing " + y.RowsProcessed.ToString() + " row(s).</span>"); }

                    if (y.Error_Log != "")
                    {
                        mdl.Error_log = "<div style='color=Red'>" + y.Error_Log.Replace("\r\n", "<br>") + "</div>";
                    }
                }
                else if (mdl.SelectedFile == "YardiPO")  // ySQL File #2
                {
                    clsYardiHelper y = new clsYardiHelper();
                    if (y.Import_YardiPO_File(_path))
                    {
                        ViewBag.Message = clsWebFormHelper.SuccessBoxMsgHTML("Success! " + y.RowsProcessed.ToString() + " row(s) successfully processed. [2 - Yardi POs]");
                    }
                    else { ViewBag.Message = clsWebFormHelper.ErrorBoxMsgHTML("Error! Error after processing " + y.RowsProcessed.ToString() + " row(s).</span>"); }

                    if (y.Error_Log != "")
                    {
                        mdl.Error_log = "<div style='color=Red'>" + y.Error_Log.Replace("\r\n", "<br>") + "</div>";
                    }
                }
                else if (mdl.SelectedFile == "YardiWO2")  // ySQL File #3
                {
                    clsYardiHelper y = new clsYardiHelper();
                    if (y.Import_YardiWO_InventoryFile(_path))
                    {
                        ViewBag.Message = clsWebFormHelper.SuccessBoxMsgHTML("Success! " + y.RowsProcessed.ToString() + " row(s) successfully processed. (3 - Yardi WO Inventory)");
                    }
                    else { ViewBag.Message = clsWebFormHelper.ErrorBoxMsgHTML("Error! Error after processing " + y.RowsProcessed.ToString() + " row(s).</span>"); }

                    if (y.Error_Log != "")
                    {
                        mdl.Error_log = "<div style='color=Red'>" + y.Error_Log.Replace("\r\n", "<br>") + "</div>";
                    }
                }
                else if (mdl.SelectedFile == "YardiPO2") // ySQL File #4
                {
                    clsYardiHelper y = new clsYardiHelper();
                    if (y.Import_YardiPO_InventoryFile(_path))
                    {
                        ViewBag.Message = clsWebFormHelper.SuccessBoxMsgHTML("Success! " + y.RowsProcessed.ToString() + " row(s) successfully processed. (4 - Yardi PO Inventory)");
                    }
                    else { ViewBag.Message = clsWebFormHelper.ErrorBoxMsgHTML("Error! Error after processing " + y.RowsProcessed.ToString() + " row(s).</span>"); }

                    if (y.Error_Log != "")
                    {
                        mdl.Error_log = "<div style='color=Red'>" + y.Error_Log.Replace("\r\n", "<br>") + "</div>";
                    }
                }
                else if (mdl.SelectedFile == "YardiWOH") // 5
                {
                    clsYardiHelper y = new clsYardiHelper();
                    if (y.Import_YardiWO_GeneralFile(_path))
                    {
                        ViewBag.Message = clsWebFormHelper.SuccessBoxMsgHTML("Success! " + y.RowsProcessed.ToString() + " row(s) successfully processed. (5 - Yardi WO General)");
                    }
                    else { ViewBag.Message = clsWebFormHelper.ErrorBoxMsgHTML("Error! Error after processing " + y.RowsProcessed.ToString() + " row(s).</span>"); }

                    if (y.Error_Log != "")
                    {
                        mdl.Error_log = "<div style='color=Red'>" + y.Error_Log.Replace("\r\n", "<br>") + "</div>";
                    }
                }
                else if (mdl.SelectedFile == "PC")
                {
                    clsGeneralImportHelper s = new clsGeneralImportHelper();

                    // Get the list of WorkSheets
                    List<string> sheetNames = clsExcelHelper.GetWorksheetNames(_path);
                    string openSheetName = sheetNames[0].ToString();
                    //if (sheetNames.Count == 1) openSheetName = sheetNames[0].ToString(); else openSheetName = mdl.WorkSheetName;

                    if (s.Import_PhysicalCounts_File(_path, openSheetName, clsSecurity.LoggedInUserFirstName()))
                    {
                        string msgStr = "Success! " + s.RowsProcessed.ToString() + " row(s) successfully processed. (Physical Inventory Counts)";
                        if (!s.WarningMsg.IsEmpty()) msgStr += s.WarningMsg;

                        ViewBag.Message = clsWebFormHelper.SuccessBoxMsgHTML(msgStr);
                    }
                    else { ViewBag.Message = clsWebFormHelper.ErrorBoxMsgHTML("Error! Error after processing " + s.RowsProcessed.ToString() + " row(s). " + s.WarningMsg + "</span>"); }
                }
                else if (mdl.SelectedFile == "YardiPAU") // 6
                {
                    clsYardiHelper y = new clsYardiHelper();
                    if (y.Import_YardiProperty_File(_path))
                    {
                        ViewBag.Message = clsWebFormHelper.SuccessBoxMsgHTML("Success! " + y.RowsProcessed.ToString() + " row(s) successfully processed. (6 - Property/Units Data)");
                    }
                    else { ViewBag.Message = clsWebFormHelper.ErrorBoxMsgHTML("Error! Error after processing " + y.RowsProcessed.ToString() + " row(s).</span>"); }

                    if (y.Error_Log != "")
                    {
                        mdl.Error_log = "<div style='color:Red';>" + y.Error_Log.Replace("\r\n", "<br>") + "</div>";
                    }
                }


            }
            catch (Exception e)
            {
                ViewBag.Message = clsWebFormHelper.ErrorBoxMsgHTML("File upload failed. " + e.Message);
            }

            return View(mdl);
        }

        [HttpPost]
        public ActionResult Counter(string fileType)
        {
            clsCounter C = clsUtilities.ReadCounter(fileType);
            return Json(C);
        }

        private bool DeleteTable(string TableFlag)
        {
            if (TableFlag.IsEmpty()) return false;

            clsDataHelper dh = new clsDataHelper();
            dh.cmd.Parameters.AddWithValue("@FileType", TableFlag);
            return dh.ExecuteSPCMD("spImport_Delete", true, true);
        }

    }
}