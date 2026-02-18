using LW_Common.Documents;
using System.Collections.Generic;

namespace LW_Web.Services
{
    public class SyncfusionDocumentService
    {
        private readonly SyncfusionDocumentEngine _documentEngine = new SyncfusionDocumentEngine();

        public void EnsureTemplatesExist(string templateRootPath, IEnumerable<string> templateNames)
        {
            _documentEngine.EnsureTemplatesExist(templateRootPath, templateNames);
        }

        public byte[] BuildPdfFromTemplate(string templatePath, IDictionary<string, string> tokens)
        {
            return _documentEngine.BuildPdfFromDocxTemplate(templatePath, tokens);
        }

        public byte[] MergePdfDocuments(IEnumerable<byte[]> pdfDocuments)
        {
            return _documentEngine.MergePdfs(pdfDocuments);
        }
    }
}
