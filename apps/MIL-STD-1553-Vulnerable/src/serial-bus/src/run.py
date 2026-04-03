#!/usr/bin/env python3
"""
run.py — shell-free entrypoint wrapper for serial-bus.

Tees stdout/stderr to /logs/serial_bus.log without requiring sh or bash.
sh and bash are intentionally removed from this image as a CTF hardening
measure, so the compose entrypoint cannot use `sh -c ... | tee`. This
wrapper replicates that behaviour entirely in Python.
"""

import os
import runpy
import sys

LOG_PATH = "/logs/serial_bus.log"


class _Tee:
    """Multiplex writes to multiple file-like objects simultaneously."""

    def __init__(self, *streams):
        self.streams = streams

    def write(self, data):
        for s in self.streams:
            s.write(data)

    def flush(self):
        for s in self.streams:
            s.flush()

    def fileno(self):
        # Return the underlying fd for subprocess / os-level compat.
        return self.streams[0].fileno()


def main():
    os.makedirs("/logs", exist_ok=True)
    log_file = open(LOG_PATH, "a", buffering=1)  # line-buffered

    sys.stdout = _Tee(sys.__stdout__, log_file)
    sys.stderr = _Tee(sys.__stderr__, log_file)

    # Run src/main.py as __main__ so its `if __name__ == "__main__"` block fires.
    sys.path.insert(0, "/app/src")
    runpy.run_path("/app/src/main.py", run_name="__main__")


if __name__ == "__main__":
    main()
