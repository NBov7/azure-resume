#!/usr/bin/env bash
set -euo pipefail

RG="rg-azure-resume-weu"
PROFILE="fd-resume-niels"
CD_NAME="resume-nielsbovre-com"
TARGET_ENDPOINT="fd-resume-niels-v2"
API_VER="2023-05-01"

CD_ID=$(az afd custom-domain show -g "$RG" --profile-name "$PROFILE" --custom-domain-name "$CD_NAME" --query id -o tsv)

ROUTE_WEB_ID=$(az afd route show -g "$RG" --profile-name "$PROFILE" --endpoint-name "$TARGET_ENDPOINT" -n route-web --query id -o tsv)
ROUTE_API_ID=$(az afd route show -g "$RG" --profile-name "$PROFILE" --endpoint-name "$TARGET_ENDPOINT" -n route-api --query id -o tsv)

az rest --method patch \
  --url "https://management.azure.com${ROUTE_WEB_ID}?api-version=${API_VER}" \
  --body "{\"properties\":{\"customDomains\":[{\"id\":\"${CD_ID}\"}]}}"

az rest --method patch \
  --url "https://management.azure.com${ROUTE_API_ID}?api-version=${API_VER}" \
  --body "{\"properties\":{\"customDomains\":[{\"id\":\"${CD_ID}\"}]}}"

echo "Attached custom domain to routes on endpoint: $TARGET_ENDPOINT"
echo "Check status:"
echo "  az afd custom-domain show -g \"$RG\" --profile-name \"$PROFILE\" --custom-domain-name \"$CD_NAME\" --query \"{validation:domainValidationState, deployment:deploymentStatus}\" -o json"
