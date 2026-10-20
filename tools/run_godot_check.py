#!/usr/bin/env python3
"""Run one Godot check with bounded time/memory and preserve raw evidence.

Pass Godot arguments after --. Use --require for the test's final summary.
On Windows the console wrapper is replaced with its sibling engine so the
process being monitored/killed is the actual engine, not a detached child.
"""
from __future__ import annotations

import argparse
import ctypes
import re
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def private_memory(process: subprocess.Popen) -> int:
    if not hasattr(process, "_handle"):
        return 0
    from ctypes import wintypes

    class Counters(ctypes.Structure):
        _fields_ = [("cb", wintypes.DWORD), ("faults", wintypes.DWORD)] + [
            (name, ctypes.c_size_t) for name in (
                "peak_working", "working", "peak_paged", "paged",
                "peak_nonpaged", "nonpaged", "pagefile", "peak_pagefile", "private",
            )
        ]

    counters = Counters()
    counters.cb = ctypes.sizeof(counters)
    query = ctypes.windll.psapi.GetProcessMemoryInfo
    query.argtypes = [wintypes.HANDLE, ctypes.c_void_p, wintypes.DWORD]
    query.restype = wintypes.BOOL
    if not query(wintypes.HANDLE(process._handle), ctypes.byref(counters), counters.cb):
        raise ctypes.WinError()
    return counters.private


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot-exe", required=True, type=Path)
    parser.add_argument("--log", required=True, type=Path)
    parser.add_argument("--require", default="")
    parser.add_argument("--timeout", type=float, default=30)
    parser.add_argument("--memory-mb", type=int, default=384)
    parser.add_argument("args", nargs=argparse.REMAINDER)
    options = parser.parse_args()
    if options.timeout <= 0 or options.memory_mb <= 0:
        parser.error("timeout and memory-mb must be positive")
    exe = options.godot_exe.resolve(strict=True)
    if exe.name.endswith("_console.exe"):
        sibling = exe.with_name(exe.name.replace("_console.exe", ".exe"))
        if sibling.is_file():
            exe = sibling
    args = options.args[1:] if options.args[:1] == ["--"] else options.args
    if "--log-file" in args:
        parser.error("the runner manages --log-file to retain UTF-8 engine evidence")
    engine_log = options.log.with_suffix(".engine.log").resolve()
    stdio_log = options.log.with_suffix(".stdio.log")
    command = [str(exe), "--log-file", str(engine_log), *args]
    options.log.parent.mkdir(parents=True, exist_ok=True)
    # Never overwrite an earlier red/green run.
    reason = ""
    peak = 0
    start = time.monotonic()
    if engine_log.exists() or stdio_log.exists():
        parser.error("engine/stdio evidence already exists; choose a new log name")
    with options.log.open("x", encoding="utf-8") as output, stdio_log.open("xb") as stdio:
        output.write(f"COMMAND={command!r}\nCWD={ROOT}\n")
        output.flush()
        process = subprocess.Popen(
            command, cwd=ROOT, stdout=stdio, stderr=subprocess.STDOUT,
            stdin=subprocess.DEVNULL,
            creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0),
        )
        try:
            while process.poll() is None:
                peak = max(peak, private_memory(process))
                if peak > options.memory_mb * 1024 * 1024:
                    reason = "MEMORY_LIMIT"
                    break
                if time.monotonic() - start > options.timeout:
                    reason = "TIMEOUT"
                    break
                time.sleep(0.05)
        finally:
            if process.poll() is None:
                process.kill()
            process.wait()
        # Godot's own file logger is UTF-8; Windows redirected stdout can be GBK.
        engine_text = engine_log.read_text(encoding="utf-8", errors="replace") if engine_log.exists() else ""
        output.write(engine_text)
        output.write(f"\nEXIT={process.returncode} LIMIT={reason or 'NONE'} PEAK_PRIVATE_BYTES={peak}\nSTDIO={stdio_log}\n")
    text = options.log.read_text(encoding="utf-8", errors="replace")
    raw_stdout = stdio_log.read_bytes().decode("utf-8", errors="replace")
    errors = bool(re.search(r"(?m)^(?:SCRIPT ERROR:|ERROR:|FAIL )", text + "\n" + raw_stdout))
    marker = not options.require or re.search(options.require, text) is not None
    ok = process.returncode == 0 and not reason and not errors and marker
    with options.log.open("a", encoding="utf-8") as output:
        output.write(f"HARNESS={'PASS' if ok else 'FAIL'} SUMMARY_FOUND={marker}\n")
    print("\n".join(text.splitlines()[-65:]))
    print(f"HARNESS={'PASS' if ok else 'FAIL'} SUMMARY_FOUND={marker} LOG={options.log}")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
