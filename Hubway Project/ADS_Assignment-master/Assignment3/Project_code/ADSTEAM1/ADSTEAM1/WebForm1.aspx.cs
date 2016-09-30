using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.IO;
using System.Net.Http;
using System.Net.Http.Formatting;
using System.Net.Http.Headers;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json.Linq;

namespace ADSTEAM1
{

    public class StringTable
    {
        public string[] ColumnNames { get; set; }
        public string[,] Values { get; set; }
    }
    public partial class WebForm1 : System.Web.UI.Page
    {
        static string State;
        static string AccountLength;
        static string AreaCode;
        static string Phone;
        static string IntlPlan;
        static string VMailPlan;
        static string VMailMessage;
        static string DayMins;
        static string DayCalls;
        static string DayCharge;
        static string EveMins;
        static string EveCalls;
        static string EveCharge;
        static string NightMins;
        static string NightCalls;
        static string NightCharge;
        static string IntlMins;
        static string IntlCalls;
        static string IntlCharge;
        static string CustServCalls;
        static string Churn;
        static string temp;
        static string temp1;
        static float tempr;
        static string region;
        static string RegularCalls;

        protected void Page_Load(object sender, EventArgs e)
        {


        }

        public void Button1_Click(object sender, EventArgs e)
        {

            State = DropDownList1.Text;
            AccountLength = TextBox2.Text;
            AreaCode = TextBox3.Text;
            Phone = TextBox4.Text;
            IntlPlan = iPlan.Text;
            VMailPlan = vmp.Text;
            VMailMessage = TextBox7.Text;
            DayMins = TextBox8.Text;
            DayCalls = TextBox9.Text;
            DayCharge = TextBox10.Text;
            EveMins = TextBox11.Text;
            EveCalls = TextBox12.Text;
            EveCharge = TextBox13.Text;
            NightMins = TextBox14.Text;
            NightCalls = TextBox15.Text;
            NightCharge = TextBox16.Text;
            IntlMins = TextBox17.Text;
            IntlCalls = TextBox18.Text;
            IntlCharge = TextBox19.Text;
            CustServCalls = TextBox20.Text;
            Churn = "value";
            

            tempr = float.Parse(DayCalls) + float.Parse(NightCalls) + float.Parse(EveCalls);
            RegularCalls = tempr.ToString();
            List<string> Northeast = new List<string>();
            Northeast.Add("NJ");
            Northeast.Add("NH");
            Northeast.Add("CT");
            Northeast.Add("ME");
            Northeast.Add("MA");
            Northeast.Add("NY");
            Northeast.Add("PA");
            Northeast.Add("RI");
            Northeast.Add("VT");
            List<string> South = new List<string>();
            South.Add("AL");
            South.Add("AR");
            South.Add("DE");
            South.Add("FL");
            South.Add("GA");
            South.Add("KT");
            South.Add("KY");
            South.Add("LA");
            South.Add("MD");
            South.Add("MS");
            South.Add("NC");
            South.Add("OK");
            South.Add("SC");
            South.Add("TN");
            South.Add("TX");
            South.Add("VA");
            South.Add("WV");
            South.Add("DC");

            List<string> West = new List<string>();
            West.Add("AK");
            West.Add("AZ");
            West.Add("CA");
            West.Add("CO");
            West.Add("HI");
            West.Add("ID");
            West.Add("MT");
            West.Add("NV");
            West.Add("NM");
            West.Add("OR");
            West.Add("UT");
            West.Add("WA");
            West.Add("WY");
            List<string> MidWest = new List<string>();
            MidWest.Add("WI");
            MidWest.Add("MN");
            MidWest.Add("MI");
            MidWest.Add("KS");
            MidWest.Add("IA");
            MidWest.Add("IN");
            MidWest.Add("IL");
            MidWest.Add("MO");
            MidWest.Add("NE");
            MidWest.Add("ND");
            MidWest.Add("OH");
            MidWest.Add("SD");






            foreach (string item in Northeast)
            {
                if (item.Contains(State))
                    region = "Northeast";
            }
            foreach (string item in South)
            {
                if (item.Contains(State)) 
                region = "South";
            }
            foreach (string item in West)
            {
                if (item.Contains(State))
                    region = "West";
            }
            foreach (string item in MidWest)
            {
                if (item.Contains(State))
                    region = "Midwest";
            }
            InvokeRequestResponseService().Wait();
         /*   this.output.Text = temp;
          HTML Part:
            <p>
            Scored Label --> 
            <asp:Label ID="output" runat="server" Text=""></asp:Label>
            </p>
            */
            this.outputsp.Text = temp1;


        }
        // static void Main(string[] args)
        //{
        //    InvokeRequestResponseService().Wait();
        // }

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
                                //   ColumnNames = new string[] {"State", "AccountLength", "AreaCode", "Phone", "IntlPlan", "VMailPlan", "VMailMessage", "DayMins", "DayCalls", "DayCharge", "EveMins", "EveCalls", "EveCharge", "NightMins", "NightCalls", "NightCharge", "IntlMins", "IntlCalls", "IntlCharge", "CustServCalls", "Churn"},
                                //  Values = new string[,] {  { State, AccountLength, AreaCode,Phone, IntlPlan, VMailPlan, VMailMessage, DayMins, DayCalls, DayCharge, EveMins, EveCalls, EveCharge, NightMins, NightCalls, NightCharge, IntlMins, IntlCalls, IntlCharge, CustServCalls, "value" }, }
                                // Values = new string[,] {  { "value", "0", "0", "value", "value", "value", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "value" },   }
                                ColumnNames = new string[] {"AccountLength", "IntlPlan", "VMailPlan", "VMailMessage", "DayCharge", "EveCharge", "NightCharge", "IntlCalls", "IntlCharge", "CustServCalls", "RegularCalls", "Region"},
                                Values = new string[,] {  { AccountLength,  IntlPlan, VMailPlan, VMailMessage, DayCharge, EveCharge, NightCharge, IntlCalls ,IntlCharge, CustServCalls, RegularCalls, region }, }
                              //  Values = new string[,] {  { "0", "no", "no", "0", "0", "0", "0", "0", "0", "0", "0", "Midwest" },  { "0", "no", "no", "0", "0", "0", "0", "0", "0", "0", "0", "Midwest" },  }

                            }
                        },
                    },
                    GlobalParameters = new Dictionary<string, string>()
                    {
                    }
                };
                const string apiKey = "OVHigqdqodI6l9dpCYcVMn3E/eHe0W/+NeCL8qV75ra2KMgpPP/cAKSJu8C0d6f3mLVuaE6DR7pMGwqHrLDgMw=="; // Replace this with the API key for the web service
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);

                client.BaseAddress = new Uri("https://ussouthcentral.services.azureml.net/workspaces/5361edf55b9a48fc8b43972c28022e23/services/7a016ed2da904cecabdb5e5b5f9d70d2/execute?api-version=2.0&details=true");

                // WARNING: The 'await' statement below can result in a deadlock if you are calling this code from the UI thread of an ASP.Net application.
                // One way to address this would be to call ConfigureAwait(false) so that the execution does not attempt to resume on the original context.
                // For instance, replace code such as:
                //     result = await DoSomeTask();
                // with the following:
                //    result = await DoSomeTask().ConfigureAwait(false);


                HttpResponseMessage response = await client.PostAsJsonAsync("", scoreRequest).ConfigureAwait(false);

                if (response.IsSuccessStatusCode)
                {
                    string result = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
                    //  result = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
                    // Console.WriteLine("Result: {0}", result);

                    string json = result;
                    string data = JObject.Parse(json)["Results"]["output1"]["value"]["Values"][0][12].ToString();
                    string data2 = JObject.Parse(json)["Results"]["output1"]["value"]["Values"][0][13].ToString();
                    temp1 = data;
                    temp = data2;
                    

                }
                else
                {
                    // Console.WriteLine(string.Format("The request failed with status code: {0}", response.StatusCode));

                    // Print the headers - they include the requert ID and the timestamp, which are useful for debugging the failure
                    // Console.WriteLine(response.Headers.ToString());

                    string responseContent = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
                    //  Console.WriteLine(responseContent);
                }
            }
        }

        protected void DropDownList1_SelectedIndexChanged(object sender, EventArgs e)
        {

        }
    }

}