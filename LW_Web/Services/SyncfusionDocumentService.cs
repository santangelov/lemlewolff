using Syncfusion.DocIO;
using Syncfusion.DocIO.DLS;
using Syncfusion.DocIORenderer;
using Syncfusion.Pdf;
using Syncfusion.Pdf.Parsing;
using System;
using System.Collections.Generic;
using System.IO;

namespace LW_Web.Services
{
    public class SyncfusionDocumentService
    {
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

        public byte[] BuildPdfFromTemplate(string templatePath, IDictionary<string, string> tokens)
        {
            using (var documentStream = new FileStream(templatePath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
            using (var wordDocument = new WordDocument(documentStream, FormatType.Docx))
            {
                foreach (var token in tokens)
                {
                    wordDocument.Replace($"##{token.Key}##", token.Value ?? string.Empty, true, true);
                }

                using (var renderer = new DocIORenderer())
                using (var pdfDocument = renderer.ConvertToPDF(wordDocument))
                using (var outputStream = new MemoryStream())
                {
                    pdfDocument.Save(outputStream);
                    return outputStream.ToArray();
                }
            }
        }

        public byte[] MergePdfDocuments(IEnumerable<byte[]> pdfDocuments)
        {
            using (var finalDocument = new PdfDocument())
            {
                foreach (var pdfBytes in pdfDocuments)
                {
                    using (var stream = new MemoryStream(pdfBytes))
                    using (var loadedDocument = new PdfLoadedDocument(stream))
                    {
                        finalDocument.Append(loadedDocument);
                    }
                }

                using (var outputStream = new MemoryStream())
                {
                    finalDocument.Save(outputStream);
                    return outputStream.ToArray();
                }
            }
        }
    }
}
