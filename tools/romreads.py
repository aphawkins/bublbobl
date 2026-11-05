"""Log which ROM bytes the main CPU reads as data, and from where, in every traced scenario.

Usage: python tools/romreads.py [RUN...] [--jobs N]

Replays each run in build/traces/ (or the RUNs named) without the debugger, using the inputs and
cheats in its trace_run.lua, and writes build/romreads/<run>.csv through tools/romreads.lua.
tools/mainptrs.py reads the logs: they say which page an operand means, and which data holds
pointers. A log that exists is kept, so an interrupted pass can carry on.
"""

import argparse
import concurrent.futures
import subprocess
import sys

import romset
import trace

ROOT = romset.ROOT
RUNS = ROOT / "build" / "traces"
OUT = ROOT / "build" / "romreads"


def replay(run: str) -> str:
    target = OUT / f"{run}.csv"
    if target.exists():
        return f"{run}: kept"
    folder = OUT / "work" / run
    folder.mkdir(parents=True, exist_ok=True)
    head = (RUNS / run / "trace_run.lua").read_text(encoding="utf-8").split("\n", 1)[0]
    if "events={}" in head and not (RUNS / run / "cfg").exists() and run not in ("attract",):
        return f"{run}: no inputs saved"
    part = folder / "reads.csv"
    script = folder / "run.lua"
    script.write_text(head + f'\nCFG.reads_out = "{part.as_posix()}"\n\n'
                      + (ROOT / "tools" / "cheats.lua").read_text() + "\n"
                      + (ROOT / "tools" / "romreads.lua").read_text(), encoding="utf-8")
    exe = trace.mame_exe()
    rompath = ROOT / "build" / "roms"
    cfg = RUNS / run / "cfg"
    argv = [str(exe), "bublbobl", "-rompath", str(rompath), "-skip_gameinfo",
            "-cfg_directory", str(cfg if cfg.exists() else folder / "cfg"),
            "-nvram_directory", str(folder / "nvram"), "-autoboot_script", str(script),
            "-video", "none", "-sound", "none", "-nothrottle"]
    result = subprocess.run(argv, cwd=exe.parent, capture_output=True, text=True)
    (folder / "mame.log").write_text(result.stdout + result.stderr)
    if not part.exists():
        return f"{run}: FAILED, see {folder / 'mame.log'}"
    part.replace(target)
    return f"{run}: done"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("runs", nargs="*")
    ap.add_argument("--jobs", type=int, default=6)
    args = ap.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    runs = args.runs or sorted(p.parent.name for p in RUNS.glob("*/trace_run.lua"))
    with concurrent.futures.ThreadPoolExecutor(args.jobs) as pool:
        for line in pool.map(replay, runs):
            print(line, flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
