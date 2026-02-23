using System;
using System.Text;
using System.Web.Mvc;
using LW_Common.MyJsonHandler;
using Newtonsoft.Json;

namespace LW_Web.ActionResults
{
    public sealed class MyJsonResult : ActionResult
    {
        public object Data { get; set; }

        public string ContentType { get; set; } = "application/json";

        public Encoding ContentEncoding { get; set; } = Encoding.UTF8;

        public override void ExecuteResult(ControllerContext controllerContext)
        {
            if (controllerContext == null)
            {
                throw new ArgumentNullException("controllerContext");
            }

            var response = controllerContext.HttpContext.Response;
            response.ContentType = ContentType;
            response.ContentEncoding = ContentEncoding;

            using (var writer = new JsonTextWriter(response.Output) { CloseOutput = false })
            {
                var serializer = MyJson.CreateSerializer();
                serializer.Serialize(writer, Data);
                writer.Flush();
            }
        }
    }
}
