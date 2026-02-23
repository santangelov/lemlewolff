using Newtonsoft.Json;

namespace LW_Common.MyJsonHandler
{
    public static class MyJson
    {
        public static JsonSerializer CreateSerializer()
        {
            return new JsonSerializer
            {
                ReferenceLoopHandling = ReferenceLoopHandling.Ignore
            };
        }
    }
}
