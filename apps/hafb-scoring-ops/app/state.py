from __future__ import annotations

from copy import deepcopy
from datetime import datetime, timezone
from threading import Event, RLock, Thread
from typing import Any, Optional

from app.services.availability import demo_targets, probe_targets
from app.services.loader import load_availability_targets


class DashboardStore:
    def __init__(self) -> None:
        self._lock = RLock()
        self.targets = load_availability_targets()
        self._stop_event = Event()
        self._worker: Optional[Thread] = None
        self._demo_step = 0
        self._run_id = 0
        self.reset()

    def reset(self) -> None:
        with self._lock:
            self._stop_event.set()
            now = self._now_iso()
            self._demo_step = 0
            self.monitor = {
                "status": "idle",
                "mode": "idle",
                "label": "Awaiting start",
                "started_at": None,
                "stopped_at": None,
                "last_checked_at": None,
                "interval_seconds": 5,
                "elapsed_seconds": 0,
            }
            self.vulnerability_scope = self._pending_scope()
            self._refresh_snapshot(now)

    def snapshot(self) -> dict[str, Any]:
        with self._lock:
            state = deepcopy(self.dashboard_state)

        if state["monitor"]["status"] == "running":
            now = self._now_iso()
            state["generated_at"] = now
            state["monitor"]["elapsed_seconds"] = self._elapsed_seconds(state["monitor"], now)

        return state

    def start_monitor(self, mode: str) -> bool:
        if mode not in {"live", "demo"}:
            return False

        with self._lock:
            if self.monitor["status"] == "running":
                return False

            self._run_id += 1
            run_id = self._run_id
            self._stop_event = Event()
            self._demo_step = 0
            now = self._now_iso()
            self.monitor.update(
                {
                    "status": "running",
                    "mode": mode,
                    "label": "Live monitoring" if mode == "live" else "Demo mode",
                    "started_at": now,
                    "stopped_at": None,
                    "last_checked_at": None,
                    "elapsed_seconds": 0,
                }
            )
            self.vulnerability_scope = self._pending_scope()
            self._refresh_snapshot(now)
            self._worker = Thread(
                target=self._monitor_loop,
                args=(mode, run_id, self._stop_event),
                daemon=True,
            )
            self._worker.start()
            return True

    def stop_monitor(self) -> bool:
        with self._lock:
            if self.monitor["status"] != "running":
                return False

            self._run_id += 1
            now = self._now_iso()
            self._stop_event.set()
            self.monitor.update(
                {
                    "status": "stopped",
                    "label": "Stopped",
                    "stopped_at": now,
                    "elapsed_seconds": self._elapsed_seconds(self.monitor, now),
                }
            )
            self._refresh_snapshot(now)
            return True

    def _monitor_loop(self, mode: str, run_id: int, stop_event: Event) -> None:
        while not stop_event.is_set():
            checked_at = self._now_iso()
            if mode == "live":
                label = "Live monitoring"
                results = probe_targets(self.targets)
            else:
                label, results = demo_targets(self.targets, self._demo_step)
                self._demo_step += 1

            with self._lock:
                if self._run_id != run_id or self.monitor["status"] != "running" or self.monitor["mode"] != mode:
                    return

                self.vulnerability_scope = results
                self.monitor["label"] = label
                self.monitor["last_checked_at"] = checked_at
                self.monitor["elapsed_seconds"] = self._elapsed_seconds(self.monitor, checked_at)
                self._refresh_snapshot(checked_at)

            if stop_event.wait(self.monitor["interval_seconds"]):
                return

    def _pending_scope(self) -> list[dict[str, Any]]:
        families = []
        for family in self.targets:
            checks = [
                {
                    "id": check["id"],
                    "name": check["name"],
                    "url": check["url"],
                    "http_status": None,
                    "latency_ms": None,
                    "status": "pending",
                    "detail": "Awaiting monitor start.",
                }
                for check in family["checks"]
            ]
            families.append(
                {
                    "name": family["name"],
                    "status": "pending",
                    "healthy_checks": 0,
                    "total_checks": len(checks),
                    "score": 0,
                    "detail": "No availability checks have run yet.",
                    "checks": checks,
                }
            )
        return families

    def _refresh_snapshot(self, timestamp: str) -> None:
        score = self._overall_score()
        self.dashboard_state = {
            "generated_at": timestamp,
            "score": score,
            "mission_status": self._mission_status(score),
            "monitor": deepcopy(self.monitor),
            "vulnerability_scope": deepcopy(self.vulnerability_scope),
        }

    def _overall_score(self) -> int:
        if not self.vulnerability_scope:
            return 0
        family_scores = [family["score"] for family in self.vulnerability_scope]
        return round(sum(family_scores) / len(family_scores))

    def _mission_status(self, score: int) -> dict[str, str]:
        if self.monitor["status"] == "idle":
            return {
                "label": "Idle",
                "detail": "Monitoring has not started. Use Start for live checks or Demo to simulate results.",
            }
        if self.monitor["status"] == "stopped":
            return {
                "label": "Stopped",
                "detail": "Monitoring is paused. The score shown is the last recorded result.",
            }
        if score == 100:
            return {
                "label": "Nominal",
                "detail": "All configured endpoints are returning HTTP 200.",
            }
        if score > 0:
            return {
                "label": "Degraded",
                "detail": "Some configured endpoints are unavailable or not returning HTTP 200.",
            }
        return {
            "label": "Incident Response",
            "detail": "No configured endpoints are currently returning HTTP 200.",
        }

    @staticmethod
    def _elapsed_seconds(monitor: dict[str, Any], now: str) -> int:
        started_at = monitor.get("started_at")
        if not started_at:
            return 0

        started = datetime.fromisoformat(started_at)
        if monitor.get("status") == "stopped" and monitor.get("stopped_at"):
            finished = datetime.fromisoformat(monitor["stopped_at"])
        else:
            finished = datetime.fromisoformat(now)
        return max(0, round((finished - started).total_seconds()))

    @staticmethod
    def _now_iso() -> str:
        return datetime.now(tz=timezone.utc).replace(microsecond=0).isoformat()
