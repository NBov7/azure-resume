#!/usr/bin/env bash
set -euo pipefail

# ====== CONFIG (pas aan indien nodig) ======
SUB="316160fa-527f-473a-8f61-ede4e832d315"
RG="rg-azure-resume-weu"
PROFILE="fd-resume-niels"

CD_NAME="resume-nielsbovre-com"
CUSTOM_HOST="resume.nielsbovre.com"

# Endpoint waar je uiteindelijk je custom domain op wil (v2)
TARGET_ENDPOINT="fd-resume-niels-v2"

API_VER="2023-05-01"

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1"; exit 1; }; }
need az
need jq

echo "==> Using subscription: $SUB"
az account set -s "$SUB" >/dev/null

echo "==> Fetch endpoints in profile..."
ENDPOINTS=$(az afd endpoint list -g "$RG" --profile-name "$PROFILE" --query "[].name" -o tsv)

echo "Endpoints:"
echo "$ENDPOINTS" | sed 's/^/ - /'

echo "==> Try get Custom Domain ID (if exists)..."
set +e
CD_ID=$(az afd custom-domain show -g "$RG" --profile-name "$PROFILE" --custom-domain-name "$CD_NAME" --query id -o tsv 2>/dev/null)
set -e

if [[ -n "${CD_ID:-}" ]]; then
  echo "Custom Domain exists: $CD_ID"
  echo "==> Unassociating custom domain from ALL routes on ALL endpoints (PUT overwrite)..."

  for EP in $ENDPOINTS; do
    ROUTES=$(az afd route list -g "$RG" --profile-name "$PROFILE" --endpoint-name "$EP" --query "[].name" -o tsv)
    for R in $ROUTES; do
      # Check if this route contains our custom domain id
      HAS=$(az afd route show -g "$RG" --profile-name "$PROFILE" --endpoint-name "$EP" -n "$R" \
        --query "contains(customDomains[].id, '$CD_ID')" -o tsv 2>/dev/null || echo "false")

      if [[ "$HAS" == "true" ]]; then
        echo " - Clearing domain on endpoint=$EP route=$R"

        RID=$(az afd route show -g "$RG" --profile-name "$PROFILE" --endpoint-name "$EP" -n "$R" --query id -o tsv)

        ROUTE_JSON=$(az rest --method get \
          --url "https://management.azure.com${RID}?api-version=${API_VER}")

        # Overwrite customDomains
        ROUTE_JSON=$(echo "$ROUTE_JSON" | jq '.properties.customDomains = []')

        # PUT back full resource
        az rest --method put \
          --url "https://management.azure.com${RID}?api-version=${API_VER}" \
          --body "$ROUTE_JSON" >/dev/null

        echo "   done."
      fi
    done
  done

  echo "==> Verify no routes still reference the custom domain..."
  FOUND="false"
  for EP in $ENDPOINTS; do
    ROUTES=$(az afd route list -g "$RG" --profile-name "$PROFILE" --endpoint-name "$EP" --query "[].name" -o tsv)
    for R in $ROUTES; do
      HAS=$(az afd route show -g "$RG" --profile-name "$PROFILE" --endpoint-name "$EP" -n "$R" \
        --query "contains(customDomains[].id, '$CD_ID')" -o tsv 2>/dev/null || echo "false")
      if [[ "$HAS" == "true" ]]; then
        echo "!! Still attached: endpoint=$EP route=$R"
        FOUND="true"
      fi
    done
  done

  if [[ "$FOUND" == "true" ]]; then
    echo "ERROR: Some routes still reference the domain. Aborting."
    exit 1
  fi

  echo "==> Delete custom domain..."
  az afd custom-domain delete -g "$RG" --profile-name "$PROFILE" --custom-domain-name "$CD_NAME" -y

  echo "==> Wait until custom domain is gone..."
  for i in {1..30}; do
    if az afd custom-domain show -g "$RG" --profile-name "$PROFILE" --custom-domain-name "$CD_NAME" >/dev/null 2>&1; then
      echo "  still exists... ($i/30)"
      sleep 10
    else
      echo "  deleted."
      break
    fi
  done
else
  echo "Custom Domain does not exist. Continuing to create..."
fi

echo "==> Create custom domain (AFD managed certificate)..."
az afd custom-domain create \
  -g "$RG" \
  --profile-name "$PROFILE" \
  --custom-domain-name "$CD_NAME" \
  --host-name "$CUSTOM_HOST" \
  --certificate-type ManagedCertificate >/dev/null

TOKEN=$(az afd custom-domain show -g "$RG" --profile-name "$PROFILE" --custom-domain-name "$CD_NAME" \
  --query "validationProperties.validationToken" -o tsv)

echo
echo "============================================================"
echo "DNS ACTION REQUIRED (one.com):"
echo "  Type : TXT"
echo "  Name : _dnsauth.resume"
echo "  Value: $TOKEN"
echo "============================================================"
echo
echo "Verify after updating DNS:"
echo "  dig +short TXT _dnsauth.resume.nielsbovre.com"
echo
echo "When dig returns the token above, run:"
echo "  bash scripts/afd-attach-domain.sh"
echo

# Create the attach script as well (idempotent)
cat > scripts/afd-attach-domain.sh <<'ATTACH'
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
ATTACH

chmod +x scripts/afd-attach-domain.sh
echo "==> Wrote scripts/afd-attach-domain.sh"
