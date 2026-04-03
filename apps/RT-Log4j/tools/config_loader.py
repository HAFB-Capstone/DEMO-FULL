"""
config_loader.py — shared utility for all RT-template tools.
Loads target.yaml and provides a clean config object.

Usage:
    from config_loader import load_config
    cfg = load_config()
    print(cfg.base_url)
"""

import os
import sys
import yaml
from pathlib import Path
from dataclasses import dataclass


def _find_repo_root() -> Path:
    candidate = Path(__file__).resolve().parent
    for _ in range(4):
        if (candidate / "config" / "target.yaml").exists():
            return candidate
        candidate = candidate.parent
    candidate = Path.cwd()
    for _ in range(4):
        if (candidate / "config" / "target.yaml").exists():
            return candidate
        candidate = candidate.parent
    return Path(__file__).resolve().parents[2]


REPO_ROOT = _find_repo_root()
CONFIG_PATH = REPO_ROOT / "config" / "target.yaml"


@dataclass
class TargetConfig:
    host: str
    attacker_host: str
    attacker_port: int


def load_config(config_path: Path = CONFIG_PATH) -> TargetConfig:
    if not config_path.exists():
        print(f"[!] Config not found at {config_path}")
        sys.exit(1)

    with open(config_path) as f:
        raw = yaml.safe_load(f)

    host = os.environ.get("TARGET_HOST", raw["target"]["host"])

    return TargetConfig(
        host=host,
        attacker_host=os.environ.get("ATTACKER_HOST", raw["attacker"]["host"]),
        attacker_port=int(os.environ.get("ATTACKER_PORT", raw["attacker"]["port"])),
    )
