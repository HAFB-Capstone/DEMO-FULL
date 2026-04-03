from __future__ import annotations

import json
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[2]


def _load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def load_raw_events(filename: str) -> list[dict[str, Any]]:
    return _load_json(REPO_ROOT / "data" / "raw" / filename)


def load_demo_scenario() -> dict[str, Any]:
    return _load_json(REPO_ROOT / "data" / "scenarios" / "demo_scenario.json")


def load_service_catalog() -> list[dict[str, Any]]:
    return _load_json(REPO_ROOT / "config" / "services.json")


def load_scoring_rules() -> dict[str, Any]:
    return _load_json(REPO_ROOT / "config" / "scoring_rules.json")


def load_availability_targets() -> list[dict[str, Any]]:
    return _load_json(REPO_ROOT / "config" / "availability_targets.json")
