#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

export MSYS_NO_PATHCONV=1

# いくつかの定義が不正なので、openapi 定義をマージする
api_spec="Reference/apiSpecs.json"
api_spec_overrides="Reference/apiSpecs.overrides.json"
resolved_api_spec="Reference/apiSpecs.resolved.json"

resolve_openapi_spec() {
  local spec_path="$1"
  local overrides_path="$2"
  local resolved_spec_path="$3"

  if ! command -v jq >/dev/null 2>&1; then
    echo "jq is required to apply OpenAPI schema overrides." >&2
    exit 1
  fi

  local resolved_spec
  resolved_spec="$(mktemp "${resolved_spec_path}.XXXXXX")"

  jq -s '.[0] * .[1]' "$spec_path" "$overrides_path" > "$resolved_spec"
  mv "$resolved_spec" "$resolved_spec_path"
}

resolve_openapi_spec "$api_spec" "$api_spec_overrides" "$resolved_api_spec"

dotnet tool restore

mkdir -p \
  src/TolgeeDotNet.ApiClient.NSwag/Generated \
  src/TolgeeDotNet.ApiClient.Kiota/Generated \
  src/TolgeeDotNet.ApiClient.Refitter/Generated

# クライアント作成

dotnet nswag openapi2csclient \
  /input:"$resolved_api_spec" \
  /output:src/TolgeeDotNet.ApiClient.NSwag/Generated/TolgeeApiClient.Generated.cs \
  /namespace:TolgeeDotNet.ApiClient.NSwag.Generated \
  /classname:{controller}Client \
  /GenerateClientInterfaces:true \
  /GenerateOptionalParameters:true \
  /UseBaseUrl:false \
  /GenerateExceptionClasses:true \
  /JsonLibrary:SystemTextJson \
  /OperationGenerationMode:MultipleClientsFromPathSegments

dotnet kiota generate \
  --openapi "$resolved_api_spec" \
  --language CSharp \
  --output src/TolgeeDotNet.ApiClient.Kiota/Generated \
  --clean-output \
  --exclude-backward-compatible \
  --namespace-name TolgeeDotNet.ApiClient.Kiota.Generated \
  --class-name TolgeeApiClient \
  --log-level Warning

kiota_log="src/TolgeeDotNet.ApiClient.Kiota/Generated/.kiota.log"
if [[ -f "$kiota_log" ]]; then
  LC_ALL=C sort -o "$kiota_log" "$kiota_log"
fi

dotnet refitter "$resolved_api_spec" \
  --namespace TolgeeDotNet.ApiClient.Refitter.Generated \
  --output src/TolgeeDotNet.ApiClient.Refitter/Generated/TolgeeApiClient.Generated.cs \
  --cancellation-tokens \
  --use-api-response \
  --no-banner \
  --simple-output

dotnet build -c Release
