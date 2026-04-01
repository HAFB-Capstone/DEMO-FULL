#!/usr/bin/env bash
set -euo pipefail

# One-command offline installer for SBOM X-Ray Lab (Module 1).
# Run on ubuntuBlue/analysis VM from inside the extracted bundle directory.
#
# Example:
#   cd /tmp/module1-bundle
#   bash ./install-module1-offline.sh

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

BUNDLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TOOL_SYFT_SRC="$BUNDLE_DIR/tooling/syft"
TOOL_JQ_SRC="$BUNDLE_DIR/tooling/jq"

ART_DIR="$BUNDLE_DIR/artifacts"
STUDENT_DIR="$BUNDLE_DIR/student"
INSTR_DIR="$BUNDLE_DIR/instructor"

REQUIRED_ARTIFACTS=(
  "flight-path-v1.tar"
  "radar-control-v1.tar"
  "vendor_claim.spdx.json"
  "SBOM_Minimum_Elements.md"
  "expected_outputs.json"
)

if [[ ! -f "$TOOL_SYFT_SRC" ]]; then
  echo "Missing syft binary in bundle: $TOOL_SYFT_SRC" >&2
  exit 1
fi
if [[ ! -f "$TOOL_JQ_SRC" ]]; then
  echo "Missing jq binary in bundle: $TOOL_JQ_SRC" >&2
  exit 1
fi

for f in "${REQUIRED_ARTIFACTS[@]}"; do
  if [[ "$f" == expected_outputs.json ]]; then
    if [[ ! -f "$BUNDLE_DIR/$f" ]]; then
      echo "Missing $f in bundle root: $BUNDLE_DIR/$f" >&2
      exit 1
    fi
  else
    if [[ ! -f "$ART_DIR/$f" ]]; then
      echo "Missing artifact in bundle: $ART_DIR/$f" >&2
      exit 1
    fi
  fi
done

echo "Installing tooling (pinned syft + jq) ..."
if command -v sudo >/dev/null 2>&1; then
  SUDO="sudo"
else
  SUDO=""
fi

TARGET_BIN_DIR="/usr/local/bin"
if [[ -n "$SUDO" ]] || [[ -w "$TARGET_BIN_DIR" ]]; then
  $SUDO mkdir -p "$TARGET_BIN_DIR" >/dev/null 2>&1 || true
  $SUDO install -m 0755 "$TOOL_SYFT_SRC" "$TARGET_BIN_DIR/syft"
  $SUDO install -m 0755 "$TOOL_JQ_SRC" "$TARGET_BIN_DIR/jq"
  export PATH="$TARGET_BIN_DIR:$PATH"
else
  # Fallback: install into ~/.local/bin (students run immediately after install).
  TARGET_BIN_DIR="$HOME/.local/bin"
  mkdir -p "$TARGET_BIN_DIR"
  install -m 0755 "$TOOL_SYFT_SRC" "$TARGET_BIN_DIR/syft"
  install -m 0755 "$TOOL_JQ_SRC" "$TARGET_BIN_DIR/jq"
  export PATH="$TARGET_BIN_DIR:$PATH"
  echo "WARNING: No sudo/privilege. Installed tools into $TARGET_BIN_DIR." >&2
  echo "Ensure your shell PATH includes $TARGET_BIN_DIR for later sessions." >&2
fi

if ! command -v syft >/dev/null 2>&1; then
  echo "syft not found on PATH after install." >&2
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "jq not found on PATH after install." >&2
  exit 1
fi

echo "Verifying tool versions ..."
syft --version
jq --version

echo "Preparing lab directory: $LAB_DIR"
mkdir -p "$LAB_DIR"
mkdir -p "$LAB_DIR/instructor"

echo "Copying artifacts into lab folder ..."
cp -f "$ART_DIR/"flight-path-v1.tar "$LAB_DIR/"
cp -f "$ART_DIR/"radar-control-v1.tar "$LAB_DIR/"
cp -f "$ART_DIR/"vendor_claim.spdx.json "$LAB_DIR/"
cp -f "$ART_DIR/"SBOM_Minimum_Elements.md "$LAB_DIR/"
cp -f "$BUNDLE_DIR/expected_outputs.json" "$LAB_DIR/"

echo "Copying student guide + worksheet ..."
cp -f "$STUDENT_DIR/"sbom-xray-lab-student-guide.md "$LAB_DIR/"
cp -f "$STUDENT_DIR/"sbom-xray-lab-student-worksheet.md "$LAB_DIR/"

echo "Copying instructor materials ..."
cp -f "$INSTR_DIR"/* "$LAB_DIR/instructor/"

echo "Integrity check (bundle SHA-256sums) ..."
if [[ -f "$BUNDLE_DIR/SHA256SUMS.txt" ]]; then
  (cd "$BUNDLE_DIR" && sha256sum -c "SHA256SUMS.txt")
else
  echo "WARNING: No SHA256SUMS.txt found in bundle; skipping integrity check." >&2
fi

echo "Hard offline sanity: generate + parse CycloneDX SBOM from tars ..."
cd "$LAB_DIR"

# 1) Ensure syft output is valid CycloneDX JSON and component count is in expected band.
fp_count="$(syft flight-path-v1.tar -o cyclonedx-json | jq '.components | length')"
if [[ "$fp_count" -lt 3000 || "$fp_count" -gt 4000 ]]; then
  echo "FAIL: flight-path component count out of expected band: $fp_count" >&2
  exit 1
fi

radar_count="$(syft radar-control-v1.tar -o cyclonedx-json | jq '.components | length')"
if [[ "$radar_count" -lt 3000 || "$radar_count" -gt 4000 ]]; then
  echo "FAIL: radar-control component count out of expected band: $radar_count" >&2
  exit 1
fi

# 2) Ensure required shared PURLs intersect across both images.
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

echo "Creating compatibility symlink for student guide path ..."
mkdir -p "$HOME/labs"
if [[ ! -e "$HOME/labs/sbom-xray" ]]; then
  ln -s "$LAB_DIR" "$HOME/labs/sbom-xray"
fi

echo "SUCCESS: Module 1 offline bundle installed into: $LAB_DIR"
echo "Students should run:"
echo "  cd ~/labs/sbom-xray"
echo "  syft flight-path-v1.tar -o cyclonedx-json > internal_cdx.json"

