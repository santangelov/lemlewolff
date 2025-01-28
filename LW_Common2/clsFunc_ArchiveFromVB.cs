

namespace LW_Common_Reference
{

    #region Assembly PixelMarsalaCore.Common, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null
    // C:\inetpub\wwwroot\Pixel Marsala Projects\PMCore_Common\obj\Release\PixelMarsalaCore.Common.dll
    // Decompiled with ICSharpCode.Decompiler 7.1.0.6543
    #endregion
    /*
        using System;
        using System.Diagnostics;
        using System.IO;
        using System.Runtime.CompilerServices;
        using System.Runtime.Serialization.Formatters.Binary;
        using System.Text.RegularExpressions;
        using System.Web;
        using Microsoft.VisualBasic;
        using Microsoft.VisualBasic.CompilerServices;

        namespace PixelMarsalaCore.Common
        {
            public sealed class Func
            {
                public string TFtoYN(bool TFValue)
                {
                    if (TFValue)
                    {
                        return "Yes";
                    }

                    return "No";
                }

                public static string GetWebsiteRoot_UNC()
                {
                    string text = HttpContext.Current.Server.MapPath("~");
                    checked
                    {
                        if (text.EndsWith("/"))
                        {
                            text = Strings.Left(text, Strings.Len(text) - 1);
                        }

                        if (text.EndsWith("\\"))
                        {
                            text = Strings.Left(text, Strings.Len(text) - 1);
                        }

                        return text;
                    }
                }

                public static string StripHTMLTags(string html)
                {
                    if (Operators.CompareString(html.Trim(), "", false) == 0)
                    {
                        return "";
                    }

                    return Regex.Replace(Regex.Replace(html, "<.*?>", " "), "\\s+", " ").Trim();
                }

                public static string GetIPAddressFromHeader()
                {
                    string result = "";
                    try
                    {
                        result = HttpContext.Current.Request.ServerVariables["HTTP_X_FORWARDED_FOR"] ?? "";
                        return result;
                    }
                    catch (Exception ex)
                    {
                        ProjectData.SetProjectError(ex);
                        Exception ex2 = ex;
                        ProjectData.ClearProjectError();
                        return result;
                    }
                }

                public static string TranslatedText(string EnglishText, string SpanishText = "")
                {
                    string text = Conversions.ToString(Interaction.IIf(HttpContext.Current.Request.CurrentExecutionFilePath.ToUpper().Contains("/SP/"), (object)SpanishText, (object)EnglishText));
                    if (Operators.CompareString(text, "", false) == 0)
                    {
                        text = EnglishText;
                    }

                    return text;
                }

                public static string ObfuscateWords(object StringToObfuscate, bool RevealFirstWord = true, string ObfuscationCharacter = "X")
                {
                    string text = CastToStr(RuntimeHelpers.GetObjectValue(StringToObfuscate)).Trim();
                    if (Operators.CompareString(text, "", false) == 0)
                    {
                        return "";
                    }

                    MatchCollection matchCollection = Regex.Matches(text, "[\\w]+");
                    int num = 0;
                    if (RevealFirstWord)
                    {
                        text = matchCollection[0].ToString();
                        num = 1;
                    }

                    checked
                    {
                        if (num < matchCollection.Count)
                        {
                            int num2 = num;
                            int num3 = matchCollection.Count - 1;
                            for (int i = num2; i <= num3; i++)
                            {
                                text = text + " " + Regex.Replace(matchCollection[i].ToString(), ".", ObfuscationCharacter);
                            }
                        }

                        return text;
                    }
                }

                public string ObjectToString(object O)
                {
                    MemoryStream memoryStream = new MemoryStream();
                    new BinaryFormatter().Serialize(memoryStream, RuntimeHelpers.GetObjectValue(O));
                    return Convert.ToBase64String(memoryStream.ToArray()) ?? "";
                }

                public object StringToObject(string str)
                {
                    MemoryStream serializationStream = new MemoryStream(Convert.FromBase64String(str));
                    return new BinaryFormatter().Deserialize(serializationStream);
                }

                public static string ObfuscateZipCode(object ZipCode, string ObfuscationCharacter = "X")
                {
                    string text = CastToStr(RuntimeHelpers.GetObjectValue(ZipCode)).Trim();
                    if (Operators.CompareString(text, "", false) > 0)
                    {
                        text = Regex.Replace(text, "[0-9]", ObfuscationCharacter);
                    }

                    return text;
                }

                public static string formatDelimitedStringForDisplay(object value, string Delimiter, string EOLDelimiter, string ReplacementDelimiter, string ReplacementEOL, bool TruncateLastDelimiter)
                {
                    string text = Conversions.ToString(Operators.ConcatenateObject(value, (object)""));
                    if (Operators.CompareString(text, "", false) == 0)
                    {
                        return "";
                    }

                    if (Operators.CompareString(Delimiter, "", false) > 0)
                    {
                        text = text.Replace(Delimiter, ReplacementDelimiter);
                    }

                    if (Operators.CompareString(EOLDelimiter, "", false) > 0)
                    {
                        text = text.Replace(EOLDelimiter, ReplacementEOL);
                    }

                    checked
                    {
                        if (TruncateLastDelimiter)
                        {
                            if (text.EndsWith(ReplacementEOL))
                            {
                                text = Strings.Left(text, Strings.Len(text) - Strings.Len(ReplacementEOL));
                            }

                            if (text.EndsWith(ReplacementDelimiter))
                            {
                                text = Strings.Left(text, Strings.Len(text) - Strings.Len(ReplacementDelimiter));
                            }
                        }

                        return text;
                    }
                }

                public static bool isAlphaNumeric(object theValue, bool allowNumbers, bool allowSpaces, bool allowPeriods, string allowOtherChars = "")
                {
                    string text = "a-zA-Z";
                    if (allowSpaces)
                    {
                        text += " ";
                    }

                    if (allowNumbers)
                    {
                        text += "0-9";
                    }

                    if (allowPeriods)
                    {
                        text += "/.";
                    }

                    return Regex.IsMatch(Conversions.ToString(Operators.ConcatenateObject(theValue, (object)"")), "^[" + text + allowOtherChars + "]+$");
                }

                public static bool IsAllNumericDigit(string input)
                {
                    return Regex.IsMatch(input, "^[0-9]+$");
                }

                public static string DateFriendlyDay(int theDay)
                {
                    string result = Conversions.ToString(theDay) + "th";
                    if (theDay < 10 || theDay > 20)
                    {
                        int num = theDay % 10;
                        if (num == 1)
                        {
                            result = theDay + "st";
                        }

                        if (num == 2)
                        {
                            result = theDay + "nd";
                        }

                        if (num == 3)
                        {
                            result = theDay + "rd";
                        }
                    }

                    return result;
                }

                public static bool CastToBool(object value, bool defaultValue = false)
                {
                    try
                    {
                        if (value == null)
                        {
                            return defaultValue;
                        }

                        if (value == DBNull.Value)
                        {
                            return defaultValue;
                        }

                        switch (Conversions.ToString(NewLateBinding.LateGet((object)null, typeof(Strings), "UCase", new object[1] { Operators.ConcatenateObject(value, (object)"") }, (string[])null, (Type[])null, (bool[])null)))
                        {
                            case "Y":
                            case "YES":
                            case "TRUE":
                            case "1":
                                return true;
                            case "N":
                            case "NO":
                            case "FALSE":
                            case "0":
                                return false;
                            default:
                                return Conversions.ToBoolean(value);
                        }
                    }
                    catch (Exception ex)
                    {
                        ProjectData.SetProjectError(ex);
                        Exception ex2 = ex;
                        bool result = defaultValue;
                        ProjectData.ClearProjectError();
                        return result;
                    }
                }

                public static DateTime CastToDate(object value, DateTime defaultValue)
                {
                    try
                    {
                        if (value == null)
                        {
                            return defaultValue;
                        }

                        if (value == DBNull.Value)
                        {
                            return defaultValue;
                        }

                        return Conversions.ToDate(value);
                    }
                    catch (Exception ex)
                    {
                        ProjectData.SetProjectError(ex);
                        Exception ex2 = ex;
                        ProjectData.ClearProjectError();
                        return defaultValue;
                    }
                }

                public static double CastToDouble(object value, double defaultValue)
                {
                    try
                    {
                        if (value == null)
                        {
                            return defaultValue;
                        }

                        if (value == DBNull.Value)
                        {
                            return defaultValue;
                        }

                        return Conversions.ToDouble(value);
                    }
                    catch (Exception ex)
                    {
                        ProjectData.SetProjectError(ex);
                        Exception ex2 = ex;
                        ProjectData.ClearProjectError();
                        return defaultValue;
                    }
                }

                public static int CastToInt(object value, int defaultValue)
                {
                    try
                    {
                        if (value == null)
                        {
                            return defaultValue;
                        }

                        if (value == DBNull.Value)
                        {
                            return defaultValue;
                        }

                        return Conversions.ToInteger(value);
                    }
                    catch (Exception ex)
                    {
                        ProjectData.SetProjectError(ex);
                        Exception ex2 = ex;
                        ProjectData.ClearProjectError();
                        return defaultValue;
                    }
                }

                public static decimal CastToDec(object value, decimal defaultValue)
                {
                    try
                    {
                        if (value == null)
                        {
                            return defaultValue;
                        }

                        if (value == DBNull.Value)
                        {
                            return defaultValue;
                        }

                        return Conversions.ToDecimal(value);
                    }
                    catch (Exception ex)
                    {
                        ProjectData.SetProjectError(ex);
                        Exception ex2 = ex;
                        ProjectData.ClearProjectError();
                        return defaultValue;
                    }
                }

                public static long CastToLong(object value, long defaultValue)
                {
                    try
                    {
                        if (value == null)
                        {
                            return defaultValue;
                        }

                        if (value == DBNull.Value)
                        {
                            return defaultValue;
                        }

                        long result = defaultValue;
                        if (!long.TryParse(CastToStr(RuntimeHelpers.GetObjectValue(value)), out result))
                        {
                            return defaultValue;
                        }

                        return result;
                    }
                    catch (Exception ex)
                    {
                        ProjectData.SetProjectError(ex);
                        Exception ex2 = ex;
                        ProjectData.ClearProjectError();
                        return defaultValue;
                    }
                }

                public static string CastToStr(object value, string defaultValue = "")
                {
                    try
                    {
                        if (value == null)
                        {
                            return defaultValue;
                        }

                        if (value == DBNull.Value)
                        {
                            return defaultValue;
                        }

                        return Conversions.ToString(value);
                    }
                    catch (Exception ex)
                    {
                        ProjectData.SetProjectError(ex);
                        Exception ex2 = ex;
                        ProjectData.ClearProjectError();
                        return defaultValue;
                    }
                }

                public static bool ContainsNonPrintableCharacter(string textToBeChecked)
                {
                    bool result = false;
                    if (!string.IsNullOrEmpty(textToBeChecked))
                    {
                        for (int i = 0; i < textToBeChecked.Length; i = checked(i + 1))
                        {
                            int num = Strings.Asc(textToBeChecked[i]);
                            if (num >= 0 && num <= 31)
                            {
                                return true;
                            }
                        }
                    }

                    return result;
                }

                public static string ConcatenateFullMailingAddress(string Name, string Company, string CoAttn, string Addr1, string Addr2, string City, string State, string Zip, string Country, bool ReturnAsHTML, bool Addr1and2OnSameLine, string Title = "")
                {
                    string text = "";
                    string text2 = "<br />";
                    bool flag = false;
                    Country = Country ?? "";
                    if ((Operators.CompareString(Country.Trim(), "", false) > 0) & (Operators.CompareString(Country.Trim().ToUpper(), "UNITED STATES", false) != 0) & (Operators.CompareString(Country.Trim().ToUpper(), "U.S.", false) != 0) & (Operators.CompareString(Country.Trim().ToUpper(), "US", false) != 0) & (Operators.CompareString(Country.Trim().ToUpper(), "USA", false) != 0))
                    {
                        flag = true;
                    }

                    if (!ReturnAsHTML)
                    {
                        text2 = "\r\n";
                    }

                    if (string.IsNullOrEmpty(Name))
                    {
                        Name = "";
                    }

                    if (string.IsNullOrEmpty(Company))
                    {
                        Company = "";
                    }

                    if (string.IsNullOrEmpty(CoAttn))
                    {
                        CoAttn = "";
                    }

                    if (string.IsNullOrEmpty(Addr1))
                    {
                        Addr1 = "";
                    }

                    if (string.IsNullOrEmpty(Addr2))
                    {
                        Addr2 = "";
                    }

                    if (string.IsNullOrEmpty(State))
                    {
                        State = "";
                    }

                    if (string.IsNullOrEmpty(Country))
                    {
                        Country = "";
                    }

                    if (string.IsNullOrEmpty(Zip))
                    {
                        Zip = "";
                    }

                    if (Operators.CompareString(Name, "", false) > 0)
                    {
                        text += Name.Trim();
                        if (Operators.CompareString(Title.Trim(), "", false) > 0)
                        {
                            text = text + ", " + Title;
                        }

                        text += text2;
                    }
                    else if (Operators.CompareString(Title.Trim(), "", false) > 0)
                    {
                        text = text + Title + text2;
                    }

                    if (Operators.CompareString(Company.Trim(), "", false) > 0)
                    {
                        text = text + Company.Trim() + text2;
                    }

                    if (Operators.CompareString(CoAttn.Trim(), "", false) > 0)
                    {
                        text = text + "c/o " + CoAttn.Trim() + text2;
                    }

                    if (Operators.CompareString(Addr1.Trim(), "", false) > 0)
                    {
                        text = Conversions.ToString(Operators.ConcatenateObject((object)text, Operators.ConcatenateObject((object)Addr1.Trim(), Interaction.IIf(Addr1and2OnSameLine, (object)" ", (object)text2))));
                    }

                    if (Operators.CompareString(Addr2.Trim(), "", false) > 0)
                    {
                        text = text + Addr2 + text2;
                    }

                    string text3 = ConcatenateCityStateZip(City, State, Zip);
                    if (Operators.CompareString(text3.Trim(), "", false) > 0)
                    {
                        text = text + text3 + text2;
                    }

                    if (flag)
                    {
                        text = text + Country.Trim() + text2;
                    }

                    if (text.Length > 0)
                    {
                        int num = text.LastIndexOf(text2);
                        try
                        {
                            if (num > 0)
                            {
                                text = text.Substring(0, num) + text.Substring(checked(num + text2.Length));
                            }
                        }
                        catch (Exception ex)
                        {
                            ProjectData.SetProjectError(ex);
                            Exception ex2 = ex;
                            ProjectData.ClearProjectError();
                        }
                    }

                    return text ?? "";
                }

                public static string ConcatenateCityStateZip(string City, string State, string Zip)
                {
                    if (string.IsNullOrEmpty(City))
                    {
                        City = "";
                    }

                    if (string.IsNullOrEmpty(State))
                    {
                        State = "";
                    }

                    if (string.IsNullOrEmpty(Zip))
                    {
                        Zip = "";
                    }

                    string text = City.Trim();
                    if (Operators.CompareString(State.Trim(), "", false) > 0)
                    {
                        if (Operators.CompareString(text, "", false) > 0)
                        {
                            text += ", ";
                        }

                        text += State;
                    }

                    if (Operators.CompareString(Zip.Trim(), "", false) > 0)
                    {
                        if (Operators.CompareString(text, "", false) > 0)
                        {
                            text += " ";
                        }

                        text += Zip;
                    }

                    return text.Trim();
                }

                public static bool ContainsPunctuation(string textToBeChecked)
                {
                    bool result = false;
                    if (!string.IsNullOrEmpty(textToBeChecked))
                    {
                        for (int i = 0; i < textToBeChecked.Length; i = checked(i + 1))
                        {
                            int num = Strings.Asc(textToBeChecked[i]);
                            if (!((num >= 48 && num <= 57) || (num >= 65 && num <= 90) || (num >= 97 && num <= 122) || num == 32))
                            {
                                return true;
                            }
                        }
                    }

                    return result;
                }

                public static string GetCallingMethodName()
                {
                    return new StackFrame(1, fNeedFileInfo: false).GetMethod().Name;
                }

                public static string FormatCurrency(object value, int ForceDecPlaces, bool includeCommas, bool returnZeroInsteadOfBlanks)
                {
                    string text = Conversions.ToString(Operators.ConcatenateObject(value, (object)""));
                    if (returnZeroInsteadOfBlanks & (Operators.CompareString(text, "", false) == 0))
                    {
                        text = "0";
                    }

                    if (!Versioned.IsNumeric((object)text))
                    {
                        return text;
                    }

                    try
                    {
                        string text2 = "";
                        string text3 = "0";
                        if (ForceDecPlaces > 0)
                        {
                            text2 = ".";
                            for (int i = 1; i <= ForceDecPlaces; i = checked(i + 1))
                            {
                                text2 += "0";
                            }
                        }

                        text3 = ((!includeCommas) ? "0" : "#,0");
                        text = Conversions.ToDecimal(text).ToString(text3 + text2);
                    }
                    catch (Exception ex)
                    {
                        ProjectData.SetProjectError(ex);
                        Exception ex2 = ex;
                        ProjectData.ClearProjectError();
                    }

                    return text;
                }

                public static string FormatDateForPersistingMMDDYYYY(object value)
                {
                    string text = Conversions.ToString(NewLateBinding.LateGet(Operators.ConcatenateObject(value, (object)""), (Type)null, "Trim", new object[0], (string[])null, (Type[])null, (bool[])null));
                    if (Operators.CompareString(text, "", false) == 0)
                    {
                        return "";
                    }

                    string returnReformattedDate = "";
                    if (!clsValidationHelper.isValidDateMMDDYYYY(text, Allow1DigitMonth: true, Allow1DigitDay: true, Allow2DigitYear: true, AllowBlank: false, ref returnReformattedDate))
                    {
                        return "";
                    }

                    return returnReformattedDate;
                }

                public static string FormatDateForDisplayMMDDYYYY(object value)
                {
                    string text = Conversions.ToString(NewLateBinding.LateGet(Operators.ConcatenateObject(value, (object)""), (Type)null, "Trim", new object[0], (string[])null, (Type[])null, (bool[])null));
                    if (Operators.CompareString(text, "", false) == 0)
                    {
                        return "";
                    }

                    string returnReformattedDate = "";
                    if (!clsValidationHelper.isValidDateMMDDYYYY(text, Allow1DigitMonth: true, Allow1DigitDay: true, Allow2DigitYear: true, AllowBlank: false, ref returnReformattedDate))
                    {
                        return "";
                    }

                    return returnReformattedDate;
                }

                public static string FormatDateForPersistingMMYYYY(object value, bool Return4DigitYear)
                {
                    string text = Conversions.ToString(NewLateBinding.LateGet(Operators.ConcatenateObject(value, (object)""), (Type)null, "Trim", new object[0], (string[])null, (Type[])null, (bool[])null));
                    if (Operators.CompareString(text, "", false) == 0)
                    {
                        return "";
                    }

                    string returnReformattedDate = "";
                    if (!clsValidationHelper.isValidDateMMYYYY(text, Allow1DigitMonth: true, Allow2DigitYear: true, AllowBlank: false, ref returnReformattedDate, Return2DigitYear: true))
                    {
                        return "";
                    }

                    return returnReformattedDate;
                }

                public static string FormatPhoneNumberCSVforDisplay(object CSVPhoneNumbers)
                {
                    string[] array = Strings.Split(CastToStr(RuntimeHelpers.GetObjectValue(CSVPhoneNumbers)).Replace(" ", ""), ",", -1, (CompareMethod)0);
                    string text = "";
                    checked
                    {
                        if (array.Length > 0)
                        {
                            int num = array.Length - 1;
                            for (int i = 0; i <= num; i++)
                            {
                                text = Conversions.ToString(Operators.ConcatenateObject((object)text, Operators.ConcatenateObject(Interaction.IIf(Operators.CompareString(text, "", false) > 0, (object)", ", (object)""), (object)FormatPhoneNumberForDisplay(array[i]))));
                            }
                        }

                        return text;
                    }
                }

                public static string FormatPhoneNumberCSVforPersisting(object CSVPhoneNumbers)
                {
                    string[] array = Strings.Split(CastToStr(RuntimeHelpers.GetObjectValue(CSVPhoneNumbers)).Replace(" ", ""), ",", -1, (CompareMethod)0);
                    string text = "";
                    checked
                    {
                        if (array.Length > 0)
                        {
                            int num = array.Length - 1;
                            for (int i = 0; i <= num; i++)
                            {
                                text = Conversions.ToString(Operators.ConcatenateObject((object)text, Operators.ConcatenateObject(Interaction.IIf(Operators.CompareString(text, "", false) > 0, (object)",", (object)""), (object)FormatPhoneNumberForPersisting(array[i]))));
                            }
                        }

                        return text;
                    }
                }

                public static string FormatDatesCSVforPersisting(object MMDDYYYYDateStrCSV)
                {
                    string[] array = Strings.Split(CastToStr(RuntimeHelpers.GetObjectValue(MMDDYYYYDateStrCSV)).Replace(" ", ""), ",", -1, (CompareMethod)0);
                    string text = "";
                    checked
                    {
                        if (array.Length > 0)
                        {
                            int num = array.Length - 1;
                            for (int i = 0; i <= num; i++)
                            {
                                text = Conversions.ToString(Operators.ConcatenateObject((object)text, Operators.ConcatenateObject(Interaction.IIf(Operators.CompareString(text, "", false) > 0, (object)",", (object)""), (object)FormatDateForPersistingMMDDYYYY(array[i]))));
                            }
                        }

                        return text;
                    }
                }

                public static string FormatPhoneNumberForPersisting(object value)
                {
                    string text = Conversions.ToString(Operators.ConcatenateObject(value, (object)""));
                    text = text.Trim();
                    if (Operators.CompareString(text, "", false) == 0)
                    {
                        return "";
                    }

                    string text2 = extractDigits(text);
                    bool flag = true;
                    if (((text2.Length == 11) & text2.StartsWith("1")) | ((text2.Length == 12) & text2.StartsWith("01")) | ((text2.Length == 12) & text2.StartsWith("+1")))
                    {
                        return Strings.Right(text2, 10);
                    }

                    if (text.Contains("+"))
                    {
                        flag = true;
                    }
                    else if (text2.Length == 10)
                    {
                        return text2;
                    }

                    checked
                    {
                        if (flag)
                        {
                            string text3 = "";
                            bool flag2 = false;
                            int num = Strings.Len(text) - 1;
                            for (int i = 0; i <= num; i++)
                            {
                                if (Regex.IsMatch(text.Substring(i, 1), "[0-9\\+]"))
                                {
                                    text3 += text.Substring(i, 1);
                                    flag2 = false;
                                    continue;
                                }

                                if (!flag2)
                                {
                                    text3 += " ";
                                }

                                flag2 = true;
                            }

                            return text3.Trim();
                        }

                        return text2;
                    }
                }

                public static string FormatPhoneNumberForDisplay(object value)
                {
                    string text = Conversions.ToString(Operators.ConcatenateObject(value, (object)""));
                    if (Operators.CompareString(text, "", false) == 0)
                    {
                        return "";
                    }

                    text = extractDigits(text) ?? "";
                    if (text.Length == 10)
                    {
                        return "(" + text.Substring(0, 3) + ") " + text.Substring(3, 3) + "-" + text.Substring(6, 4);
                    }

                    if (text.Length == 11)
                    {
                        return text.Substring(0, 1) + "-" + text.Substring(1, 3) + "-" + text.Substring(4, 3) + "-" + text.Substring(7, 4);
                    }

                    return value.ToString();
                }

                public static string FormatBooleanForPersistingYN(object boolValue, bool allowBlank, bool InSiteFormat = false)
                {
                    if (allowBlank && Operators.CompareString(CastToStr(RuntimeHelpers.GetObjectValue(boolValue)).Trim(), "", false) == 0)
                    {
                        return "";
                    }

                    if (InSiteFormat)
                    {
                        if (CastToBool(RuntimeHelpers.GetObjectValue(boolValue)))
                        {
                            return "1";
                        }

                        return "0";
                    }

                    if (CastToBool(RuntimeHelpers.GetObjectValue(boolValue)))
                    {
                        return "Y";
                    }

                    return "N";
                }

                public static string ToYesNo(object YesValue, object NoValue, string DefaultForNoAnswer = "")
                {
                    if (CastToBool(RuntimeHelpers.GetObjectValue(YesValue)))
                    {
                        return "Yes";
                    }

                    if (CastToBool(RuntimeHelpers.GetObjectValue(NoValue)))
                    {
                        return "No";
                    }

                    return DefaultForNoAnswer;
                }

                public static string ToYesNo(object BooleanValue)
                {
                    if (CastToBool(RuntimeHelpers.GetObjectValue(BooleanValue)))
                    {
                        return "Yes";
                    }

                    return "No";
                }

                public static string extractDigits(string value)
                {
                    if (Operators.CompareString(value ?? "", "", false) == 0)
                    {
                        return "";
                    }

                    string text = "";
                    checked
                    {
                        int num = Strings.Len(value) - 1;
                        for (int i = 0; i <= num; i++)
                        {
                            if (Regex.IsMatch(value.Substring(i, 1), "[0-9]"))
                            {
                                text += value.Substring(i, 1);
                            }
                        }

                        return text ?? "";
                    }
                }

                public static string extractAlphaNum(object value, bool ExtractAlpha = true, bool ExtractNumeric = true, string AllowChars = " ", string ReplaceWithChar = "")
                {
                    if (Operators.ConditionalCompareObjectEqual(Operators.ConcatenateObject(value, (object)""), (object)"", false))
                    {
                        return "";
                    }

                    string text = Conversions.ToString(Operators.ConcatenateObject(value, (object)""));
                    string text2 = "";
                    string text3 = Conversions.ToString(Interaction.IIf(ExtractNumeric, (object)"0-9", (object)""));
                    string text4 = Conversions.ToString(Interaction.IIf(ExtractAlpha, (object)"a-zA-Z", (object)""));
                    checked
                    {
                        int num = Strings.Len(RuntimeHelpers.GetObjectValue(value)) - 1;
                        for (int i = 0; i <= num; i++)
                        {
                            text2 = ((!Regex.IsMatch(text.Substring(i, 1), "[" + text3 + text4 + AllowChars + "]")) ? (text2 + ReplaceWithChar) : (text2 + text.Substring(i, 1)));
                        }

                        return text2 ?? "";
                    }
                }

                public static bool HttpTransmitFile(string absolutePath, string fileName)
                {
                    bool result = false;
                    try
                    {
                        if (absolutePath[checked(absolutePath.Length - 1)] != Path.DirectorySeparatorChar)
                        {
                            absolutePath += Conversions.ToString(Path.DirectorySeparatorChar);
                        }

                        if (File.Exists(absolutePath + fileName))
                        {
                            HttpContext.Current.Response.ContentType = "application/pdf";
                            HttpContext.Current.Response.AddHeader("content-disposition", "attachment; filename=" + fileName);
                            HttpContext.Current.Response.TransmitFile(absolutePath + fileName);
                            HttpContext.Current.Response.End();
                            result = true;
                            return result;
                        }

                        return result;
                    }
                    catch (Exception ex)
                    {
                        ProjectData.SetProjectError(ex);
                        Exception ex2 = ex;
                        ProjectData.ClearProjectError();
                        return result;
                    }
                }
            }
        }
    */

}
