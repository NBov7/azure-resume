using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Azure.Cosmos;
using System;

var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureServices(services =>
    {
        var conn = Environment.GetEnvironmentVariable("AzureResumeConnectionString");
        if (string.IsNullOrWhiteSpace(conn))
            throw new Exception("Missing app setting: AzureResumeConnectionString");

        services.AddSingleton(new CosmosClient(conn));
    })
    .Build();

host.Run();
