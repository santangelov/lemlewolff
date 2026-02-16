using LW_Data;
using System;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Text.RegularExpressions;

namespace LW_Web.Services
{
    public class FileStorageService
    {
        public string SanitizePathSegment(string value, string fallback)
        {
            var baseValue = string.IsNullOrWhiteSpace(value) ? fallback : value.Trim();
            foreach (var invalidChar in Path.GetInvalidFileNameChars())
            {
                baseValue = baseValue.Replace(invalidChar, '_');
            }

            baseValue = Regex.Replace(baseValue, "\\s+", " ").Trim();
            return string.IsNullOrWhiteSpace(baseValue) ? fallback : baseValue;
        }

        public StoredFileResult SavePdfAndLog(FileStoreRequest request)
        {
            EnsureDirectoryExists(Path.GetDirectoryName(request.AbsoluteFilePath));
            File.WriteAllBytes(request.AbsoluteFilePath, request.FileBytes);

            var fileInfo = new FileInfo(request.AbsoluteFilePath);
            var fileId = InsertFileStoreRecord(request, fileInfo.Length);

            return new StoredFileResult
            {
                FileId = fileId,
                AbsolutePath = request.AbsoluteFilePath,
                RelativePath = request.RelativeFilePath,
                FileName = Path.GetFileName(request.AbsoluteFilePath)
            };
        }

        public int InsertPrintHistoryRecord(string printType, int? buildingId, int unitCount, string createdByUser, string notes)
        {
            using (var connection = clsDataHelper.sqlconn(true))
            using (var command = new SqlCommand(@"
INSERT INTO dbo.tblPrintHistory
(
    PrintType,
    BuildingID,
    UnitID,
    TenantID,
    CombinedFileID,
    CreatedByUser,
    UnitCount,
    Notes
)
VALUES
(
    @PrintType,
    @BuildingID,
    NULL,
    NULL,
    NULL,
    @CreatedByUser,
    @UnitCount,
    @Notes
);
SELECT CAST(SCOPE_IDENTITY() AS INT);", connection))
            {
                command.Parameters.Add("@PrintType", SqlDbType.NVarChar, 100).Value = printType;
                command.Parameters.Add("@BuildingID", SqlDbType.Int).Value = (object)buildingId ?? DBNull.Value;
                command.Parameters.Add("@CreatedByUser", SqlDbType.NVarChar, 100).Value = createdByUser;
                command.Parameters.Add("@UnitCount", SqlDbType.Int).Value = unitCount;
                command.Parameters.Add("@Notes", SqlDbType.NVarChar, 500).Value = (object)notes ?? DBNull.Value;

                connection.Open();
                return Convert.ToInt32(command.ExecuteScalar());
            }
        }

        public void LinkCombinedFileToPrintHistory(int printHistoryId, int combinedFileId)
        {
            using (var connection = clsDataHelper.sqlconn(true))
            using (var command = new SqlCommand(@"
UPDATE dbo.tblPrintHistory
SET CombinedFileID = @CombinedFileID
WHERE PrintHistoryID = @PrintHistoryID;", connection))
            {
                command.Parameters.Add("@CombinedFileID", SqlDbType.Int).Value = combinedFileId;
                command.Parameters.Add("@PrintHistoryID", SqlDbType.Int).Value = printHistoryId;

                connection.Open();
                command.ExecuteNonQuery();
            }
        }

        private int InsertFileStoreRecord(FileStoreRequest request, long fileSize)
        {
            using (var connection = clsDataHelper.sqlconn(true))
            using (var command = new SqlCommand(@"
INSERT INTO dbo.tblFileStore
(
    FileCategory,
    RelatedTable,
    RelatedRecordID,
    BuildingID,
    UnitID,
    TenantID,
    FilePath,
    FileName,
    FileExtension,
    FileSizeBytes,
    CreatedByUser
)
VALUES
(
    @FileCategory,
    @RelatedTable,
    @RelatedRecordID,
    @BuildingID,
    @UnitID,
    @TenantID,
    @FilePath,
    @FileName,
    @FileExtension,
    @FileSizeBytes,
    @CreatedByUser
);
SELECT CAST(SCOPE_IDENTITY() AS INT);", connection))
            {
                command.Parameters.Add("@FileCategory", SqlDbType.NVarChar, 100).Value = request.FileCategory;
                command.Parameters.Add("@RelatedTable", SqlDbType.NVarChar, 100).Value = (object)request.RelatedTable ?? DBNull.Value;
                command.Parameters.Add("@RelatedRecordID", SqlDbType.Int).Value = (object)request.RelatedRecordId ?? DBNull.Value;
                command.Parameters.Add("@BuildingID", SqlDbType.Int).Value = (object)request.BuildingId ?? DBNull.Value;
                command.Parameters.Add("@UnitID", SqlDbType.Int).Value = (object)request.UnitId ?? DBNull.Value;
                command.Parameters.Add("@TenantID", SqlDbType.Int).Value = (object)request.TenantId ?? DBNull.Value;
                command.Parameters.Add("@FilePath", SqlDbType.NVarChar, 500).Value = request.RelativeFilePath;
                command.Parameters.Add("@FileName", SqlDbType.NVarChar, 255).Value = Path.GetFileName(request.AbsoluteFilePath);
                command.Parameters.Add("@FileExtension", SqlDbType.NVarChar, 20).Value = Path.GetExtension(request.AbsoluteFilePath);
                command.Parameters.Add("@FileSizeBytes", SqlDbType.BigInt).Value = fileSize;
                command.Parameters.Add("@CreatedByUser", SqlDbType.NVarChar, 100).Value = request.CreatedByUser;

                connection.Open();
                return Convert.ToInt32(command.ExecuteScalar());
            }
        }

        private static void EnsureDirectoryExists(string directoryPath)
        {
            if (string.IsNullOrWhiteSpace(directoryPath))
            {
                throw new InvalidOperationException("Directory path was empty while trying to save file.");
            }

            if (!Directory.Exists(directoryPath))
            {
                Directory.CreateDirectory(directoryPath);
            }
        }
    }

    public class FileStoreRequest
    {
        public string FileCategory { get; set; }
        public string RelatedTable { get; set; }
        public int? RelatedRecordId { get; set; }
        public int? BuildingId { get; set; }
        public int? UnitId { get; set; }
        public int? TenantId { get; set; }
        public string RelativeFilePath { get; set; }
        public string AbsoluteFilePath { get; set; }
        public byte[] FileBytes { get; set; }
        public string CreatedByUser { get; set; }
    }

    public class StoredFileResult
    {
        public int FileId { get; set; }
        public string AbsolutePath { get; set; }
        public string RelativePath { get; set; }
        public string FileName { get; set; }
    }
}
