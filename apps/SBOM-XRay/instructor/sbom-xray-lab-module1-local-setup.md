# SBOM X-Ray Lab (Module 1) - Local Setup Guide (Windows)

This guide is for setting up Module 1 on your own machine right now.

## 1) What You Are Setting Up

You are preparing the offline scenario bundle used by students:

- Two container image archives:
  - `flight-path-v1.tar`
  - `radar-control-v1.tar`
- Vendor SBOM file:
  - `vendor_claim.spdx.json`
- Quality checklist:
  - `SBOM_Minimum_Elements.md`
- Student-facing walkthrough:
  - `sbom-xray-lab-student-guide.md`
  - `sbom-xray-lab-student-worksheet.md`

## 2) Prerequisites (Windows)

Install and verify:

1. Docker Desktop (Linux containers mode)
2. Python 3.10+ (`python --version`)
3. PowerShell 5+ (or PowerShell 7+)

Optional local tooling for dry-run commands:

- `jq` (for JSON queries)
- `syft` (if you want to run student commands directly on host)

## 3) Open the Repo in PowerShell

```powershell
cd "C:\Users\Hammo\OneDrive\Documents\Capstone-HAFB\SBOM-Module\SBOM-Training-Module"
```

Confirm scenario files exist:

```powershell
Get-ChildItem ".\training\scenarios\sbom-xray-lab"
Get-ChildItem ".\training\scenarios\sbom-xray-lab\docker"
Get-ChildItem ".\training\scenarios\sbom-xray-lab\artifacts"
```

## 4) Build the Two Training Images and Export TARs

Run:

```powershell
.\training\scenarios\sbom-xray-lab\build-artifacts.ps1
```

What this script does:

1. Builds `sbom-lab-flight-path:v1` from `docker/flight-path/Dockerfile`.
2. Builds `sbom-lab-radar-control:v1` from `docker/radar-control/Dockerfile`.
3. Saves both images to:
  - `training/scenarios/sbom-xray-lab/artifacts/flight-path-v1.tar`
  - `training/scenarios/sbom-xray-lab/artifacts/radar-control-v1.tar`
4. Prints SHA-256 values using `certutil`.

## 5) Verify the Scenario Bundle

Run static checks:

```powershell
python .\scripts\verify_sbom_xray_lab.py
```

Run full checks (includes Docker + Syft OCI image scan of tar files):

```powershell
python .\scripts\verify_sbom_xray_lab.py --full
```

Expected outcome:

- `OK: static lab bundle checks passed.`
- `OK: full Syft checks passed against built tars.` (for `--full`)

## 6) Stage Files for Student Machines

Create a destination folder (example):

```powershell
New-Item -ItemType Directory -Force "$HOME\labs\sbom-xray" | Out-Null
```

Copy required files:

```powershell
Copy-Item ".\training\scenarios\sbom-xray-lab\artifacts\flight-path-v1.tar" "$HOME\labs\sbom-xray\"
Copy-Item ".\training\scenarios\sbom-xray-lab\artifacts\radar-control-v1.tar" "$HOME\labs\sbom-xray\"
Copy-Item ".\training\scenarios\sbom-xray-lab\artifacts\vendor_claim.spdx.json" "$HOME\labs\sbom-xray\"
Copy-Item ".\training\scenarios\sbom-xray-lab\artifacts\SBOM_Minimum_Elements.md" "$HOME\labs\sbom-xray\"
Copy-Item ".\sbom-xray-lab-student-guide.md" "$HOME\labs\sbom-xray\"
Copy-Item ".\sbom-xray-lab-student-worksheet.md" "$HOME\labs\sbom-xray\"
```

## 7) Optional Instructor Dry Run (On Your Host)

If `syft` and `jq` are installed locally, you can run the same core student flow:

```powershell
cd "$HOME\labs\sbom-xray"
syft flight-path-v1.tar -o cyclonedx-json > internal_cdx.json
jq ".components | length" internal_cdx.json
jq ".packages | length" vendor_claim.spdx.json
syft radar-control-v1.tar -o cyclonedx-json > radar_cdx.json
```

If you do not have host `syft`, the `--full` verification command already validates SBOM generation via the pinned Syft container image.

## 8) Air-Gapped Readiness Checklist

- Docker build and export completed with no errors
- Both tar files exist under `artifacts/`
- `python scripts/verify_sbom_xray_lab.py --full` passes
- `vendor_claim.spdx.json` and `SBOM_Minimum_Elements.md` copied
- Student guide + worksheet copied
- Student destination has no dependency on internet access

