#!/usr/bin/env bash

cd "$(dirname "$0")/.."

dotnet jb inspectcode \
    "TolgeeDotNet.slnx" \
    "--include=$REL_FILE" \
    "--caches-home=$CACHE_DIR_WIN" \
    "-o=$SARIF_WIN" \
    "--disable-settings-layers=GlobalAll;GlobalPerProduct" \
    --format=Sarif --severity=WARNING \
    --no-swea --no-build --no-updates --verbosity=WARN
