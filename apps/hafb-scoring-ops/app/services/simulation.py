from __future__ import annotations

import time


def run_demo_scenario(store) -> None:
    scenario = store.demo_scenario
    steps = scenario["steps"]
    total_steps = len(steps)

    for index, step in enumerate(steps, start=1):
        time.sleep(step.get("delay_seconds", scenario.get("default_delay_seconds", 6)))
        store.apply_step(index, total_steps, step)

    time.sleep(3)
    store.finish_simulation()

