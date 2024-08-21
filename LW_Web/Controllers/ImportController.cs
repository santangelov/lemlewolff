using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Net;
using System.Reflection;
using System.Runtime.Remoting.Contexts;
using System.Web;
using System.Web.Mvc;
using System.Web.WebPages;
using LW_Common;
using LW_Data;
using LW_Web.Models;

namespace LW_Web.Controllers
{
    public class ImportController : BaseController
    {
        // GET: Import
        [HttpGet]
        public ActionResult ImportFile(String filetype)
        {
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
                _path = Path.Combine(Server.MapPath("~/_FileUploads"), _FileName);
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
                    string openSheetName = "";

                    if (sheetNames.Count == 1) openSheetName = sheetNames[0].ToString(); else openSheetName = mdl.WorkSheetName;

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
                    string openSheetName = "";

                    if (sheetNames.Count == 1) openSheetName = sheetNames[0].ToString(); else openSheetName = mdl.WorkSheetName;

                    if (s.Import_ADP_File(_path, openSheetName))
                    {
                        ViewBag.Message = clsWebFormHelper.SuccessBoxMsgHTML("Success! " + s.RowsProcessed.ToString() + " row(s) successfully processed. ");
                        if (s.error_message != "")
                        {
                            ViewBag.Message += clsWebFormHelper.ErrorBoxMsgHTML("With Errors:\n" + s.error_message);
                        }
                    }
                    else { ViewBag.Message = clsWebFormHelper.ErrorBoxMsgHTML("Error! Error after processing " + s.RowsProcessed.ToString() + " row(s). " + s.error_message); }
                }
                else if (mdl.SelectedFile == "YardiWO")
                {
                    clsYardiHelper y = new clsYardiHelper();
                    if (y.Import_YardiWO_File(_path))
                    {
                        ViewBag.Message = clsWebFormHelper.SuccessBoxMsgHTML("Success! " + y.RowsProcessed.ToString() + " row(s) successfully processed.");
                    }
                    else { ViewBag.Message = clsWebFormHelper.ErrorBoxMsgHTML("Error! Error after processing " + y.RowsProcessed.ToString() + " row(s).</span>"); }

                    if (y.Error_Log != "")
                    {
                        mdl.Error_log = "<div style='color=Red'>" + y.Error_Log.Replace("\r\n", "<br>") + "</div>";
                    }
                }
                else if (mdl.SelectedFile == "YardiPO")
                {
                    clsYardiHelper y = new clsYardiHelper();
                    if (y.Import_YardiPO_File(_path))
                    {
                        ViewBag.Message = clsWebFormHelper.SuccessBoxMsgHTML("Success! " + y.RowsProcessed.ToString() + " row(s) successfully processed.");
                    }
                    else { ViewBag.Message = clsWebFormHelper.ErrorBoxMsgHTML("Error! Error after processing " + y.RowsProcessed.ToString() + " row(s).</span>"); }

                    if (y.Error_Log != "")
                    {
                        mdl.Error_log = "<div style='color=Red'>" + y.Error_Log.Replace("\r\n", "<br>") + "</div>";
                    }
                }

        }
            catch (Exception e)
            {
                ViewBag.Message = clsWebFormHelper.ErrorBoxMsgHTML("File upload failed!! " + e.Message);
            }

            return View(mdl);
        }

        //[HttpPost]
        //public ActionResult RunAllSQL()
        //{
        //    Server.ScriptTimeout = 1200;
        //    ImportFilesModel model = new ImportFilesModel();

        //    if (clsReportHelper.RunAllReportSQL())
        //    {
        //        ViewBag.Message2 = "<div class=\"alert alert-success\"><strong>Success!</strong> All Scripts Run.</div>";
        //        model.Error_log = "";
        //    }
        //    else 
        //    {
        //        ViewBag.Message2 = "";
        //        model.Error_log = "<div class=\"alert alert-danger\"><strong>Error!</strong> Error running scripts. Not all script might have run.</div>";
        //    }

        //    return View("ImportFile", model);
        //}

        [HttpPost]
        public ActionResult Counter(string fileType)
        {
            clsCounter C = clsUtilities.ReadCounter(fileType);
            return Json(C);
        }

        private bool DeleteTable(string TableFlag)
        {
                //            IF @FileType = 'Sortly'             DELETE FROM tblImport_Sortly
                //--ELSE IF @FileType = 'ADP'         DELETE FROM tblImport_ADP-- - We don't need to ever delete from this table now - do it manually if need be

                //    ELSE IF @FileType = 'YardiWO'       DELETE FROM tblImport_Yardi_WOList
                //    ELSE IF @FileType = 'YardiPO'       DELETE FROM tblImport_Yardi_POs
                //    --ELSE IF @FileType = 'master'      DELETE FROM tblMasterWOReview
                //    ELSE IF @FileType = 'InventoryWO'   DELETE FROM tblImport_Inv_Yardi_WOItems
                //    ELSE IF @FileType = 'InventoryPO'   DELETE FROM tblImport_Inv_Yardi_POItems
                //    ELSE IF @FileType = 'MasterInv'     DELETE FROM tblMasterInventoryReview where isSeedItem = 0
                //    --ELSE IF @FileType = 'MasterInv-All'   DELETE FROM tblMasterInventoryReview

            if (TableFlag.IsEmpty()) return false;

            clsDataHelper dh = new clsDataHelper();
            dh.cmd.Parameters.AddWithValue("@FileType", TableFlag);
            return dh.ExecuteSPCMD("spImport_Delete", true, true);
        }

    }
}