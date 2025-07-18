using LW_Data;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.OleDb;
using System.IO;
using System.Net.Http.Headers;
using System.Net.Http;
using System.Threading.Tasks;
using static LW_Data.clsSortlyModels;
using System.Net.Http.Json; 

namespace LW_Common
{
    public class clsSortlyHelper
    {
        public string error_message { get; set; }
        public int RowsProcessed { get; set; }
        public string WarningMsg { get; set; }
        private readonly HttpClient _httpClient;
        private readonly string _apiToken = "sk_sortly_yUWmE3Hp6ys4hv8UwyAg";  // Bearer ID from Sortly

        public clsSortlyHelper()
        {
            _httpClient = new HttpClient();
            _httpClient.BaseAddress = new Uri("https://api.sortly.co/api/v1/");
            _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Authorization", _apiToken);
        }

        public bool Import_Sortly_File(string FilePathAndName, string WorksheetName)
        {
            DataTable dtImport = new DataTable();

            clsUtilities.WriteToCounter("Sortly", "Starting...");

            string FolderOnly = Path.GetDirectoryName(FilePathAndName);
            string FileNameOnly = Path.GetFileName(FilePathAndName);
            DateTime FileCreateDate = File.GetCreationTime(FilePathAndName);

            DataSet ds = new DataSet("Temp");

            using (var conn = new OleDbConnection(clsExcelHelper.GetExcelConnectionString(FilePathAndName)))
            {
                conn.Open();
                OleDbDataAdapter adapter = new OleDbDataAdapter(string.Format("SELECT * FROM [{0}$A1:AO]", WorksheetName), conn);
                adapter.Fill(ds);
                conn.Close();
                conn.Dispose();
            }

            DataTable sourceTable = ds.Tables[0];

            DateTime CreateDate = DateTime.Now;
            int NumToProcess = sourceTable.Rows.Count;
            if (NumToProcess > 0)
            {
                // Validate the import file first - All columns are required
                string NotFoundStr = "";
                foreach (string s in new List<string> { "Entry Name", "SID", "Quantity", "Price", "Value", "Sell price", "Notes", "Primary Folder", "Subfolder-level1", "Subfolder-level2", "Subfolder-level3", "Subfolder-level4", "LANDED COST", "WO Date" })
                {
                    if (!sourceTable.Columns.Contains(s)) if (NotFoundStr == "") NotFoundStr += s; else NotFoundStr += ", " + s;
                }
                if (NotFoundStr != "")
                {
                    WarningMsg = "Sortly Import file NOT loaded. Columns not found: " + NotFoundStr;
                    return false;
                }

                // Record the Range Imported
                clsReportHelper.RecordFileDateRanges("Sortly", FileCreateDate);

                // Add rows
                RowsProcessed = 0;
                clsUtilities.WriteToCounter("Sortly", "0 of " + NumToProcess.ToString("#,###"));

                int rowCount = 0;
                foreach (DataRow r in sourceTable.Rows)
                {
                    rowCount++;

                    /* THe WO Number will be calculated later for Sortly data at this point - 
                     * So no WO Number will be imported now. Later we can set the WO Number during the import if we want. 
                     * It is in the Folder columns */

                    // Importing the Excel Sortly file. Not all columns are imported
                    // Just make sure the names of the r[] entries match the column headers

                    clsDataHelper dh = new clsDataHelper();
                    dh.cmd.Parameters.AddWithValue("@ItemName", r["Entry Name"].ToString());
                    dh.cmd.Parameters.AddWithValue("@SortlyID", r["SID"].ToString());
                    dh.cmd.Parameters.AddWithValue("@Quantity", clsFunc.CastToInt(r["Quantity"], 0));
                    dh.cmd.Parameters.AddWithValue("@unitPrice", r["Price"]);
                    dh.cmd.Parameters.AddWithValue("@TotalValue", r["Value"]);
                    dh.cmd.Parameters.AddWithValue("@sellPrice", r["Sell price"]);
                    dh.cmd.Parameters.AddWithValue("@Notes", r["Notes"].ToString());
                    dh.cmd.Parameters.AddWithValue("@PrimaryFolder", r["Primary Folder"].ToString());
                    dh.cmd.Parameters.AddWithValue("@SubFolderLevel1", r["Subfolder-level1"].ToString());
                    dh.cmd.Parameters.AddWithValue("@SubFolderLevel2", r["Subfolder-level2"].ToString());
                    dh.cmd.Parameters.AddWithValue("@SubFolderLevel3", r["Subfolder-level3"].ToString());
                    dh.cmd.Parameters.AddWithValue("@SubFolderLevel4", r["Subfolder-level4"].ToString());
                    if (r["LANDED COST"].ToString().Trim() != "") dh.cmd.Parameters.AddWithValue("@LandedCost", clsFunc.CastToDec(r["LANDED COST"], 0));
                    if (r["WO Date"].ToString().Trim() != "") dh.cmd.Parameters.AddWithValue("@WODate", r["WO Date"].ToString());  // Do not pass parameter if blank to make it NULL
                    dh.cmd.Parameters.AddWithValue("@CreatedBy", "User1");
                    dh.cmd.Parameters.AddWithValue("@CreateDate", CreateDate);

                    dh.cmd.Parameters.AddWithValue("@NoReturn", true);  // Force it to not return data for speed
                    bool isSuccess = dh.ExecuteSPCMD("spSortlyWorkOrderUpdate", false);
                    if (isSuccess) RowsProcessed++; else WarningMsg += " || row " + rowCount.ToString() + ": " + dh.data_err_msg;
                    if (RowsProcessed % 15 == 0) clsUtilities.WriteToCounter("Sortly", RowsProcessed.ToString("#,###") + " of " + NumToProcess.ToString("#,###"));  // only update every 15 records
                }

                // Run the after Stored Procedures to clean up fields
                clsDataHelper sp = new clsDataHelper();
                if (!sp.ExecuteSPCMD("spRptBuilder_WOReview_04_SortlyFixes", false)) WarningMsg += " || spRptBuilder_WOReview_04_SortlyFixes: " + sp.data_err_msg;
            }
            clsUtilities.WriteToCounter("Sortly", "Completed");
            return true;
        }

        public async Task<List<SortlyItem>> GetAllItemsWithFullPathAsync(clsSortlyModels.SortlyFolder rootFolder)
        {
            var allItems = new List<SortlyItem>();
            var folderPaths = new Dictionary<int, string>();
            var queue = new Queue<int>();
            queue.Enqueue(rootFolder.Id);

            folderPaths[rootFolder.Id] = !string.IsNullOrEmpty(rootFolder.ParentRootPath)
                ? $"{rootFolder.ParentRootPath}||{rootFolder.Name}"
                : rootFolder.Name;

            while (queue.Count > 0)
            {
                int currentFolderId = queue.Dequeue();
                string currentFolderPath = folderPaths[currentFolderId];

                HttpResponseMessage response = await _httpClient.GetAsync($"items?folder_id={currentFolderId}&per_page=500");

                if (response.IsSuccessStatusCode)
                {
                    var result = await response.Content.ReadFromJsonAsync<SortlyResponse<SortlyItem>>();

                    foreach (SortlyItem item in result.Data)
                    {
                        string fullFolderPath = $"{currentFolderPath}||{item.Name}";
                        string[] folderPathParts = fullFolderPath.Split(new string[] { "||" }, StringSplitOptions.None);

                        bool includeItem = false;

                        if (fullFolderPath.StartsWith("1-Inventory"))
                        {
                            includeItem = true;
                        }
                        else if (fullFolderPath.StartsWith("4-Today")) // && folderPathParts.Length > 3)
                        {
                            if (folderPathParts.Length > 3)
                            {
                                string dateCandidate = $"{folderPathParts[3]}/{folderPathParts[1]}";

                                if (folderPathParts.Length > 3 && DateTime.TryParse(dateCandidate, out DateTime parsedDate))
                                {
                                    if (parsedDate > DateTime.Today.AddMonths(-3))
                                        includeItem = true;
                                }
                            }
                            else
                            {
                                includeItem = true;
                            }
                        }

                        if (includeItem)
                        {
                            if (item.Type == "folder")
                            {
                                queue.Enqueue(item.Id);
                                folderPaths[item.Id] = fullFolderPath;
                            }
                            else if (item.Type == "item")
                            {
                                item.FolderPath = currentFolderPath;
                                allItems.Add(item);
                            }
                        }
                    }
                }
            }

            // Record the Range Imported
            clsReportHelper.RecordFileDateRanges("Sortly", DateTime.Now);

            return allItems;
        }

        //public async Task<List<SortlyItem>> SearchFolderByNameAsync(clsSortlyModels.SortlyFolder rootFolder, string SearchString)
        //{
        //    var allItems = new List<SortlyItem>();

        //    // Fetch items in the current folder
        //    HttpResponseMessage response = await _httpClient.GetAsync($"items/search?type=folder&folder_ids=%5B{rootFolder.Id}%5D&per_page=50");

        //    var result = await response.Content.ReadFromJsonAsync<SortlyResponse<SortlyItem>>();

        //    foreach (var item in result.Data)
        //    {
        //        if (item.Type == "folder")
        //        {
        //            // Add folder to the queue and update its path
        //            allItems.Add(item);
        //        }
        //    }

        //    return allItems;
        //}

    }
}
