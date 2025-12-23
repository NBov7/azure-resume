using System.Net;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Azure.Functions.Worker.Extensions.CosmosDB;
using Newtonsoft.Json;

namespace Company.Function;

public class GetResumeCounter
{
    [Function("GetResumeCounter")]
    public async Task<MultiOutput> Run(
        [HttpTrigger(AuthorizationLevel.Function, "get", "post")] HttpRequestData req,

        [CosmosDBInput(
            databaseName: "AzureResume",
            containerName: "Counter",
            Connection = "AzureResumeConnectionString",
            Id = "1",
            PartitionKey = "1")]
        Counter? counter)
    {
        counter ??= new Counter { Id = "1", PartitionKey = "1", Count = 0 };
        counter.Count += 1;

        var response = req.CreateResponse(HttpStatusCode.OK);
        response.Headers.Add("Content-Type", "application/json");
        await response.WriteStringAsync(JsonConvert.SerializeObject(counter));

        return new MultiOutput
        {
            CounterDocument = counter,   // -> wordt naar Cosmos geschreven
            HttpResponse = response      // -> wordt naar client teruggestuurd
        };
    }
}

public class MultiOutput
{
    [CosmosDBOutput(
        databaseName: "AzureResume",
        containerName: "Counter",
        Connection = "AzureResumeConnectionString")]
    public Counter? CounterDocument { get; set; }

    [HttpResult]
    public HttpResponseData? HttpResponse { get; set; }
}
