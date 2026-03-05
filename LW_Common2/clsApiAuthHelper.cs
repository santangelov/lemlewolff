using System;

namespace LW_Common
{
    public static class clsApiAuthHelper
    {
        public static bool IsBasicAuthorized(string authorizationHeader, string expectedAccountId, string expectedPassword)
        {
            if (string.IsNullOrWhiteSpace(authorizationHeader))
            {
                return false;
            }

            const string basicPrefix = "Basic ";
            if (!authorizationHeader.StartsWith(basicPrefix, StringComparison.OrdinalIgnoreCase))
            {
                return false;
            }

            var encodedCredentials = authorizationHeader.Substring(basicPrefix.Length).Trim();
            if (string.IsNullOrWhiteSpace(encodedCredentials))
            {
                return false;
            }

            string decodedCredentials;
            try
            {
                var credentialBytes = Convert.FromBase64String(encodedCredentials);
                decodedCredentials = System.Text.Encoding.UTF8.GetString(credentialBytes);
            }
            catch (FormatException)
            {
                decodedCredentials = encodedCredentials;
            }

            var parts = decodedCredentials.Split(new[] { ':' }, 2);
            if (parts.Length != 2 && encodedCredentials.Contains(":"))
            {
                parts = encodedCredentials.Split(new[] { ':' }, 2);
            }

            if (parts.Length != 2)
            {
                return false;
            }

            return !string.IsNullOrEmpty(parts[0])
                && !string.IsNullOrEmpty(parts[1])
                && string.Equals(parts[0], expectedAccountId)
                && string.Equals(parts[1], expectedPassword);
        }
    }
}
