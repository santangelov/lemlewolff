using System;
using System.Collections.Generic;
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
    public class ImportController : Controller
    {

        // GET: Import
        [HttpGet]
        public ActionResult ImportFile(String filetype)
        {
            return View(new ImportFilesModel());
        }

        [HttpPost]
        public ActionResult ImportFile(HttpPostedFileBase file)
        {
            Server.ScriptTimeout = 1200;
            string _path = "";

            // Read form Response 
            string FileType = Request["ImportFileList"];
            string worksheetName = Request["WorkSheetName"];
            bool   DelDataFirst = Convert.ToBoolean(Request["chkDelDataFirst"].ToString());

            // Populate the Model
            ImportFilesModel model = new ImportFilesModel(FileType);
            model.WorkSheetName = worksheetName;
            ViewBag.Message = "";

            clsUtilities.WriteToCounter(FileType, "Uploading Data...");

            if (file == null) 
            { 
                ViewBag.Message = clsWebFormHelper.ErrorBoxMsgHTML("No File chosen to upload.");
                return View(model);
            }

            try
            {
                if (file.ContentLength > 0)
                {
                    string _FileName = Path.GetFileName(file.FileName);
                    _path = Path.Combine(Server.MapPath("~/_FileUploads"), _FileName);
                    file.SaveAs(_path);
                }

                // Delete data first if checked
                if (DelDataFirst)
                {
                    clsDataHelper dh = new clsDataHelper();
                    dh.cmd.Parameters.AddWithValue("@FileType", FileType);
                    dh.ExecuteSPCMD("spImport_Delete", true);
                }

                // Import the files
                if (FileType == "Sortly")
                {
                    clsSortlyHelper s = new clsSortlyHelper();

                    // Get the list of WorkSheets
                    List<string> sheetNames = clsExcelHelper.GetWorksheetNames(_path);
                    string openSheetName = "";

                    if (sheetNames.Count == 1) openSheetName = sheetNames[0].ToString(); else openSheetName = model.WorkSheetName;

                    if (s.Import_Sortly_File(_path, openSheetName))
                    {
                        string msgStr = "Success! " + s.RowsProcessed.ToString() + " row(s) successfully processed. ";
                        if (!s.WarningMsg.IsEmpty()) msgStr += s.WarningMsg;

                        ViewBag.Message = clsWebFormHelper.SuccessBoxMsgHTML(msgStr);
                    }
                    else { ViewBag.Message = clsWebFormHelper.ErrorBoxMsgHTML("Error! Error after processing " + s.RowsProcessed.ToString() + " row(s).</span>"); }
                }
                else if (FileType == "ADP")
                {
                    clsADPHelper s = new clsADPHelper();

                    // Get the list of WorkSheets
                    List<string> sheetNames = clsExcelHelper.GetWorksheetNames(_path);
                    string openSheetName = "";

                    if (sheetNames.Count == 1) openSheetName = sheetNames[0].ToString(); else openSheetName = model.WorkSheetName;

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
                else if (FileType == "YardiWO")
                {
                    clsYardiHelper y = new clsYardiHelper();
                    if (y.Import_YardiWO_File(_path))
                    {
                        ViewBag.Message = clsWebFormHelper.SuccessBoxMsgHTML("Success! " + y.RowsProcessed.ToString() + " row(s) successfully processed.");
                    }
                    else { ViewBag.Message = clsWebFormHelper.ErrorBoxMsgHTML("Error! Error after processing " + y.RowsProcessed.ToString() + " row(s).</span>"); }

                    if (y.Error_Log != "")
                    {
                        model.Error_log = "<div style='color=Red'>" + y.Error_Log.Replace("\r\n", "<br>") + "</div>";
                    }
                }
                else if (FileType == "YardiPO")
                {
                    clsYardiHelper y = new clsYardiHelper();
                    if (y.Import_YardiPO_File(_path))
                    {
                        ViewBag.Message = clsWebFormHelper.SuccessBoxMsgHTML("Success! " + y.RowsProcessed.ToString() + " row(s) successfully processed.");
                    }
                    else { ViewBag.Message = clsWebFormHelper.ErrorBoxMsgHTML("Error! Error after processing " + y.RowsProcessed.ToString() + " row(s).</span>"); }

                    if (y.Error_Log != "")
                    {
                        model.Error_log = "<div style='color=Red'>" + y.Error_Log.Replace("\r\n", "<br>") + "</div>";
                    }
                }

            }
            catch (Exception e)
            {
                ViewBag.Message = clsWebFormHelper.ErrorBoxMsgHTML("File upload failed!! " + e.Message);
            }

            return View(model);
        }

        [HttpPost]
        public ActionResult RunAllSQL()
        {
            Server.ScriptTimeout = 1200;
            ImportFilesModel model = new ImportFilesModel();

            if (clsReportHelper.RunAllReportSQL())
            {
                ViewBag.Message2 = "<div class=\"alert alert-success\"><strong>Success!</strong> All Scripts Run.</div>";
                model.Error_log = "";
            }
            else 
            {
                ViewBag.Message2 = "";
                model.Error_log = "<div class=\"alert alert-danger\"><strong>Error!</strong> Error running scripts. Not all script might have run.</div>";
            }

            return View("ImportFile", model);
        }

        [HttpPost]
        public ActionResult Counter(string fileType)
        {
            clsCounter C = clsUtilities.ReadCounter(fileType);
            return Json(C);
        }

    }
}