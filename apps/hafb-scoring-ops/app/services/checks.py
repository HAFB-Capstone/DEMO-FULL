from __future__ import annotations

from copy import deepcopy


def bootstrap_services(service_catalog: list[dict], checked_at: str) -> list[dict]:
    services = deepcopy(service_catalog)
    for service in services:
        service["last_checked_at"] = checked_at
    return services


def apply_service_updates(services: list[dict], updates: list[dict], checked_at: str) -> None:
    service_map = {service["id"]: service for service in services}
    for update in updates:
        service = service_map.get(update["id"])
        if service is None:
            continue
        service.update(update)
        service["last_checked_at"] = checked_at

