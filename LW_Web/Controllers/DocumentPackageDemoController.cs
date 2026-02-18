using LW_Common;
using LW_Data;
using LW_Security;
using LW_Web.Services;
using LW_Web.ViewModels;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Web.Mvc;
using static LW_Web.Services.FileStorageService;

namespace LW_Web.Controllers
{
    public class DocumentPackageDemoController : BaseController
    {
        private const string IncludeCoverSheetCookieName = "RenewalDemo_IncludeCoverSheet";

        /// <summary>
        /// Template names - list in order of desired PDF output.
        /// These templates must exist in the configured template root folder for the demo to work.
        /// The SyncfusionDocumentService will throw a FileNotFoundException if any are missing.
        /// </summary>
        private static readonly string[] TemplateNames =
        {
            "RenewalDemo_CoverPage.docx",
            "RenewalDemo_LeaseAgreement.docx",
            "RenewalDemo_Addendum.docx"
        };

        private readonly LWDbContext _context;
        private readonly SyncfusionDocumentEngine _syncfusionDocumentEngine;
        private readonly FileStorageService _fileStorageService;

        public DocumentPackageDemoController()
        {
            _context = new LWDbContext();
            _syncfusionDocumentEngine = new SyncfusionDocumentEngine();
            _fileStorageService = new FileStorageService();
        }

        public ActionResult Index()
        {
            var model = BuildBaseModel();
            model.IncludeCoverSheet = ReadIncludeCoverSheetPreference();
            return View("Index", model);
        }

        [HttpGet]
        public JsonResult GetUnits(int buildingId)
        {
            var units = GetUnitsForBuilding(buildingId)
                .Select(u => new SelectListItem
                {
                    Value = u.UnitId.ToString(CultureInfo.InvariantCulture),
                    Text = string.IsNullOrWhiteSpace(u.TenantLastName)
                        ? $"{u.UnitNumber}"
                        : $"{u.UnitNumber} - {u.TenantLastName}, {u.TenantFirstName}"
                })
                .ToList();

            return Json(units, JsonRequestBehavior.AllowGet);
        }

        [HttpGet]
        public ActionResult StreamPrintedPackage(int printHistoryId)
        {
            try
            {
                if (!CanAccessPrintedPackages())
                {
                    clsUtilities.WriteToCounter("RenewalDemo", "Unauthorized package stream attempt by user: " + clsSecurity.LoggedInUserID());
                    return new HttpStatusCodeResult(403, "You do not have access to printed packages.");
                }

                var printFile = _fileStorageService.GetCombinedPrintFileRecord(printHistoryId, "RenewalDemo");
                if (printFile == null)
                {
                    clsUtilities.WriteToCounter("RenewalDemo", "No print history/file found for PrintHistoryID=" + printHistoryId);
                    return HttpNotFound();
                }

                var documentStoreAbsolute = MapConfiguredPath("DocumentStoreRoot", "_document-store/");
                var absolutePath = ResolveStoredFileAbsolutePath(documentStoreAbsolute, printFile.FilePath);

                if (!System.IO.File.Exists(absolutePath))
                {
                    clsUtilities.WriteToCounter("RenewalDemo", "Combined package file not found: " + absolutePath);
                    return HttpNotFound("Requested PDF could not be found.");
                }

                var safeFileName = _fileStorageService.SanitizePathSegment(printFile.FileName, "Lease-Renewal-Package.pdf");
                return File(absolutePath, "application/pdf", safeFileName);
            }
            catch (Exception ex)
            {
                clsUtilities.WriteToCounter("RenewalDemo", "Error streaming package for PrintHistoryID=" + printHistoryId + ": " + ex);
                return new HttpStatusCodeResult(500, "Unable to stream requested package.");
            }
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult GeneratePackage(DocumentPackageDemoViewModel model)
        {
            Server.ScriptTimeout = 1200;
            SaveIncludeCoverSheetPreference(model.IncludeCoverSheet);

            var outputModel = BuildBaseModel();
            outputModel.SelectedBuildingId = model.SelectedBuildingId;
            outputModel.SelectedUnitIds = model.SelectedUnitIds;
            outputModel.IncludeCoverSheet = model.IncludeCoverSheet;

            try
            {
                if (!model.SelectedBuildingId.HasValue || model.SelectedBuildingId.Value <= 0)
                {
                    outputModel.ErrorMessageHtml = "<div class=\"alert alert-danger\"><strong>*</strong> Select a building.</div>";
                    return View("Index", outputModel);
                }

                var selectedUnitIds = ParseUnitIds(model.SelectedUnitIds);
                if (!selectedUnitIds.Any())
                {
                    outputModel.ErrorMessageHtml = "<div class=\"alert alert-danger\"><strong>*</strong> Select one or more units.</div>";
                    return View("Index", outputModel);
                }

                var units = GetUnitPackageData(model.SelectedBuildingId.Value, selectedUnitIds);
                if (!units.Any())
                {
                    outputModel.ErrorMessageHtml = "<div class=\"alert alert-danger\"><strong>*</strong> No matching active units were found for the selected building.</div>";
                    return View("Index", outputModel);
                }

                var templateRootAbsolute = MapConfiguredPath("DocumentTemplateRoot", "_Templates/Lease-Renewal-Docs/");
                var documentStoreAbsolute = MapConfiguredPath("DocumentStoreRoot", "_document-store/");

                var selectedTemplates = GetSelectedTemplateNames(model.IncludeCoverSheet);
                _syncfusionDocumentEngine.EnsureTemplatesExist(templateRootAbsolute, selectedTemplates);

                var createdByUser = clsSecurity.LoggedInUserFullName();
                if (string.IsNullOrWhiteSpace(createdByUser))
                {
                    createdByUser = "SYSTEM";
                }

                var printHistoryId = _fileStorageService.InsertPrintHistoryRecord(
                    "RenewalDemo",
                    model.SelectedBuildingId,
                    units.Count,
                    createdByUser,
                    "Demo run. Filenames are generated with UTC timestamps to allow duplicate runs.");

                var perUnitPdfs = new List<byte[]>();
                var nowUtc = DateTime.UtcNow;
                foreach (var unit in units)
                {
                    var unitPdf = GenerateSingleUnitPdf(templateRootAbsolute, unit, model.IncludeCoverSheet);
                    perUnitPdfs.Add(unitPdf);

                    var buildingFolder = GetBuildingFolderName(unit.BuildingCode, unit.BuildingId);
                    var safeUnitNumber = _fileStorageService.SanitizePathSegment(unit.UnitNumber, "UNKNOWN_UNIT");
                    var safeLastName = _fileStorageService.SanitizePathSegment((unit.TenantLastName ?? "UNKNOWN").ToUpperInvariant(), "UNKNOWN");
                    var unitFileName = $"{nowUtc:yyyy-MM-dd-HHmmss}_{safeLastName}.pdf";
                    var relativePath = $"units/{buildingFolder}/{safeUnitNumber}/renewals/{unitFileName}";
                    var absolutePath = EnsureUniqueFilePath(Path.Combine(documentStoreAbsolute, relativePath.Replace('/', Path.DirectorySeparatorChar)));
                    var relativeSavePath = ToRelativeDocumentStorePath(documentStoreAbsolute, absolutePath);

                    _fileStorageService.SavePdfAndLog(new clsFileStoreRequest
                    {
                        FileCategory = "RenewalUnitPackage",
                        RelatedTable = "tblPropertyUnits",
                        RelatedRecordId = unit.UnitId,
                        BuildingId = unit.BuildingId,
                        UnitId = unit.UnitId,
                        TenantId = unit.TenantId,
                        RelativeFilePath = relativeSavePath,
                        AbsoluteFilePath = absolutePath,
                        FileBytes = unitPdf,
                        CreatedByUser = createdByUser
                    });
                }

                var combinedPdf = _syncfusionDocumentEngine.MergePdfs(perUnitPdfs);
                var unitCountToken = units.Count.ToString("000", CultureInfo.InvariantCulture);
                var combinedFileName = $"Lease-Renewal-Package_{nowUtc:yyyyMMddHHmmss}-{unitCountToken}-Units.pdf";
                var combinedAbsolutePath = EnsureUniqueFilePath(Path.Combine(documentStoreAbsolute, "renewal-printings", combinedFileName));
                var combinedRelativePath = ToRelativeDocumentStorePath(documentStoreAbsolute, combinedAbsolutePath);

                var combinedFile = _fileStorageService.SavePdfAndLog(new clsFileStoreRequest
                {
                    FileCategory = "RenewalCombined",
                    RelatedTable = "tblPrintHistory",
                    RelatedRecordId = printHistoryId,
                    BuildingId = model.SelectedBuildingId,
                    UnitId = null,
                    TenantId = null,
                    RelativeFilePath = combinedRelativePath,
                    AbsoluteFilePath = combinedAbsolutePath,
                    FileBytes = combinedPdf,
                    CreatedByUser = createdByUser
                });

                _fileStorageService.LinkCombinedFileToPrintHistory(printHistoryId, combinedFile.FileId);

                return RedirectToAction("Index");
            }
            catch (FileNotFoundException ex)
            {
                clsUtilities.WriteToCounter("RenewalDemo", "Template missing");
                outputModel.ErrorMessageHtml = $"<div class=\"alert alert-danger\"><strong>Template Missing:</strong> {ex.FileName}</div>";
                return View("Index", outputModel);
            }
            catch (Exception ex)
            {
                clsUtilities.WriteToCounter("RenewalDemo", "Error: " + ex.Message);
                outputModel.ErrorMessageHtml = $"<div class=\"alert alert-danger\"><strong>Error:</strong> {ex.Message}</div>";
                return View("Index", outputModel);
            }
        }

        private DocumentPackageDemoViewModel BuildBaseModel()
        {
            var model = new DocumentPackageDemoViewModel();
            model.Buildings = _context.tblProperties
                .Where(p => !p.isInactive && _context.tblPropertyUnits.Any(u => u.yardiPropertyRowID == p.yardiPropertyRowID && !u.isExcluded))
                .OrderBy(p => p.yardiPropertyRowID)
                .Select(p => new SelectListItem
                {
                    Value = p.yardiPropertyRowID.ToString(),
                    Text = p.buildingCode + " - " + (p.addr1_Co ?? "n/a").ToUpper()
                })
                .ToList();

            model.PrintHistory = _fileStorageService.GetRecentPrintHistory("RenewalDemo")
                .Select(r => new DocumentPackageHistoryItemViewModel
                {
                    PrintHistoryId = r.PrintHistoryId,
                    CreatedDate = r.CreatedDate,
                    CreatedByUser = r.CreatedByUser,
                    UnitCount = r.UnitCount,
                    FileName = r.FileName
                })
                .ToList();

            return model;
        }

        private static bool CanAccessPrintedPackages()
        {
            return clsSecurity.isSuperAdmin() || clsSecurity.isUserAdmin() || clsSecurity.isLegalTeam();
        }

        private List<DocumentPackageUnitData> GetUnitsForBuilding(int buildingId)
        {
            return _context.tblPropertyUnits
                .Where(u => u.yardiPropertyRowID == buildingId && !u.isExcluded)
                .OrderBy(u => u.AptNumber)
                .Select(u => new DocumentPackageUnitData
                {
                    UnitId = u.yardiUnitRowID,
                    BuildingId = u.yardiPropertyRowID,
                    UnitNumber = u.AptNumber,
                    TenantFirstName = null,
                    TenantLastName = null
                })
                .ToList();
        }

        private List<DocumentPackageUnitData> GetUnitPackageData(int buildingId, IReadOnlyCollection<int> selectedUnitIds)
        {
            var rows = new List<DocumentPackageUnitData>();
            var idParamNames = selectedUnitIds.Select((id, index) => $"@unitId{index}").ToList();

            var sql = clsUtilities.ExtractSqlFromXml($@"<sql>
SELECT
    p.yardiPropertyRowID AS BuildingID,
    p.buildingCode AS BuildingCode,
    p.addr1_Co AS PropertyAddress1,
    p.city AS PropertyCity,
    p.stateCode AS PropertyState,
    p.zipCode AS PropertyZip,
    u.yardiUnitRowID AS UnitID,
    u.AptNumber,
    u.Bedrooms,
    u.SqFt,
    u.rent,
    u.LeaseStartDate,
    u.LeaseEndDate,
    TRY_CAST(u.CurrentTenantYardiID AS INT) AS TenantID,
    t.firstName AS TenantFirstName,
    t.lastName AS TenantLastName
FROM dbo.tblPropertyUnits u
INNER JOIN dbo.tblProperties p
    ON p.yardiPropertyRowID = u.yardiPropertyRowID
LEFT JOIN dbo.tblTenants t
    ON t.yardiPersonRowID = TRY_CAST(u.CurrentTenantYardiID AS INT)
WHERE p.isInactive = 0
  AND u.isExcluded = 0
  AND u.yardiPropertyRowID = @buildingId
  AND u.yardiUnitRowID IN ({string.Join(",", idParamNames)})
ORDER BY p.yardiPropertyRowID ASC, u.AptNumber ASC;
</sql>");

            using (var connection = clsDataHelper.sqlconn(false))
            using (var command = new SqlCommand(sql, connection))
            {
                command.Parameters.AddWithValue("@buildingId", buildingId);
                var index = 0;
                foreach (var unitId in selectedUnitIds)
                {
                    command.Parameters.AddWithValue($"@unitId{index}", unitId);
                    index++;
                }

                connection.Open();
                using (var reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        rows.Add(new DocumentPackageUnitData
                        {
                            BuildingId = reader.GetInt32(reader.GetOrdinal("BuildingID")),
                            BuildingCode = reader["BuildingCode"]?.ToString(),
                            PropertyAddress1 = reader["PropertyAddress1"]?.ToString(),
                            PropertyCity = reader["PropertyCity"]?.ToString(),
                            PropertyState = reader["PropertyState"]?.ToString(),
                            PropertyZip = reader["PropertyZip"]?.ToString(),
                            UnitId = reader.GetInt32(reader.GetOrdinal("UnitID")),
                            UnitNumber = reader["AptNumber"]?.ToString(),
                            Bedrooms = reader["Bedrooms"] == DBNull.Value ? (int?)null : Convert.ToInt32(reader["Bedrooms"]),
                            SqFt = reader["SqFt"] == DBNull.Value ? (decimal?)null : Convert.ToDecimal(reader["SqFt"]),
                            Rent = reader["rent"] == DBNull.Value ? (decimal?)null : Convert.ToDecimal(reader["rent"]),
                            LeaseStartDate = reader["LeaseStartDate"] == DBNull.Value ? (DateTime?)null : Convert.ToDateTime(reader["LeaseStartDate"]),
                            LeaseEndDate = reader["LeaseEndDate"] == DBNull.Value ? (DateTime?)null : Convert.ToDateTime(reader["LeaseEndDate"]),
                            TenantId = reader["TenantID"] == DBNull.Value ? (int?)null : Convert.ToInt32(reader["TenantID"]),
                            TenantFirstName = reader["TenantFirstName"]?.ToString(),
                            TenantLastName = reader["TenantLastName"]?.ToString()
                        });
                    }
                }
            }

            return rows;
        }

        private byte[] GenerateSingleUnitPdf(string templateRootAbsolute, DocumentPackageUnitData unit, bool includeCoverSheet)
        {
            var templatePdfs = new List<byte[]>();
            var tokenMap = BuildTokenMap(unit);
            var templateNames = GetSelectedTemplateNames(includeCoverSheet);

            foreach (var templateName in templateNames)
            {
                var templatePath = Path.Combine(templateRootAbsolute, templateName);
                var pdf = _syncfusionDocumentEngine.BuildPdfFromDocxTemplate(templatePath, tokenMap);
                templatePdfs.Add(pdf);
            }

            return _syncfusionDocumentEngine.MergePdfs(templatePdfs);
        }

        private static string[] GetSelectedTemplateNames(bool includeCoverSheet)
        {
            if (includeCoverSheet)
            {
                return TemplateNames;
            }

            return TemplateNames.Where(t => !t.Equals("RenewalDemo_CoverPage.docx", StringComparison.OrdinalIgnoreCase)).ToArray();
        }

        private string GetBuildingFolderName(string buildingCode, int buildingId)
        {
            var sourceCode = string.IsNullOrWhiteSpace(buildingCode)
                ? buildingId.ToString(CultureInfo.InvariantCulture)
                : buildingCode.Trim();

            if (int.TryParse(sourceCode, NumberStyles.Integer, CultureInfo.InvariantCulture, out var numericCode))
            {
                return numericCode.ToString("0000", CultureInfo.InvariantCulture);
            }

            return _fileStorageService.SanitizePathSegment(sourceCode, buildingId.ToString(CultureInfo.InvariantCulture));
        }

        private static string EnsureUniqueFilePath(string proposedAbsolutePath)
        {
            if (!System.IO.File.Exists(proposedAbsolutePath))
            {
                return proposedAbsolutePath;
            }

            var directory = Path.GetDirectoryName(proposedAbsolutePath);
            var baseName = Path.GetFileNameWithoutExtension(proposedAbsolutePath);
            var extension = Path.GetExtension(proposedAbsolutePath);

            for (var i = 1; i <= 99; i++)
            {
                var candidatePath = Path.Combine(directory ?? string.Empty, $"{baseName}-{i:00}{extension}");
                if (!System.IO.File.Exists(candidatePath))
                {
                    return candidatePath;
                }
            }

            throw new IOException("Unable to determine a unique filename after 99 attempts: " + proposedAbsolutePath);
        }

        private static string ToRelativeDocumentStorePath(string documentStoreAbsolute, string absolutePath)
        {
            var relativePath = absolutePath.Substring(documentStoreAbsolute.TrimEnd(Path.DirectorySeparatorChar).Length)
                .TrimStart(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar)
                .Replace(Path.DirectorySeparatorChar, '/');

            return "/" + relativePath;
        }

        private static Dictionary<string, string> BuildTokenMap(DocumentPackageUnitData unit)
        {
            var cityStateZip = string.Join(" ", new[]
            {
                unit.PropertyCity,
                unit.PropertyState,
                unit.PropertyZip
            }.Where(s => !string.IsNullOrWhiteSpace(s))).Trim();

            return new Dictionary<string, string>
            {
                ["TenantFirstName"] = unit.TenantFirstName ?? string.Empty,
                ["TenantLastName"] = unit.TenantLastName ?? string.Empty,
                ["BuildingCode"] = unit.BuildingCode ?? string.Empty,
                ["AptNumber"] = unit.UnitNumber ?? string.Empty,
                ["PropertyAddress1"] = unit.PropertyAddress1 ?? string.Empty,
                ["PropertyCityStateZip"] = cityStateZip,
                ["Rent"] = unit.Rent.HasValue ? unit.Rent.Value.ToString("0.00") : string.Empty,
                ["LeaseStartDate"] = unit.LeaseStartDate.HasValue ? unit.LeaseStartDate.Value.ToString("MM/dd/yyyy") : string.Empty,
                ["LeaseEndDate"] = unit.LeaseEndDate.HasValue ? unit.LeaseEndDate.Value.ToString("MM/dd/yyyy") : string.Empty,
                ["Bedrooms"] = unit.Bedrooms.HasValue ? unit.Bedrooms.Value.ToString(CultureInfo.InvariantCulture) : string.Empty,
                ["SqFt"] = unit.SqFt.HasValue ? unit.SqFt.Value.ToString("0") : string.Empty
            };
        }

        private static string ResolveStoredFileAbsolutePath(string documentStoreAbsolute, string relativeFilePath)
        {
            var basePath = Path.GetFullPath(documentStoreAbsolute);
            var relativePath = (relativeFilePath ?? string.Empty).TrimStart('~', '/', '\\').Replace('/', Path.DirectorySeparatorChar);
            var combinedPath = Path.GetFullPath(Path.Combine(basePath, relativePath));

            if (!combinedPath.StartsWith(basePath, StringComparison.OrdinalIgnoreCase))
            {
                throw new InvalidOperationException("Invalid file path requested.");
            }

            return combinedPath;
        }

        private string MapConfiguredPath(string appSettingKey, string fallbackRelative)
        {
            var configuredValue = ConfigurationManager.AppSettings[appSettingKey];
            var normalized = string.IsNullOrWhiteSpace(configuredValue) ? fallbackRelative : configuredValue;
            if (Path.IsPathRooted(normalized))
            {
                return normalized;
            }

            return Server.MapPath("~/" + normalized.TrimStart('~', '/').Replace("\\", "/"));
        }

        private static List<int> ParseUnitIds(string selectedUnitIds)
        {
            if (string.IsNullOrWhiteSpace(selectedUnitIds))
            {
                return new List<int>();
            }

            return selectedUnitIds
                .Split(',')
                .Select(s => s.Trim())
                .Where(s => !string.IsNullOrWhiteSpace(s) && int.TryParse(s, out _))
                .Select(int.Parse)
                .Distinct()
                .ToList();
        }

        private bool ReadIncludeCoverSheetPreference()
        {
            var includeCoverCookie = Request?.Cookies[IncludeCoverSheetCookieName]?.Value;
            if (bool.TryParse(includeCoverCookie, out var includeCoverSheet))
            {
                return includeCoverSheet;
            }

            return true;
        }

        private void SaveIncludeCoverSheetPreference(bool includeCoverSheet)
        {
            var cookie = new System.Web.HttpCookie(IncludeCoverSheetCookieName, includeCoverSheet.ToString())
            {
                Expires = DateTime.UtcNow.AddYears(1),
                HttpOnly = false,
                Secure = Request?.IsSecureConnection ?? false,
                SameSite = SameSiteMode.Lax
            };

            Response.Cookies.Set(cookie);
        }
    }

    public class DocumentPackageUnitData
    {
        public int BuildingId { get; set; }
        public string BuildingCode { get; set; }
        public string PropertyAddress1 { get; set; }
        public string PropertyCity { get; set; }
        public string PropertyState { get; set; }
        public string PropertyZip { get; set; }
        public int UnitId { get; set; }
        public string UnitNumber { get; set; }
        public int? TenantId { get; set; }
        public string TenantFirstName { get; set; }
        public string TenantLastName { get; set; }
        public decimal? Rent { get; set; }
        public DateTime? LeaseStartDate { get; set; }
        public DateTime? LeaseEndDate { get; set; }
        public int? Bedrooms { get; set; }
        public decimal? SqFt { get; set; }
    }
}
