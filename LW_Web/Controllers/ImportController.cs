using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Runtime.Remoting.Contexts;
using System.Web;
using System.Web.Mvc;
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

                // Import the files

                if (FileType == "Sortly")
                {
                    clsSortlyHelper s = new clsSortlyHelper();
                    if (s.Import_Sortly_File(_path))
                    {
                        ViewBag.Message = clsWebFormHelper.SuccessBoxMsgHTML("Success! " + s.RowsProcessed.ToString() + " row(s) successfully processed.");
                    }
                    else { ViewBag.Message = clsWebFormHelper.ErrorBoxMsgHTML("Error! Error after processing " + s.RowsProcessed.ToString() + " row(s).</span>"); }
                }
                else if (FileType == "AMC")
                {
                    clsAMCTimeHelper s = new clsAMCTimeHelper();

                    // Get the list of WorkSheets
                    List<string> sheetNames = clsExcelHelper.GetWorksheetNames(_path);
                    string openSheetName = "";

                    if (sheetNames.Count == 1)
                    {
                        openSheetName = sheetNames[0].ToString();
                    }
                    else
                    {
                        openSheetName = model.WorkSheetName;
                    }

                    if (s.Import_AMCTime_File(_path, openSheetName))
                    {
                        ViewBag.Message = clsWebFormHelper.SuccessBoxMsgHTML("Success! " + s.RowsProcessed.ToString() + " row(s) successfully processed. ");
                        if (s.error_message != "")
                        {
                            ViewBag.Message += clsWebFormHelper.ErrorBoxMsgHTML("With Errors:\n" + s.error_message);
                        }
                    }
                    else { ViewBag.Message = clsWebFormHelper.ErrorBoxMsgHTML("Error! Error after processing " + s.RowsProcessed.ToString() + " row(s). " + s.error_message); }
                }
                else if (FileType == "Yardi")
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

            }
            catch (Exception e)
            {
                ViewBag.Message = clsWebFormHelper.ErrorBoxMsgHTML("File upload failed!! " + e.Message);
            }

            return View(model);
        }


        [HttpPost]
        public ActionResult Counter(string fileType)
        {
            clsCounter C = clsUtilities.ReadCounter(fileType);
            return Json(C);
        }

    }
}