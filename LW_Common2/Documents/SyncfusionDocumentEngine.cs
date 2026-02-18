using Syncfusion.DocIO;
using Syncfusion.DocIO.DLS;
using Syncfusion.Licensing;
using Syncfusion.Pdf;
using Syncfusion.Pdf.Parsing;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace LW_Common.Documents
{
    public class SyncfusionDocumentEngine
    {

        public static void RegisterLicense(string licenseKey)
        {
            if (!string.IsNullOrWhiteSpace(licenseKey))
            {
                SyncfusionLicenseProvider.RegisterLicense(licenseKey);
            }
        }

        public void EnsureTemplatesExist(string templateRootPath, IEnumerable<string> templateNames)
        {
            foreach (var templateName in templateNames)
            {
                var fullPath = Path.Combine(templateRootPath, templateName);
                if (!File.Exists(fullPath))
                {
                    throw new FileNotFoundException($"Template file is missing: {fullPath}", fullPath);
                }
            }
        }

        public byte[] BuildPdfFromDocxTemplate(string templatePath, IDictionary<string, string> tokens)
        {
            clsUtilities.WriteToCounter("RenewalDemo", "Syncfusion build start: " + templatePath);

            using (var documentStream = new FileStream(templatePath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
            using (var wordDocument = new WordDocument(documentStream, FormatType.Docx))
            {
                foreach (var token in tokens)
                {
                    wordDocument.Replace($"##{token.Key}##", token.Value ?? string.Empty, true, true);
                }

                using (var renderer = new Syncfusion.DocIORenderer.DocIORenderer())
                using (var pdfDocument = renderer.ConvertToPDF(wordDocument))
                using (var outputStream = new MemoryStream())
                {
                    pdfDocument.Save(outputStream);
                    var bytes = outputStream.ToArray();
                    clsUtilities.WriteToCounter("RenewalDemo", "Syncfusion build complete: " + bytes.Length + " bytes");
                    return bytes;
                }
            }
        }

        public byte[] MergePdfs(IEnumerable<byte[]> pdfs)
        {
            var pdfBytesList = pdfs?.ToList() ?? new List<byte[]>();
            clsUtilities.WriteToCounter("RenewalDemo", "Syncfusion merge start: " + pdfBytesList.Count + " docs");

            using (var finalDocument = new PdfDocument())
            {
                var sourceStreams = new List<MemoryStream>();
                var loadedDocuments = new List<PdfLoadedDocument>();

                try
                {
                    foreach (var pdfBytes in pdfBytesList)
                    {
                        var sourceStream = new MemoryStream(pdfBytes);
                        sourceStreams.Add(sourceStream);

                        var loadedDocument = new PdfLoadedDocument(sourceStream);
                        loadedDocuments.Add(loadedDocument);

                        clsUtilities.WriteToCounter("RenewalDemo", "Syncfusion merge loading PDF pages");
                        finalDocument.Append(loadedDocument);
                    }

                    using (var outputStream = new MemoryStream())
                    {
                        clsUtilities.WriteToCounter("RenewalDemo", "Syncfusion merge save start");
                        finalDocument.Save(outputStream);
                        var mergedBytes = outputStream.ToArray();
                        clsUtilities.WriteToCounter("RenewalDemo", "Syncfusion merge complete: " + mergedBytes.Length + " bytes");
                        return mergedBytes;
                    }
                }
                catch (Exception ex)
                {
                    clsUtilities.WriteToCounter("RenewalDemo", "Syncfusion merge error: " + ex.Message);
                    throw;
                }
                finally
                {
                    foreach (var loadedDocument in loadedDocuments)
                    {
                        loadedDocument.Close(true);
                    }

                    foreach (var sourceStream in sourceStreams)
                    {
                        sourceStream.Dispose();
                    }
                }
            }
        }
    }
}
