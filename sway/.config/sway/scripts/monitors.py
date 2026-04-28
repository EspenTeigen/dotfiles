#!/usr/bin/env python3
"""Auto-arrange sway outputs based on what is currently connected.

Home: AOC monitor on the left holds workspaces 1-5, Samsung on the right
holds 6-10, laptop panel disabled. Anything else (single external, laptop
only) is left to sway defaults — at the office only one external is ever
plugged in, so an AOC+Samsung pair uniquely identifies the home setup.

Daemon: applies once at startup, then re-applies on every sway output
event (hot-plug, resolution change). Started from the sway config via
`exec_always`; uses a pidfile so reload kills the previous instance.
"""

from __future__ import annotations

import json
import os
import signal
import subprocess
import sys
from pathlib import Path

LAPTOP = "eDP-1"
LEFT_MAKE = "AOC"
RIGHT_MAKE = "SAMSUNG"
LEFT_WS = range(1, 6)
RIGHT_WS = range(6, 11)
PIDFILE = Path.home() / ".cache" / "sway-monitors.pid"


def sway(cmd: str) -> None:
    subprocess.run(
        ["swaymsg", "--", cmd],
        capture_output=True,
        text=True,
        check=False,
    )


def get_outputs() -> list[dict]:
    r = subprocess.run(
        ["swaymsg", "-t", "get_outputs", "-r"],
        capture_output=True,
        text=True,
        check=True,
    )
    return json.loads(r.stdout)


def find_make(outputs: list[dict], prefix: str) -> dict | None:
    p = prefix.upper()
    for o in outputs:
        if (o.get("make") or "").upper().startswith(p):
            return o
    return None


def width_of(o: dict) -> int:
    rect = o.get("rect") or {}
    if rect.get("width"):
        return rect["width"]
    modes = o.get("modes") or []
    if modes:
        return max(modes, key=lambda m: m["width"] * m["height"])["width"]
    return 1920


def apply() -> None:
    outs = get_outputs()
    left = find_make(outs, LEFT_MAKE)
    right = find_make(outs, RIGHT_MAKE)
    if not (left and right):
        return

    left_name = left["name"]
    right_name = right["name"]
    left_w = width_of(left)

    sway(f"output {left_name} enable position 0 0")
    sway(f"output {right_name} enable position {left_w} 0")
    sway(f"output {LAPTOP} disable")

    for n in LEFT_WS:
        sway(f"workspace {n} output {left_name}")
    for n in RIGHT_WS:
        sway(f"workspace {n} output {right_name}")

    # Pinning only steers new workspaces; relocate existing ones too.
    for n in LEFT_WS:
        sway(f"workspace number {n}; move workspace to output {left_name}")
    for n in RIGHT_WS:
        sway(f"workspace number {n}; move workspace to output {right_name}")

    sway("workspace number 1")


def claim_pidfile() -> None:
    PIDFILE.parent.mkdir(parents=True, exist_ok=True)
    try:
        old = int(PIDFILE.read_text().strip())
    except (FileNotFoundError, ValueError):
        old = 0
    if old and old != os.getpid():
        try:
            os.kill(old, signal.SIGTERM)
        except ProcessLookupError:
            pass
    PIDFILE.write_text(str(os.getpid()))


def main() -> int:
    claim_pidfile()

    try:
        apply()
    except Exception as e:
        print(f"monitors: initial apply failed: {e}", file=sys.stderr)

    proc = subprocess.Popen(
        ["swaymsg", "-t", "subscribe", "-m", '["output"]'],
        stdout=subprocess.PIPE,
        text=True,
    )

    def stop(*_):
        proc.terminate()
        sys.exit(0)

    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)

    assert proc.stdout is not None
    for _ in proc.stdout:
        try:
            apply()
        except Exception as e:
            print(f"monitors: apply failed: {e}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
