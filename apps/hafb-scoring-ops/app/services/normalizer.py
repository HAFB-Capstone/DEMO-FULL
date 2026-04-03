from __future__ import annotations

from typing import Any


SEVERITY_LABELS = {
    "low": "Low",
    "medium": "Medium",
    "high": "High",
    "critical": "Critical",
}

SEVERITY_RANK = {
    "low": 1,
    "medium": 2,
    "high": 3,
    "critical": 4,
}

STATUS_MAP = {
    "open": "open",
    "investigating": "investigating",
    "contained": "contained",
    "resolved": "resolved",
    "remediated": "remediated",
    "observed": "observed",
}


def normalize_records(records: list[dict[str, Any]], rules: dict[str, Any]) -> list[dict[str, Any]]:
    return [normalize_record(record, rules) for record in records]


def normalize_record(record: dict[str, Any], rules: dict[str, Any]) -> dict[str, Any]:
    data = record.get("data", {})
    rule = record.get("rule", {})
    agent = record.get("agent", {})
    level = int(rule.get("level", 0))
    severity = severity_from_level(level)
    status = STATUS_MAP.get(data.get("action", "open"), "open")
    service = infer_service(rule.get("groups", []), data.get("service", ""))
    category = infer_category(rule.get("groups", []), service)
    incident_key = data.get("incident_key") or f"{service}:{agent.get('id', 'unknown')}:{rule.get('id', '0')}"
    score_weight = rules["severity_impacts"][severity]
    if status in {"resolved", "remediated"}:
        score_delta = min(rules["resolved_bonus"], max(2, score_weight // 2))
    elif status == "contained":
        score_delta = -max(2, score_weight // 3)
    elif status == "observed":
        score_delta = 0
    else:
        score_delta = -score_weight

    return {
        "event_id": record["id"],
        "timestamp": record["timestamp"],
        "source": "wazuh",
        "incident_key": incident_key,
        "rule_id": str(rule.get("id", "0")),
        "rule_description": rule.get("description", "Unknown rule"),
        "severity": severity,
        "severity_label": SEVERITY_LABELS[severity],
        "severity_rank": SEVERITY_RANK[severity],
        "status": status,
        "category": category,
        "service": service,
        "agent_id": str(agent.get("id", "unknown")),
        "agent_name": agent.get("name", "unknown-agent"),
        "host": data.get("hostname") or agent.get("name", "unknown-host"),
        "message": record.get("full_log") or rule.get("description", "No message provided"),
        "tags": rule.get("groups", []),
        "location": record.get("location", "unknown"),
        "score_delta": score_delta,
    }


def severity_from_level(level: int) -> str:
    if level >= 11:
        return "critical"
    if level >= 7:
        return "high"
    if level >= 4:
        return "medium"
    return "low"


def infer_service(groups: list[str], raw_service: str) -> str:
    service = raw_service.lower()
    if service in {"web", "dns", "siem", "wazuh", "endpoint", "module1", "controlplane"}:
        return service
    group_text = " ".join(groups).lower()
    if "module1" in group_text or "sbom" in group_text:
        return "module1"
    if "controlplane" in group_text or "ansible" in group_text or "controller" in group_text:
        return "controlplane"
    if "dns" in group_text:
        return "dns"
    if "sysmon" in group_text or "powershell" in group_text or "endpoint" in group_text:
        return "endpoint"
    if "agent" in group_text or "wazuh" in group_text:
        return "wazuh"
    if "web" in group_text or "apache" in group_text or "http" in group_text:
        return "web"
    return "siem"


def infer_category(groups: list[str], service: str) -> str:
    group_text = " ".join(groups).lower()
    if service == "controlplane":
        return "control-plane"
    if service == "module1":
        return "training-module"
    if service == "endpoint":
        return "endpoint"
    if service == "dns":
        return "network"
    if service == "web":
        return "mission-service"
    if service == "wazuh":
        return "telemetry"
    if "authentication" in group_text or "ssh" in group_text:
        return "identity"
    return "detection"
