import json
import logging
import os

import azure.functions as func
from azure.cosmos import CosmosClient
from azure.cosmos.exceptions import CosmosHttpResponseError

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

def _env(name: str, default: str | None = None) -> str:
    v = os.getenv(name, default)
    if not v:
        raise ValueError(f"Missing env var: {name}")
    return v

@app.route(route="health", methods=["GET"])
def health(req: func.HttpRequest) -> func.HttpResponse:
    return func.HttpResponse("ok", status_code=200)

@app.route(route="GetResumeCounter", methods=["GET"])
def get_resume_counter(req: func.HttpRequest) -> func.HttpResponse:
    logging.info("GetResumeCounter called")

    endpoint = _env("COSMOS_ENDPOINT")
    key = _env("COSMOS_KEY")
    db_name = _env("COSMOS_DATABASE", "AzureResume")
    container_name = _env("COSMOS_CONTAINER", "Counter")
    item_id = _env("COSMOS_COUNTER_ID", "1")
    pk = _env("COSMOS_PARTITION_KEY", "1")

    client = CosmosClient(endpoint, credential=key)
    container = client.get_database_client(db_name).get_container_client(container_name)

    try:
        updated = container.patch_item(
            item=item_id,
            partition_key=pk,
            patch_operations=[{"op": "incr", "path": "/count", "value": 1}],
        )

        return func.HttpResponse(
            body=json.dumps({"count": int(updated["count"])}),
            status_code=200,
            mimetype="application/json"
        )

    except Exception:
        logging.exception("Counter update failed")
        return func.HttpResponse(
            body=json.dumps({"error": "server_error"}),
            status_code=500,
            mimetype="application/json"
        )
