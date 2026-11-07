"""Regenerate build/ from the ROMs: every result that needs nothing but the set and this repo.

Usage: python tools/extract_all.py [--roms DIR]

DIR is a ROM directory or zip, by default as for romset.py. The set is verified first, and the
run stops at the first step that fails. Each step is the tool on its own, in this order because
text.py reads the listings build.py writes and the sound tools read build/images.

sounddec.py also writes notes/sound_blocks.md, which is in the repo: the same ROMs make the same
file, so a difference there is a change to the decoder.

Sprite sheets come from traces, so they are remade only if build/traces has some. The traces,
snapshots and other MAME runs (trace.py, frameorder.py, soundcmp.py, romreads.py, reloc.py) take
hours and are not part of this.
"""

import argparse
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BUILD = ROOT / "build"

# tool, then whether it takes --roms
STEPS = [("romset", True), ("build", True), ("gfx", True), ("palette", True), ("levels", True),
         ("text", True), ("sounddec", False), ("soundtables", False)]


def run(tool: str, args: list[str]) -> bool:
    print(f"--- {tool}", flush=True)
    return subprocess.run([sys.executable, str(ROOT / "tools" / f"{tool}.py"), *args], cwd=ROOT).returncode == 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--roms", type=Path, help="ROM directory or zip")
    args = ap.parse_args()
    roms = ["--roms", str(args.roms.resolve())] if args.roms else []

    steps = list(STEPS)
    if any(BUILD.glob("traces/*/sprites.csv")):
        steps.append(("sprites", True))
    else:
        print("No sprites.csv in build/traces: skipping the sprite sheets (see trace.py)")
    for tool, takes_roms in steps:
        if not run(tool, roms if takes_roms else []):
            print(f"Stopped: {tool}.py failed", file=sys.stderr)
            return 1
    print(f"Done: {', '.join(tool for tool, _ in steps)}. Results in {BUILD}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
