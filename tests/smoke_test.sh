#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
bash -n "$root/bin/mgfpolisher" "$root/lib/common.sh" "$root"/bin/*.sh
for token in READS REFERENCE_FASTA RUN_NAME FAMILY_REGEX GENOME_MAP_MODE MAP_PRESET; do grep -q "$token" "$root/config/example.env"; done
echo "Smoke test passed"
