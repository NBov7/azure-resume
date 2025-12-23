using Newtonsoft.Json;

namespace Company.Function
{
    public class Counter
    {
        [JsonProperty(PropertyName = "id")]
        public string Id { get; set; } = "1";

        [JsonProperty(PropertyName = "partitionKey")]
        public string PartitionKey { get; set; } = "1";

        [JsonProperty(PropertyName = "count")]
        public int Count { get; set; }
    }
}
