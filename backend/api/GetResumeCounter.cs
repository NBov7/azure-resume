using System.Net;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Azure.Cosmos;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Company.Function;

namespace Company.Function
{
    public class GetResumeCounter
    {
        private readonly CosmosClient _cosmos;
        private readonly ILogger _log;

        public GetResumeCounter(CosmosClient cosmos, ILoggerFactory loggerFactory)
        {
            _cosmos = cosmos;
            _log = loggerFactory.CreateLogger<GetResumeCounter>();
        }

        [Function("GetResumeCounter")]
        public async Task<HttpResponseData> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = null)] HttpRequestData req)
        {
            _log.LogInformation("GetResumeCounter triggered.");

            var db = _cosmos.GetDatabase("AzureResume");
            var container = db.GetContainer("Counter");

            Counter item;
            try
            {
                var read = await container.ReadItemAsync<Counter>(
                    id: "1",
                    partitionKey: new PartitionKey("1"));

                item = read.Resource;
            }
            catch (CosmosException ex) when (ex.StatusCode == HttpStatusCode.NotFound)
            {
                item = new Counter { Id = "1", PartitionKey = "1", Count = 0 };
            }

            item.Count += 1;

            await container.UpsertItemAsync(item, new PartitionKey(item.PartitionKey));

            var res = req.CreateResponse(HttpStatusCode.OK);
            res.Headers.Add("Content-Type", "application/json");
            var payload = new
            {
                count = item.Count,
                source = "legacy"
            };

            await res.WriteStringAsync(JsonConvert.SerializeObject(payload));

            res.Headers.Add("Access-Control-Allow-Origin", "*");
            res.Headers.Add("Cache-Control", "no-store");

            return res;
        }
    }
}
