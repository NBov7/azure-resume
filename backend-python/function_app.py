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

    for attempt in range(1, 6):
        try:
            item = container.read_item(item=item_id, partition_key=pk)
            item["count"] = int(item.get("count", 0)) + 1

            etag = item.get("_etag")
            if etag:
                updated = container.replace_item(
                    item=item_id,
                    body=item,
                    etag=etag,
                    match_condition="IfMatch"
                )
            else:
                updated = container.replace_item(item=item_id, body=item)

            return func.HttpResponse(
                body=json.dumps({"count": int(updated["count"])}),
                status_code=200,
                mimetype="application/json"
            )

        except CosmosHttpResponseError as e:
            if getattr(e, "status_code", None) == 412 and attempt < 5:
                logging.warning("ETag conflict, retrying... attempt=%s", attempt)
                continue
            logging.exception("Cosmos error")
            return func.HttpResponse(
                body=json.dumps({"error": "cosmos_error"}),
                status_code=500,
                mimetype="application/json"
            )
        except Exception:
            logging.exception("Unhandled error")
            return func.HttpResponse(
                body=json.dumps({"error": "server_error"}),
                status_code=500,
                mimetype="application/json"
            )
