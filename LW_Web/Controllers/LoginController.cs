﻿using LW_Common;
using LW_Security;
using LW_Web.Models;
using System.Web.Mvc;

namespace LW_Web.Controllers
{
    public class LoginController : Controller
    {
        // GET: Login
        public ActionResult Index()
        {
            return View();
        }

        [HttpPost]
        public ActionResult LoginUser(LoginModel mdl)   // This will auto-bind the model to the payload
        {
            ViewBag.Message = "";
            clsSecurity s = new clsSecurity();

            if (s.ValidateLogin(mdl.EmailAddress, mdl.Password, true))
            {
                DashboardModel m = new DashboardModel();
                return View("Dashboard", m);

                //return RedirectToAction("ImportFile", "Import");
            }
            else
            {
                mdl.Error_log = clsWebFormHelper.ErrorBoxMsgHTML("Invalid Login");
                return View("Login", mdl);
            }
        }

        [HttpGet]
        public ActionResult LogOutUser()
        {
            clsSecurity s = new clsSecurity();
            s.LogOutUser();

            //return RedirectToAction("Index", "Login");
            LoginModel mdl = new LoginModel { Error_log = clsWebFormHelper.SuccessBoxMsgHTML("User Logged Out") };
            return View("Login", mdl);

        }

    }
}