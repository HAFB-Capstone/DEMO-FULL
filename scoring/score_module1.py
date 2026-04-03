#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_BUNDLE = (
    REPO_ROOT.parent
    / "SBOM-Training-Module"
    / "deploy"
    / "releases"
    / "Module1-offline-bundle-sbom-xray-2026-03-25_004519"
)
DEFAULT_LAB_DIR = Path.home() / "labs" / "sbom-Module1-sbom-xray"
DEFAULT_COMPAT_SYMLINK = Path.home() / "labs" / "sbom-xray"
REPORT_JSON = REPO_ROOT / "reports" / "module1-score-latest.json"
REPORT_MD = REPO_ROOT / "reports" / "module1-score-latest.md"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Score the readiness of SBOM Training Module 1 after Ansible deployment."
    )
    parser.add_argument(
        "--bundle-source-dir",
        default=os.environ.get("SBOM_BUNDLE_SOURCE_DIR", str(DEFAULT_BUNDLE)),
        help="Path to the extracted Module 1 offline bundle.",
    )
    parser.add_argument(
        "--lab-dir",
        default=str(DEFAULT_LAB_DIR),
        help="Installed lab directory to evaluate.",
    )
    parser.add_argument(
        "--compat-symlink",
        default=str(DEFAULT_COMPAT_SYMLINK),
        help="Expected compatibility symlink path.",
    )
    parser.add_argument(
        "--weights",
        default=str(REPO_ROOT / "scoring" / "weights.json"),
        help="Weight configuration file.",
    )
    parser.add_argument(
        "--skip-validator",
        action="store_true",
        help="Skip the official Module 1 validator and score only static checks.",
    )
    return parser.parse_args()


def load_weights(path: Path) -> list[dict[str, Any]]:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)["checks"]


def run_check(check_id: str, bundle_dir: Path, lab_dir: Path, compat_symlink: Path, skip_validator: bool) -> tuple[bool, str]:
    required_artifacts = [
        "flight-path-v1.tar",
        "radar-control-v1.tar",
        "vendor_claim.spdx.json",
        "SBOM_Minimum_Elements.md",
    ]
    student_guide_names = [
        "sbom-xray-lab-Module1-student-guide.md",
        "sbom-xray-lab-student-guide.md",
    ]
    student_worksheet_names = [
        "sbom-xray-lab-Module1-student-worksheet.md",
        "sbom-xray-lab-student-worksheet.md",
    ]

    if check_id == "bundle_source_present":
        ok = bundle_dir.exists() and bundle_dir.is_dir() and (bundle_dir / "install-module1-offline.sh").exists()
        return ok, f"bundle_dir={bundle_dir}"

    if check_id == "lab_directory_present":
        ok = lab_dir.exists() and lab_dir.is_dir()
        return ok, f"lab_dir={lab_dir}"

    if check_id == "student_artifacts_present":
        missing = [name for name in required_artifacts if not (lab_dir / name).exists()]
        if not any((lab_dir / name).exists() for name in student_guide_names):
            missing.append("student guide")
        if not any((lab_dir / name).exists() for name in student_worksheet_names):
            missing.append("student worksheet")
        return not missing, "all required student artifacts present" if not missing else f"missing: {', '.join(missing)}"

    if check_id == "instructor_materials_present":
        instructor_dir = lab_dir / "instructor"
        file_count = len(list(instructor_dir.glob("*"))) if instructor_dir.exists() else 0
        return file_count > 0, f"instructor files={file_count}"

    if check_id == "syft_available":
        path = shutil.which("syft")
        return path is not None, f"syft={path or 'not found'}"

    if check_id == "jq_available":
        path = shutil.which("jq")
        return path is not None, f"jq={path or 'not found'}"

    if check_id == "compat_symlink_present":
        if compat_symlink.is_symlink():
            resolved = compat_symlink.resolve()
            return resolved == lab_dir.resolve(), f"{compat_symlink} -> {resolved}"
        return False, f"{compat_symlink} is missing or not a symlink"

    if check_id == "official_validator_passes":
        if skip_validator:
            return False, "validator skipped by flag"
        validator = bundle_dir / "validate-module1-offline.sh"
        if not validator.exists():
            return False, f"missing validator: {validator}"
        env = os.environ.copy()
        env["PATH"] = f"/usr/local/bin:{Path.home() / '.local/bin'}:{env.get('PATH', '')}"
        result = subprocess.run(
            ["bash", str(validator), "--lab-dir", str(lab_dir)],
            capture_output=True,
            text=True,
            env=env,
        )
        detail = (result.stdout + "\n" + result.stderr).strip().splitlines()
        summary = detail[-1] if detail else f"exit={result.returncode}"
        return result.returncode == 0, summary

    return False, "unknown check"


def render_markdown(report: dict[str, Any]) -> str:
    lines = [
        "# SBOM Module 1 Score",
        "",
        f"- Generated at: `{report['generated_at']}`",
        f"- Score: `{report['score']}/{report['max_score']}`",
        f"- Status: `{report['status']}`",
        "",
        "| Check | Result | Points | Detail |",
        "|---|---|---:|---|",
    ]
    for check in report["checks"]:
        result = "PASS" if check["passed"] else "FAIL"
        lines.append(
            f"| {check['label']} | {result} | {check['points_awarded']}/{check['points_possible']} | {check['detail']} |"
        )
    return "\n".join(lines) + "\n"


def main() -> int:
    args = parse_args()
    bundle_dir = Path(args.bundle_source_dir).expanduser().resolve()
    lab_dir = Path(args.lab_dir).expanduser()
    compat_symlink = Path(args.compat_symlink).expanduser()
    weights = load_weights(Path(args.weights))

    results = []
    score = 0
    max_score = 0
    for item in weights:
        max_score += item["points"]
        passed, detail = run_check(
            item["id"],
            bundle_dir=bundle_dir,
            lab_dir=lab_dir,
            compat_symlink=compat_symlink,
            skip_validator=args.skip_validator,
        )
        awarded = item["points"] if passed else 0
        score += awarded
        results.append(
            {
                "id": item["id"],
                "label": item["label"],
                "passed": passed,
                "detail": detail,
                "points_awarded": awarded,
                "points_possible": item["points"],
            }
        )

    if score == max_score:
        status = "ready"
    elif score >= max_score * 0.6:
        status = "partial"
    else:
        status = "not_ready"

    report = {
        "generated_at": datetime.now(timezone.utc).replace(microsecond=0).isoformat(),
        "module": "SBOM Training Module 1",
        "score": score,
        "max_score": max_score,
        "status": status,
        "bundle_source_dir": str(bundle_dir),
        "lab_dir": str(lab_dir),
        "checks": results,
    }

    REPORT_JSON.parent.mkdir(parents=True, exist_ok=True)
    REPORT_JSON.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    REPORT_MD.write_text(render_markdown(report), encoding="utf-8")

    print(f"SBOM Module 1 score: {score}/{max_score} ({status})")
    for check in results:
        marker = "PASS" if check["passed"] else "FAIL"
        print(f"- {marker}: {check['label']} [{check['points_awarded']}/{check['points_possible']}] - {check['detail']}")
    print(f"JSON report: {REPORT_JSON}")
    print(f"Markdown report: {REPORT_MD}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
