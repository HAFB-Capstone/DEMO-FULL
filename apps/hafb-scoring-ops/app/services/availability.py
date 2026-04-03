from __future__ import annotations

from time import perf_counter
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


DEMO_SCENARIOS: list[dict[str, Any]] = [
    {
        "label": "Demo baseline",
        "checks": {
            "log4j-auth-health": {"http_status": 200, "latency_ms": 28},
            "log4j-inventory-health": {"http_status": 200, "latency_ms": 31},
            "log4j-status-health": {"http_status": 200, "latency_ms": 19},
            "mil-logistics-root": {"http_status": 200, "latency_ms": 24},
        },
    },
    {
        "label": "Log4j auth degraded",
        "checks": {
            "log4j-auth-health": {"http_status": 503, "latency_ms": 145},
            "log4j-inventory-health": {"http_status": 200, "latency_ms": 29},
            "log4j-status-health": {"http_status": 200, "latency_ms": 21},
            "mil-logistics-root": {"http_status": 200, "latency_ms": 22},
        },
    },
    {
        "label": "MIL portal unavailable",
        "checks": {
            "log4j-auth-health": {"http_status": 200, "latency_ms": 32},
            "log4j-inventory-health": {"http_status": 200, "latency_ms": 27},
            "log4j-status-health": {"http_status": 200, "latency_ms": 20},
            "mil-logistics-root": {"error": "Connection timed out"},
        },
    },
    {
        "label": "Partial recovery",
        "checks": {
            "log4j-auth-health": {"http_status": 200, "latency_ms": 30},
            "log4j-inventory-health": {"http_status": 500, "latency_ms": 102},
            "log4j-status-health": {"http_status": 200, "latency_ms": 18},
            "mil-logistics-root": {"http_status": 200, "latency_ms": 26},
        },
    },
]


def probe_targets(targets: list[dict[str, Any]], timeout_seconds: float = 2.5) -> list[dict[str, Any]]:
    families = []
    for family in targets:
        checks = [_probe_check(check, timeout_seconds) for check in family["checks"]]
        families.append(_family_result(family["name"], checks))
    return families


def demo_targets(targets: list[dict[str, Any]], step_index: int) -> tuple[str, list[dict[str, Any]]]:
    scenario = DEMO_SCENARIOS[step_index % len(DEMO_SCENARIOS)]
    overrides = scenario["checks"]
    families = []

    for family in targets:
        checks = []
        for check in family["checks"]:
            override = overrides.get(check["id"], {})
            http_status = override.get("http_status")
            checks.append(
                {
                    "id": check["id"],
                    "name": check["name"],
                    "url": check["url"],
                    "http_status": http_status,
                    "latency_ms": override.get("latency_ms"),
                    "status": "healthy" if http_status == 200 else "unhealthy",
                    "detail": "HTTP 200 OK" if http_status == 200 else override.get("error", f"HTTP {http_status}"),
                }
            )
        families.append(_family_result(family["name"], checks))

    return scenario["label"], families


def _probe_check(check: dict[str, Any], timeout_seconds: float) -> dict[str, Any]:
    request = Request(check["url"], method="GET")
    started = perf_counter()
    try:
        with urlopen(request, timeout=timeout_seconds) as response:
            latency_ms = round((perf_counter() - started) * 1000)
            http_status = response.getcode()
            return {
                "id": check["id"],
                "name": check["name"],
                "url": check["url"],
                "http_status": http_status,
                "latency_ms": latency_ms,
                "status": "healthy" if http_status == 200 else "unhealthy",
                "detail": "HTTP 200 OK" if http_status == 200 else f"HTTP {http_status}",
            }
    except HTTPError as exc:
        latency_ms = round((perf_counter() - started) * 1000)
        return {
            "id": check["id"],
            "name": check["name"],
            "url": check["url"],
            "http_status": exc.code,
            "latency_ms": latency_ms,
            "status": "unhealthy",
            "detail": f"HTTP {exc.code}",
        }
    except URLError as exc:
        return {
            "id": check["id"],
            "name": check["name"],
            "url": check["url"],
            "http_status": None,
            "latency_ms": None,
            "status": "unhealthy",
            "detail": str(exc.reason),
        }
    except Exception as exc:  # noqa: BLE001
        return {
            "id": check["id"],
            "name": check["name"],
            "url": check["url"],
            "http_status": None,
            "latency_ms": None,
            "status": "unhealthy",
            "detail": str(exc),
        }


def _family_result(name: str, checks: list[dict[str, Any]]) -> dict[str, Any]:
    total = len(checks)
    healthy = sum(1 for check in checks if check["status"] == "healthy")
    family_score = round((healthy / total) * 100) if total else 0
    if healthy == total:
        status = "healthy"
    elif healthy == 0:
        status = "unhealthy"
    else:
        status = "degraded"

    return {
        "name": name,
        "status": status,
        "healthy_checks": healthy,
        "total_checks": total,
        "score": family_score,
        "detail": f"{healthy} of {total} endpoints returned HTTP 200.",
        "checks": checks,
    }
