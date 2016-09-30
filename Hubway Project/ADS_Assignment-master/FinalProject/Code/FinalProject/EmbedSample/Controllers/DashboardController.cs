using System;
using System.Configuration;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Mvc;
using Microsoft.PowerBI.Api.V1;
using Microsoft.PowerBI.Security;
using Microsoft.Rest;
using paas_demo.Models;
using System.Collections.Generic;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using Newtonsoft.Json.Linq;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Runtime.Serialization;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.WindowsAzure.Storage;
using Microsoft.WindowsAzure.Storage.Auth;
using Microsoft.WindowsAzure.Storage.Blob;
using System.IO;
namespace paas_demo.Controllers
{
    public class StringTable
    {
        public string[] ColumnNames { get; set; }
        public string[,] Values { get; set; }
    }
    public class AzureBlobDataReference
    {
        // Storage connection string used for regular blobs. It has the following format:
        // DefaultEndpointsProtocol=https;AccountName=ACCOUNT_NAME;AccountKey=ACCOUNT_KEY
        // It's not used for shared access signature blobs.
        public string ConnectionString { get; set; }

        // Relative uri for the blob, used for regular blobs as well as shared access 
        // signature blobs.
        public string RelativeLocation { get; set; }

        // Base url, only used for shared access signature blobs.
        public string BaseLocation { get; set; }

        // Shared access signature, only used for shared access signature blobs.
        public string SasBlobToken { get; set; }
    }
    public enum BatchScoreStatusCode
    {
        NotStarted,
        Running,
        Failed,
        Cancelled,
        Finished
    }
    public class BatchScoreStatus
    {
        // Status code for the batch scoring job
        public BatchScoreStatusCode StatusCode { get; set; }


        // Locations for the potential multiple batch scoring outputs
        public IDictionary<string, AzureBlobDataReference> Results { get; set; }

        // Error details, if any
        public string Details { get; set; }
    }
    public class BatchExecutionRequest
    {

        public IDictionary<string, AzureBlobDataReference> Inputs { get; set; }
        public IDictionary<string, string> GlobalParameters { get; set; }

        // Locations for the potential multiple batch scoring outputs
        public IDictionary<string, AzureBlobDataReference> Outputs { get; set; }
    }
    public class DashboardController : Controller
    {
        private readonly string workspaceCollection;
        private readonly string workspaceId;
        private readonly string accessKey;
        private readonly string apiUrl;
        static string candidate;
        static string responsebn;
        static int population;
        static float ageG;
        static float black;
        static float latino;
        static float white;
        static float Highschool;
        static float bachelors;
        static float houseHold;
        static float povertyLevel;
        static float populationPSM;
        static string fPath;
        static string temp;
        static string dt = DateTime.UtcNow.ToString();
        public DashboardController()
        {
            this.workspaceCollection = ConfigurationManager.AppSettings["powerbi:WorkspaceCollection"];
            this.workspaceId = ConfigurationManager.AppSettings["powerbi:WorkspaceId"];
            this.accessKey = ConfigurationManager.AppSettings["powerbi:AccessKey"];
            this.apiUrl = ConfigurationManager.AppSettings["powerbi:ApiUrl"];
            responsebn = null;
        }

        public ActionResult Index()
        {
            return View();
        }
        public ActionResult Webapp()
        {
            candidate = Request.QueryString["candi"];
            return View();
            
        }
        public ActionResult BatchE()
        {
            candidate = Request.QueryString["candi"];
            return View();

        }

        [HttpPost]
        public ActionResult BatchE(BatchViewModel bv)
        {
            if (ModelState.IsValid)
            {
               // candidate = Request.QueryString["candi"];
                
                
                fPath = bv.inputPath;
                //responsebn = fPath;
                InvokeBatchExecutionService().Wait();
                ViewBag.Message = responsebn;
                return View();
                
            }
            else
            {
                
                ModelState.Clear();
                return View();
            }
            
        }
        static async Task WriteFailedResponse(HttpResponseMessage response)
        {
            
            Console.WriteLine(string.Format("The request failed with status code: {0}", response.StatusCode));

            // Print the headers - they include the requert ID and the timestamp, which are useful for debugging the failure
            Console.WriteLine(response.Headers.ToString());

            string responseContent = await response.Content.ReadAsStringAsync().ConfigureAwait(false); ;
            Console.WriteLine(responseContent);
            
        }


        static void SaveBlobToFile(AzureBlobDataReference blobLocation, string resultsLabel)
        {
            const string OutputFileLocation = "C:\\Users\\Public\\Documents\\output.csv"; // Replace this with the location you would like to use for your output file

            var credentials = new StorageCredentials(blobLocation.SasBlobToken);
            var blobUrl = new Uri(new Uri(blobLocation.BaseLocation), blobLocation.RelativeLocation);
            var cloudBlob = new CloudBlockBlob(blobUrl, credentials);

            Console.WriteLine(string.Format("Reading the result from {0}", blobUrl.ToString()));
            cloudBlob.DownloadToFile(OutputFileLocation, FileMode.Create);
            responsebn = string.Format("{0} have been written to the file {1}", resultsLabel, OutputFileLocation);
            Console.WriteLine(string.Format("{0} have been written to the file {1}", resultsLabel, OutputFileLocation));
        }



        static void UploadFileToBlob(string inputFileLocation, string inputBlobName, string storageContainerName, string storageConnectionString)
        {
            // Make sure the file exists
            if (!System.IO.File.Exists(inputFileLocation))
            {
                throw new FileNotFoundException(
                    string.Format(
                        CultureInfo.InvariantCulture,
                        "File {0} doesn't exist on local computer.",
                        inputFileLocation));
            }

            Console.WriteLine("Uploading the input to blob storage...");

            var blobClient = CloudStorageAccount.Parse(storageConnectionString).CreateCloudBlobClient();
            var container = blobClient.GetContainerReference(storageContainerName);
            container.CreateIfNotExists();
            var blob = container.GetBlockBlobReference(inputBlobName);
            blob.UploadFromFile(inputFileLocation);
        }



        static void ProcessResults(BatchScoreStatus status)
        {


            bool first = true;
            foreach (var output in status.Results)
            {
                var blobLocation = output.Value;
                Console.WriteLine(string.Format("The result '{0}' is available at the following Azure Storage location:", output.Key));
                Console.WriteLine(string.Format("BaseLocation: {0}", blobLocation.BaseLocation));
                Console.WriteLine(string.Format("RelativeLocation: {0}", blobLocation.RelativeLocation));
                Console.WriteLine(string.Format("SasBlobToken: {0}", blobLocation.SasBlobToken));
                Console.WriteLine();


                // Save the first output to disk
                if (first)
                {
                    first = false;
                    SaveBlobToFile(blobLocation, string.Format("The results for {0}", output.Key));
                }
            }
        }

        static async Task InvokeBatchExecutionService()
        {
          

            // responsebn = dt;
            // How this works:
            //
            // 1. Assume the input is present in a local file (if the web service accepts input)
            // 2. Upload the file to an Azure blob - you'd need an Azure storage account
            // 3. Call the Batch Execution Service to process the data in the blob. Any output is written to Azure blobs.
            // 4. Download the output blob, if any, to local file


            const string StorageAccountName = "azureabhi"; // Replace this with your Azure Storage Account name
            const string StorageAccountKey = "IYbg4A2yBtrGj5W7oElpxzF5wsEl0UV+pkGloEgRRu2NwZjDC1F30f23/HzkjFPBu1pv16bbesm06ifPYwWPpQ=="; // Replace this with your Azure Storage Key
            const string StorageContainerName = "abhione"; // Replace this with your Azure Storage Container name
            string BaseUrl;
            string apiKey;
            // set a time out for polling status
            const int TimeOutInMilliseconds = 120 * 1000; // Set a timeout of 2 minutes


            string storageConnectionString = string.Format("DefaultEndpointsProtocol=https;AccountName={0};AccountKey={1}", StorageAccountName, StorageAccountKey);

            UploadFileToBlob(fPath /*Replace this with the location of your input file*/,
               "inputdatablob"+dt+".csv" /*Replace this with the name you would like to use for your Azure blob; this needs to have the same extension as the input file */,
               StorageContainerName, storageConnectionString);

            using (HttpClient client = new HttpClient())
            {
                var request = new BatchExecutionRequest()
                {

                    Inputs = new Dictionary<string, AzureBlobDataReference>()
                    {

                        {
                            "input1",
                            new AzureBlobDataReference()
                            {
                                ConnectionString = storageConnectionString,
                                RelativeLocation = string.Format("{0}/inputdatablob"+dt+".csv", StorageContainerName)
                            }
                        },
                    },

                    Outputs = new Dictionary<string, AzureBlobDataReference>()
                    {

                        {
                            "output1",
                            new AzureBlobDataReference()
                            {
                                ConnectionString = storageConnectionString,
                                RelativeLocation = string.Format("/{0}/outputresults"+dt+".csv", StorageContainerName)
                            }
                        },
                    },
                    GlobalParameters = new Dictionary<string, string>()
                    {
                    }
                };
                if (candidate.ToString().Equals("4"))
                {

                      BaseUrl = "https://ussouthcentral.services.azureml.net/workspaces/5361edf55b9a48fc8b43972c28022e23/services/f467bcb10500475bbc18b7b1272e4c0d/jobs";
                      apiKey = "g+g4Zsl7z4/aluvYnvj5e5ZnkDZDWwVO0wKSn4dsv47uG958rlIG/QUptoH8d810F8jbCyvnfh3NkkHEOanTWg=="; // Replace this with the API key for the web service


                }
                else if (candidate.ToString().Equals("5"))
                {
                    responsebn = candidate;
                      BaseUrl = "https://ussouthcentral.services.azureml.net/workspaces/5361edf55b9a48fc8b43972c28022e23/services/2a7fbf30526c49d2bf886d3f755809f6/jobs";
                      apiKey = "poHGh5CLoe05k02n/sZLS2Poxv1U1fG14FumEp9otNmUj9TT79hHx0JS6tJ8nwf8YuyYpd0bS9VISoglDha3zw=="; // Replace this with the API key for the web service


                }
                else if (candidate.ToString().Equals("6"))
                {
                    responsebn = candidate;
                      BaseUrl = "https://ussouthcentral.services.azureml.net/workspaces/5361edf55b9a48fc8b43972c28022e23/services/080223b738e140b492e82e3fb9aa30fa/jobs";
                     apiKey = "JHA0hJLMWX8ziIBq2eKDYBJWZnshByCxT8qTP/+bVc9tNGguDucvbnLCV2JMgvuv4Bfrzo2dQYRaLPDa06oLpw=="; // Replace this with the API key for the web service


                }
                else if (candidate.ToString().Equals("7"))
                {
                    responsebn = candidate;
                      BaseUrl = "https://ussouthcentral.services.azureml.net/workspaces/5361edf55b9a48fc8b43972c28022e23/services/a0a7dca9825446539beee94557375866/jobs";
                      apiKey = "XRadRZlxubzav+YENCAjxyJcyPMlMKWEmoWyi7bCuH3Xu7dNWbzl/bJ1amuVe5jftQ/S+0TfcaGs8s03fCSJVg=="; // Replace this with the API key for the web service


                }
                else
                {
                    responsebn = "Not Valid Request";
                    BaseUrl = "";
                    apiKey = "";

                }
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);

                // WARNING: The 'await' statement below can result in a deadlock if you are calling this code from the UI thread of an ASP.Net application.
                // One way to address this would be to call ConfigureAwait(false) so that the execution does not attempt to resume on the original context.
                // For instance, replace code such as:
                //      result = await DoSomeTask()
                // with the following:
                //      result = await DoSomeTask().ConfigureAwait(false)


                Console.WriteLine("Submitting the job...");
                
                // submit the job
                var response = await client.PostAsJsonAsync(BaseUrl + "?api-version=2.0", request).ConfigureAwait(false);
               
                if (!response.IsSuccessStatusCode)
                {
                   // responsebn = response.IsSuccessStatusCode.ToString();
                    await WriteFailedResponse(response).ConfigureAwait(false);
                    return;
                }

                string jobId = await response.Content.ReadAsAsync<string>().ConfigureAwait(false);
                Console.WriteLine(string.Format("Job ID: {0}", jobId));


                // start the job
                Console.WriteLine("Starting the job...");
                response = await client.PostAsync(BaseUrl + "/" + jobId + "/start?api-version=2.0", null).ConfigureAwait(false);
                if (!response.IsSuccessStatusCode)
                {
                    await WriteFailedResponse(response).ConfigureAwait(false);
                    return;
                }

                string jobLocation = BaseUrl + "/" + jobId + "?api-version=2.0";
                Stopwatch watch = Stopwatch.StartNew();
                bool done = false;
                while (!done)
                {
                    Console.WriteLine("Checking the job status...");
                    response = await client.GetAsync(jobLocation).ConfigureAwait(false);
                    if (!response.IsSuccessStatusCode)
                    {
                        await WriteFailedResponse(response).ConfigureAwait(false);
                        return;
                    }

                    BatchScoreStatus status = await response.Content.ReadAsAsync<BatchScoreStatus>().ConfigureAwait(false);
                    if (watch.ElapsedMilliseconds > TimeOutInMilliseconds)
                    {
                        done = true;
                        Console.WriteLine(string.Format("Timed out. Deleting job {0} ...", jobId));
                        await client.DeleteAsync(jobLocation).ConfigureAwait(false);
                    }
                    switch (status.StatusCode)
                    {
                        case BatchScoreStatusCode.NotStarted:
                            Console.WriteLine(string.Format("Job {0} not yet started...", jobId));
                            break;
                        case BatchScoreStatusCode.Running:
                            Console.WriteLine(string.Format("Job {0} running...", jobId));
                            break;
                        case BatchScoreStatusCode.Failed:
                            Console.WriteLine(string.Format("Job {0} failed!", jobId));
                            Console.WriteLine(string.Format("Error details: {0}", status.Details));
                            done = true;
                            break;
                        case BatchScoreStatusCode.Cancelled:
                            Console.WriteLine(string.Format("Job {0} cancelled!", jobId));
                            done = true;
                            break;
                        case BatchScoreStatusCode.Finished:
                            done = true;
                            Console.WriteLine(string.Format("Job {0} finished!", jobId));

                            ProcessResults(status);
                            break;
                    }

                    if (!done)
                    {
                        Thread.Sleep(1000); // Wait one second
                    }
                }
            }
        }
        [HttpPost]
        public ActionResult Webapp(WebAppViewModel mv)
        {
            //  this.lblone 
            if(ModelState.IsValid )
            {
                population = mv.Population;
                ageG = mv.AgeGreaterThan65;
                black = mv.Black;
                latino = mv.Latino;
                white = mv.White;
                Highschool = mv.HighSchool;
                bachelors = mv.Bachelors;
                houseHold = mv.MedianHouseholdIncome;
                povertyLevel = mv.BelowPovertylevel;
                populationPSM = mv.PopulationPSM;
                InvokeRequestResponseService().Wait();
                ViewBag.Message = responsebn;

                ModelState.Clear();
            }
            else
            {
                ViewBag.Message = "You are great!";
                ModelState.Clear();
            }
            return View(mv);
        }
        static async Task InvokeRequestResponseService()
        {
            using (var client = new HttpClient())
            {
                var scoreRequest = new
                {

                    Inputs = new Dictionary<string, StringTable>() {
                        {
                            "input1",
                            new StringTable()
                            {
                                ColumnNames = new string[] {"Population", "Age > 65", "Black", "Latino", "White", "HighSchool", "Bachelors", "Median Household", "< Poverty level", "Population PSM"},
                                Values = new string[,] {  { "0", "0", "0", "0", "0", "0", "0", "0", "0", "0" },  { "0", "0", "0", "0", "0", "0", "0", "0", "0", "0" },  }
                                //Values = new string[,] {  { "55395", "13.8", "18.7", "2.7", "75.6", "85.6", "20.9", "53682", "12.1", "91.8" },  }
                            }
                        },
                    },
                    GlobalParameters = new Dictionary<string, string>()
                    {
                    }
                };
                string req;
                 
                if (candidate.ToString().Equals("0"))
                {
                    req = "{'Inputs': {'input1': {'ColumnNames': ['Population','AgeGreaterThan65','Black','Latino','White','HighSchool','Bachelors','MedianHouseholdIncome','BelowPovertylevel','PopulationPSM'],'Values': [[" + population + "," + ageG + "," + black + "," + latino + "," + white + "," + Highschool + "," + bachelors + "," + houseHold + "," + povertyLevel + "," + populationPSM + "],]    } },  'GlobalParameters': {}}";
                    const string apiKey = "g+g4Zsl7z4/aluvYnvj5e5ZnkDZDWwVO0wKSn4dsv47uG958rlIG/QUptoH8d810F8jbCyvnfh3NkkHEOanTWg=="; // Replace this with the API key for the web service
                    client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);

                    client.BaseAddress = new Uri("https://ussouthcentral.services.azureml.net/workspaces/5361edf55b9a48fc8b43972c28022e23/services/f467bcb10500475bbc18b7b1272e4c0d/execute?api-version=2.0&details=true");


                }
                else if (candidate.ToString().Equals("1"))
                {
                    responsebn = candidate;
                    req = "{'Inputs': {'input1': {'ColumnNames': ['Population','AgeGreaterThan65','Black','Latino','White','HighSchool','Bachelors','MedianHouseholdIncome','BelowPovertylevel','PopulationPSM'],'Values': [[" + population + "," + ageG + "," + black + "," + latino + "," + white + "," + Highschool + "," + bachelors + "," + houseHold + "," + povertyLevel + "," + populationPSM + "],]    } },  'GlobalParameters': {}}";
                    const string apiKey = "poHGh5CLoe05k02n/sZLS2Poxv1U1fG14FumEp9otNmUj9TT79hHx0JS6tJ8nwf8YuyYpd0bS9VISoglDha3zw=="; // Replace this with the API key for the web service
                    client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);

                    client.BaseAddress = new Uri("https://ussouthcentral.services.azureml.net/workspaces/5361edf55b9a48fc8b43972c28022e23/services/2a7fbf30526c49d2bf886d3f755809f6/execute?api-version=2.0&details=true");


                }
                else if (candidate.ToString().Equals("2"))
                {
                    responsebn = candidate;
                    req = "{'Inputs': {'input1': {'ColumnNames': ['Population','AgeGreaterThan65','Black','Latino','White','HighSchool','Bachelors','MedianHouseholdIncome','BelowPovertylevel','PopulationPSM'],'Values': [[" + population + "," + ageG + "," + black + "," + latino + "," + white + "," + Highschool + "," + bachelors + "," + houseHold + "," + povertyLevel + "," + populationPSM + "],]    } },  'GlobalParameters': {}}";
                    const string apiKey = "JHA0hJLMWX8ziIBq2eKDYBJWZnshByCxT8qTP/+bVc9tNGguDucvbnLCV2JMgvuv4Bfrzo2dQYRaLPDa06oLpw=="; // Replace this with the API key for the web service
                    client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);

                    client.BaseAddress = new Uri("https://ussouthcentral.services.azureml.net/workspaces/5361edf55b9a48fc8b43972c28022e23/services/080223b738e140b492e82e3fb9aa30fa/execute?api-version=2.0&details=true");


                }
                else if (candidate.ToString().Equals("3"))
                {
                    responsebn = candidate;
                    req = "{ 'Inputs': {'input1': {'ColumnNames': ['Population','AgeGreaterThan65','Black','Latino','White','HighSchool','Bachelors','MedianHouseholdIncome','BelowPovertylevel','PopulationPSM'],'Values': [[" + population + "," + ageG + "," + black + "," + latino + "," + white + "," + Highschool + "," + bachelors + "," + houseHold + "," + povertyLevel + "," + populationPSM + "]] }},  'GlobalParameters': {}}";
                    const string apiKey = "XRadRZlxubzav+YENCAjxyJcyPMlMKWEmoWyi7bCuH3Xu7dNWbzl/bJ1amuVe5jftQ/S+0TfcaGs8s03fCSJVg=="; // Replace this with the API key for the web service
                    client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);

                    client.BaseAddress = new Uri("https://ussouthcentral.services.azureml.net/workspaces/5361edf55b9a48fc8b43972c28022e23/services/a0a7dca9825446539beee94557375866/execute?api-version=2.0&details=true");


                }
                else
                {
                    responsebn = "Not Valid Request";
                    req = "{'Inputs': {'input1': {'ColumnNames': ['Population','AgeGreaterThan65','Black','Latino','White','HighSchool','Bachelors','MedianHouseholdIncome','BelowPovertylevel','PopulationPSM'],'Values': [[" + population + "," + ageG + "," + black + "," + latino + "," + white + "," + Highschool + "," + bachelors + "," + houseHold + "," + povertyLevel + "," + populationPSM + "],]    } },  'GlobalParameters': {}}";
                   // const string apiKey = "poHGh5CLoe05k02n/sZLS2Poxv1U1fG14FumEp9otNmUj9TT79hHx0JS6tJ8nwf8YuyYpd0bS9VISoglDha3zw=="; // Replace this with the API key for the web service
                   // client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);

                    //client.BaseAddress = new Uri("https://ussouthcentral.services.azureml.net/workspaces/5361edf55b9a48fc8b43972c28022e23/services/2a7fbf30526c49d2bf886d3f755809f6/execute?api-version=2.0&details=true");
                }
                // WARNING: The 'await' statement below can result in a deadlock if you are calling this code from the UI thread of an ASP.Net application.
                // One way to address this would be to call ConfigureAwait(false) so that the execution does not attempt to resume on the original context.
                // For instance, replace code such as:
                //      result = await DoSomeTask()
                // with the following:
                //      result = await DoSomeTask().ConfigureAwait(false)
                //WebAppViewModel p = new WebAppViewModel { population = 123, ageG = 54, bachelors=23,black=32, Highschool=23 , houseHold=32, latino=23, populationPSM=32, povertyLevel=23, white=23};
               // responsebn = new JavaScriptSerializer().Serialize(scoreRequest);
               HttpResponseMessage response = await client.PostAsync("", new StringContent(req, Encoding.UTF8, "application/json")).ConfigureAwait(false);
            //    HttpResponseMessage response = await client.PostAsJsonAsync("", scoreRequest);
               // HttpResponseMessage response = await client.PostAsync("", new StringContent(
   //new JavaScriptSerializer().Serialize(scoreRequest), Encoding.UTF8, "application/json")).ConfigureAwait(false);
                if (response.IsSuccessStatusCode)
                {
                    string result = await response.Content.ReadAsStringAsync().ConfigureAwait(false);

                    //Console.WriteLine("Result: {0}", result);
                    string json = result;
                    string data = JObject.Parse(json)["Results"]["output1"]["value"]["Values"][0].ToString();

                  responsebn = data;
                }
                else
                {
                    //Console.WriteLine(string.Format("The request failed with status code: {0}", response.StatusCode));

                    // Print the headers - they include the requert ID and the timestamp, which are useful for debugging the failure
                    //Console.WriteLine(response.Headers.ToString());
                    
                    string responseContent = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
                    //  Console.WriteLine(responseContent);
                    responsebn = responseContent;
                }
            }
        }
        [ChildActionOnly]
        public ActionResult Reports()
        {
            using (var client = this.CreatePowerBIClient())
            {
                var reportsResponse = client.Reports.GetReports(this.workspaceCollection, this.workspaceId);

                var viewModel = new ReportsViewModel
                {
                    Reports = reportsResponse.Value.ToList()
                };

                return PartialView(viewModel);
            }
        }
        
        public async Task<ActionResult> Report(string reportId)
        {
            using (var client = this.CreatePowerBIClient())
            {
                var reportsResponse = await client.Reports.GetReportsAsync(this.workspaceCollection, this.workspaceId).ConfigureAwait(false);
                var report = reportsResponse.Value.FirstOrDefault(r => r.Id == reportId);
                var embedToken = PowerBIToken.CreateReportEmbedToken(this.workspaceCollection, this.workspaceId, report.Id);

                var viewModel = new ReportViewModel
                {
                    Report = report,
                    AccessToken = embedToken.Generate(this.accessKey)
                };

                return View(viewModel);
            }
        }

        private IPowerBIClient CreatePowerBIClient()
        {
            var credentials = new TokenCredentials(accessKey, "AppKey");
            var client = new PowerBIClient(credentials)
            {
                BaseUri = new Uri(apiUrl)
            };

            return client;
        }
    }
}