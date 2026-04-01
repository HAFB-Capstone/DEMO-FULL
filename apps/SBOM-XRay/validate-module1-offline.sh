#!/usr/bin/env bash
set -euo pipefail

# Offline validation for an installed Module 1 bundle.
# Assumes:
#   - lab folder exists at ~/labs/sbom-Module1-sbom-xray
#   - syft and jq are on PATH

LAB_DIR_DEFAULT="$HOME/labs/sbom-Module1-sbom-xray"
LAB_DIR="$LAB_DIR_DEFAULT"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --lab-dir)
      LAB_DIR="${2:?missing value for --lab-dir}"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

cd "$LAB_DIR"

for f in \
  "flight-path-v1.tar" \
  "radar-control-v1.tar" \
  "vendor_claim.spdx.json" \
  "SBOM_Minimum_Elements.md"
do
  if [[ ! -f "$f" ]]; then
    echo "Missing required file: $LAB_DIR/$f" >&2
    exit 1
  fi
done

if ! command -v syft >/dev/null 2>&1; then
  echo "Missing syft on PATH." >&2
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "Missing jq on PATH." >&2
  exit 1
fi

echo "Tool versions:"
syft --version
jq --version

echo "Validating CycloneDX generation & counts ..."
fp_count="$(syft flight-path-v1.tar -o cyclonedx-json | jq '.components | length')"
radar_count="$(syft radar-control-v1.tar -o cyclonedx-json | jq '.components | length')"

echo "flight-path components: $fp_count"
echo "radar-control components: $radar_count"

if [[ "$fp_count" -lt 3000 || "$fp_count" -gt 4000 ]]; then
  echo "FAIL: flight-path component count out of expected band." >&2
  exit 1
fi
if [[ "$radar_count" -lt 3000 || "$radar_count" -gt 4000 ]]; then
  echo "FAIL: radar-control component count out of expected band." >&2
  exit 1
fi

echo "Validating required shared PURLs exist in intersection ..."
fp_purls="$(mktemp)"
radar_purls="$(mktemp)"
trap 'rm -f "$fp_purls" "$radar_purls"' EXIT

syft flight-path-v1.tar -o cyclonedx-json | jq -r '.components[].purl | select(. != null)' | sort -u > "$fp_purls"
syft radar-control-v1.tar -o cyclonedx-json | jq -r '.components[].purl | select(. != null)' | sort -u > "$radar_purls"
comm -12 "$fp_purls" "$radar_purls" > /tmp/module1-shared-purls.txt

for req in \
  "pkg:pypi/requests@2.31.0" \
  "pkg:pypi/urllib3@2.6.3"
do
  if ! grep -Fq "$req" /tmp/module1-shared-purls.txt; then
    echo "FAIL: missing required shared PURL in intersection: $req" >&2
    exit 1
  fi
done

rm -f /tmp/module1-shared-purls.txt

echo "SUCCESS: Offline Module 1 validation passed."

