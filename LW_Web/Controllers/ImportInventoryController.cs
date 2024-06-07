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
    public class ImportInventoryController : BaseController
    {
        // GET: Import
        [HttpGet]
        public ActionResult ImportInventoryFiles(String filetype)
        {
            return View(new ImportInventoryModel());
        }

        [HttpPost]
        public ActionResult ImportInventoryFiles(ImportInventoryModel mdl)   // This will auto-bind the model to the payload
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

            try
            {
                if (mdl.UploadedFile.ContentLength > 0)
                {
                    string _FileName = Path.GetFileName(mdl.UploadedFile.FileName);
                    _path = Path.Combine(Server.MapPath("~/_FileUploads"), _FileName);
                    mdl.UploadedFile.SaveAs(_path);
                }

                if (mdl.SelectedFile == "YardiWO")
                {
                    clsYardiHelper y = new clsYardiHelper();
                    if (y.Import_YardiWO_InventoryFile(_path))
                    {
                        ViewBag.Message = clsWebFormHelper.SuccessBoxMsgHTML("Success! " + y.RowsProcessed.ToString() + " row(s) successfully processed.");
                    }
                    else { ViewBag.Message = clsWebFormHelper.ErrorBoxMsgHTML("Error! Error after processing " + y.RowsProcessed.ToString() + " row(s).</span>"); }

                    if (y.Error_Log != "")
                    {
                        mdl.Error_log = "<div style='color=Red'>" + y.Error_Log.Replace("\r\n", "<br>") + "</div>";
                    }
                }
                else if (mdl.SelectedFile == "YardiWOH")
                {
                    clsYardiHelper y = new clsYardiHelper();
                    if (y.Import_YardiWO_GeneralFile(_path))
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
                    if (y.Import_YardiPO_InventoryFile(_path))
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
        //    ImportInventoryModel model = new ImportInventoryModel();

        //    if (clsReportHelper.ProcessInventorySQL())
        //    {
        //        ViewBag.Message2 = "<div class=\"alert alert-success\"><strong>Success!</strong> All Scripts Run.</div>";
        //        model.Error_log = "";
        //    }
        //    else 
        //    {
        //        ViewBag.Message2 = "";
        //        model.Error_log = "<div class=\"alert alert-danger\"><strong>Error!</strong> Error running scripts. Not all script might have run.</div>";
        //    }

        //    return View("ImportInventoryFiles", model);
        //}

        [HttpPost]
        public ActionResult Counter(string fileType)
        {
            clsCounter C = clsUtilities.ReadCounter(fileType);
            return Json(C);
        }

    }
}