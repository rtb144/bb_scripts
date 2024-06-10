using System;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using Microsoft.Identity.Client;
using Newtonsoft.Json.Linq;
using System.IO;

class Program
{
    private static string tenantId = "your_tenant_id";
    private static string clientId = "your_client_id";
    private static string clientSecret = "your_client_secret";
    private static string siteUrl = "https://your_army365_domain.sharepoint.com/sites/yoursite";
    private static string listName = "your_list_name";
    private static HttpClient httpClient = new HttpClient();

    static async Task Main(string[] args)
    {
        string accessToken = await GetAccessToken();
        await DownloadAttachments(accessToken);
    }

    private static async Task<string> GetAccessToken()
    {
        var confidentialClient = ConfidentialClientApplicationBuilder.Create(clientId)
            .WithClientSecret(clientSecret)
            .WithAuthority(new Uri($"https://login.microsoftonline.us/{tenantId}"))
            .Build();

        string[] scopes = { $"https://your_army365_domain.sharepoint.com/.default" };

        var authResult = await confidentialClient.AcquireTokenForClient(scopes).ExecuteAsync();
        return authResult.AccessToken;
    }

    private static async Task DownloadAttachments(string accessToken)
    {
        httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
        httpClient.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));

        string listItemsUrl = $"{siteUrl}/_api/web/lists/getbytitle('{listName}')/items?$expand=AttachmentFiles";

        var listItemsResponse = await httpClient.GetAsync(listItemsUrl);
        listItemsResponse.EnsureSuccessStatusCode();
        var listItemsContent = await listItemsResponse.Content.ReadAsStringAsync();

        JObject listItems = JObject.Parse(listItemsContent);
        foreach (var item in listItems["d"]["results"])
        {
            if (item["AttachmentFiles"] != null)
            {
                foreach (var attachment in item["AttachmentFiles"]["results"])
                {
                    string attachmentUrl = $"{siteUrl}{attachment["ServerRelativeUrl"]}";
                    string attachmentName = attachment["FileName"].ToString();

                    var attachmentResponse = await httpClient.GetAsync(attachmentUrl);
                    attachmentResponse.EnsureSuccessStatusCode();
                    var attachmentContent = await attachmentResponse.Content.ReadAsByteArrayAsync();

                    await File.WriteAllBytesAsync(attachmentName, attachmentContent);
                    Console.WriteLine($"Downloaded {attachmentName}");
                }
            }
        }

        Console.WriteLine("All attachments downloaded.");
    }
}
