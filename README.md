https://www.youtube.com/watch?v=YVMoLvMrC8E
https://help.mulesoft.com/s/article/Troubleshooting-Mule-license-key-issues
https://forums.raspberrypi.com/viewtopic.php?t=315172

dotnet add package Microsoft.Identity.Client 

dotnet add package Newtonsoft.Json

8/15/2024, 12:35:25 PM
Information
DIAnalyzeUrl: Calling model with: (documentUrl: https://cazw0cuaadsedstgdsitapi.blob.core.usgovcloudapi.net/afchqdpd-rrp-rforms/sharepoint_download_20240528/ARMY_VOL1_BA3_PB_2025.pdf, documentPages: null, modelId: prebuilt-layout, mode: sync, resultId: null, adfWebActivity: false

8/15/2024, 12:35:26 PM
Information
DIAnalyzeUrl: Error while requesting for analyze result: {"code":"InvalidRequest","message":"Invalid request.","innererror":{"code":"InvalidContent","message":"The file is corrupted or format is unsupported. Refer to documentation for the list of supported formats."}}


8/15/2024, 12:35:26 PM
Information
Executed 'Functions.DIAnalyzeUrl' (Succeeded, Id=43208830-e51a-49fb-8e44-1206e712bec6, Duration=411ms)

using Azure.Identity;
using Azure.ResourceManager;
using Azure.ResourceManager.Sql;
using Microsoft.Data.SqlClient;
using System.Threading.Tasks;

public class AzureSqlManager
{
    public async Task ListSqlDatabases()
    {
        try
        {
            // Create interactive credential that will prompt for MFA
            // This will use your personal Entra ID account
            var credential = new InteractiveBrowserCredential(new InteractiveBrowserCredentialOptions
            {
                // Prompt for login every time - you can remove this to use cached credentials
                TokenCachePersistenceOptions = new TokenCachePersistenceOptions { Enabled = true }
            });
            
            // Create ArmClient instance
            var armClient = new ArmClient(credential);
            
            // Get the default subscription
            var subscription = await armClient.GetDefaultSubscriptionAsync();
            Console.WriteLine($"Connected to subscription: {subscription.Data.DisplayName}");
            
            // Get all SQL Servers in the subscription
            await foreach (var server in subscription.GetSqlServersAsync())
            {
                Console.WriteLine($"\nSQL Server: {server.Data.Name}");
                Console.WriteLine($"Location: {server.Data.Location}");
                Console.WriteLine($"Resource Group: {server.Id.ResourceGroupName}");
                
                // Get databases for each server
                await foreach (var database in server.GetSqlDatabasesAsync())
                {
                    Console.WriteLine($"\n  Database: {database.Data.Name}");
                    Console.WriteLine($"  Status: {database.Data.Status}");
                    Console.WriteLine($"  Creation Date: {database.Data.CreationDate}");
                    Console.WriteLine($"  Edition: {database.Data.SkuData.Name}");
                    Console.WriteLine($"  Max Size in Bytes: {database.Data.MaxSizeInBytes}");

                    // Test connection to the database using your identity
                    await TestDatabaseConnection(server.Data.FullyQualifiedDomainName, 
                                              database.Data.Name);
                }
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error: {ex.Message}");
            if (ex.InnerException != null)
            {
                Console.WriteLine($"Inner Error: {ex.InnerException.Message}");
            }
        }
    }

    private async Task TestDatabaseConnection(string serverName, string databaseName)
    {
        try
        {
            // Build connection string for Azure SQL with Entra ID authentication
            var builder = new SqlConnectionStringBuilder
            {
                DataSource = serverName,
                InitialCatalog = databaseName,
                TrustServerCertificate = true,
                Authentication = SqlAuthenticationMethod.ActiveDirectoryInteractive,
                ConnectTimeout = 30
            };

            using (var connection = new SqlConnection(builder.ConnectionString))
            {
                try
                {
                    Console.WriteLine($"  Attempting to connect to {databaseName}...");
                    await connection.OpenAsync();
                    Console.WriteLine($"  Connection Test: Successfully connected to {databaseName}");

                    // Optional: Test a simple query
                    using (var command = new SqlCommand("SELECT @@VERSION", connection))
                    {
                        var version = await command.ExecuteScalarAsync();
                        Console.WriteLine($"  SQL Server Version: {version}");
                    }
                }
                catch (SqlException sqlEx)
                {
                    Console.WriteLine($"  Connection Test: Failed to connect - {sqlEx.Message}");
                }
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"  Connection Test: Error - {ex.Message}");
        }
    }
}

// Simple program to run the SQL manager
public class Program
{
    public static async Task Main()
    {
        Console.WriteLine("Starting Azure SQL Database inventory...");
        var sqlManager = new AzureSqlManager();
        await sqlManager.ListSqlDatabases();
        Console.WriteLine("\nPress any key to exit...");
        Console.ReadKey();
    }
}
