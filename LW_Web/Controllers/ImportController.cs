using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Runtime.Remoting.Contexts;
using System.Web;
using System.Web.Mvc;
using LW_Common;
using LW_Web.Models;

namespace LW_Web.Controllers
{
    public class ImportController : Controller
    {
        private void FillForm(ref ImportFilesModel model)
        {
            model.ImportFileList.Add(new SelectListItem { Text = "ADP", Value = "ADP" });
            model.ImportFileList.Add(new SelectListItem { Text = "AMC Time", Value = "AMC" });
            model.ImportFileList.Add(new SelectListItem { Text = "Sortly", Value = "Sortly" });
            model.ImportFileList.Add(new SelectListItem { Text = "Yardi", Value = "Yardi" });
        }

        // GET: Import
        [HttpGet]
        public ActionResult ImportFile(String filetype)
        {
            ImportFilesModel model = new ImportFilesModel();
            FillForm(ref model);
            return View(model);
        }

        [HttpPost]
        public ActionResult ImportFile(HttpPostedFileBase file)
        {
            ImportFilesModel model = new ImportFilesModel();
            FillForm(ref model);
            string _path = "";
            Server.ScriptTimeout = 1200;

            string FileType = Request["ImportFileList"].ToString();

            clsUtilities.WriteToCounter(FileType, "Uploading Data...");
            ViewBag.Message = "";

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
                    if (s.Import_AMCTime_File(_path))
                    {
                        ViewBag.Message = clsWebFormHelper.SuccessBoxMsgHTML("Success! " + s.RowsProcessed.ToString() + " row(s) successfully processed.");
                    }
                    else { ViewBag.Message = clsWebFormHelper.ErrorBoxMsgHTML("Error! Error after processing " + s.RowsProcessed.ToString() + " row(s).</span>"); }
                }
            }
            catch (Exception e)
            {
                ViewBag.Message = clsWebFormHelper.ErrorBoxMsgHTML("File upload failed!! " + e);
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