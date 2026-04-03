from __future__ import annotations

from collections import Counter
from copy import deepcopy
from datetime import datetime, timezone
from typing import Any, Optional


def compute_dashboard_state(
    raw_events: list[dict[str, Any]],
    normalized_events: list[dict[str, Any]],
    services: list[dict[str, Any]],
    activity_feed: list[dict[str, Any]],
    score_history: list[dict[str, Any]],
    rules: dict[str, Any],
    timeline_label: Optional[str],
    simulation: dict[str, Any],
) -> dict[str, Any]:
    incident_state = latest_incident_state(normalized_events)
    score = compute_score(incident_state, services, rules)
    updated_history = update_score_history(score_history, score, timeline_label)
    severity_counts = Counter(event["severity"] for event in normalized_events)
    agent_counts = Counter(event["agent_name"] for event in normalized_events)
    service_counts = Counter(service["status"] for service in services)
    open_incidents = [
        incident
        for incident in incident_state.values()
        if incident["status"] in {"open", "investigating"}
    ]
    resolved_incidents = [
        incident
        for incident in incident_state.values()
        if incident["status"] in {"contained", "resolved", "remediated"}
    ]
    successful_checks = sum(1 for service in services if service["status"] == "healthy")
    failed_checks = sum(1 for service in services if service["status"] != "healthy")
    mission_status = derive_mission_status(score, failed_checks)
    top_host = agent_counts.most_common(1)[0][0] if agent_counts else "n/a"
    trend = build_trend(updated_history)
    current_time = datetime.now(tz=timezone.utc).replace(microsecond=0).isoformat()

    return {
        "generated_at": current_time,
        "score": score,
        "mission_status": mission_status,
        "summary_cards": {
            "total_alerts": len(normalized_events),
            "high_severity_alerts": severity_counts["high"] + severity_counts["critical"],
            "open_incidents": len(open_incidents),
            "resolved_incidents": len(resolved_incidents),
            "healthy_services": service_counts["healthy"],
            "failed_checks": failed_checks,
        },
        "severity_counts": {
            "critical": severity_counts["critical"],
            "high": severity_counts["high"],
            "medium": severity_counts["medium"],
            "low": severity_counts["low"],
        },
        "services": deepcopy(services),
        "checks": {
            "successful": successful_checks,
            "failed": failed_checks,
        },
        "recent_activity": sorted(activity_feed, key=lambda item: item["timestamp"], reverse=True)[:10],
        "trend": trend,
        "score_history": updated_history,
        "normalized_summary": {
            "raw_records_ingested": len(raw_events),
            "normalized_records": len(normalized_events),
            "unique_agents": len(agent_counts),
            "top_noisy_host": top_host,
            "active_incidents": len(open_incidents),
            "resolved_or_contained": len(resolved_incidents),
        },
        "incident_state": sorted(
            incident_state.values(),
            key=lambda item: (item["severity_rank"], item["timestamp"]),
            reverse=True,
        )[:8],
        "simulation": deepcopy(simulation),
    }


def latest_incident_state(events: list[dict[str, Any]]) -> dict[str, dict[str, Any]]:
    latest: dict[str, dict[str, Any]] = {}
    for event in sorted(events, key=lambda item: item["timestamp"]):
        latest[event["incident_key"]] = event
    return latest


def compute_score(
    incident_state: dict[str, dict[str, Any]], services: list[dict[str, Any]], rules: dict[str, Any]
) -> int:
    score = rules["score_ceiling"]
    for incident in incident_state.values():
        impact = rules["severity_impacts"][incident["severity"]]
        if incident["status"] in {"open", "investigating"}:
            score -= impact
        elif incident["status"] == "contained":
            score -= max(2, impact // 3)

    for service in services:
        score -= rules["service_penalties"][service["status"]]

    return max(rules["score_floor"], min(rules["score_ceiling"], score))


def update_score_history(
    history: list[dict[str, Any]], score: int, timeline_label: Optional[str]
) -> list[dict[str, Any]]:
    updated = list(history)
    if timeline_label:
        updated.append(
            {
                "label": timeline_label,
                "score": score,
                "timestamp": datetime.now(tz=timezone.utc).replace(microsecond=0).isoformat(),
            }
        )
    if not updated:
        updated.append(
            {
                "label": "Baseline Operating Picture",
                "score": score,
                "timestamp": datetime.now(tz=timezone.utc).replace(microsecond=0).isoformat(),
            }
        )
    return updated[-10:]


def build_trend(score_history: list[dict[str, Any]]) -> list[dict[str, Any]]:
    trend = []
    for item in score_history[-6:]:
        trend.append(
            {
                "label": item["label"],
                "score": item["score"],
                "height": max(18, item["score"]),
            }
        )
    return trend


def derive_mission_status(score: int, failed_checks: int) -> dict[str, str]:
    if score >= 90 and failed_checks == 0:
        return {
            "label": "Nominal",
            "detail": "Mission services and telemetry are stable. Scoring VM sees no significant operational degradation.",
        }
    if score >= 75:
        return {
            "label": "Degraded",
            "detail": "Mission impact is limited, but service or security conditions require active blue-team response.",
        }
    return {
        "label": "Incident Response",
        "detail": "Multiple scoring penalties are active. Operators should treat the environment as degraded until containment completes.",
    }
