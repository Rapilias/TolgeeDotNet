#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

dotnet tool restore

mkdir -p \
  src/TolgeeDotNet.ApiClient.NSwag/Generated \
  src/TolgeeDotNet.ApiClient.Kiota/Generated \
  src/TolgeeDotNet.ApiClient.Refitter/Generated

dotnet nswag openapi2csclient \
  /input:Reference/apiSpecs.json \
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
  --openapi Reference/apiSpecs.json \
  --language CSharp \
  --output src/TolgeeDotNet.ApiClient.Kiota/Generated \
  --clean-output \
  --exclude-backward-compatible \
  --namespace-name TolgeeDotNet.ApiClient.Kiota.Generated \
  --class-name TolgeeApiClient \
  --log-level Warning

dotnet refitter Reference/apiSpecs.json \
  --namespace TolgeeDotNet.ApiClient.Refitter.Generated \
  --output src/TolgeeDotNet.ApiClient.Refitter/Generated/TolgeeApiClient.Generated.cs \
  --cancellation-tokens \
  --use-api-response \
  --no-banner \
  --simple-output
