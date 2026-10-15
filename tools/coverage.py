"""Merge MAME trace coverage into the byte classification maps.

Usage: python tools/coverage.py [--roms DIR] [--dry-run]

Reads every build/traces/<scenario>/coverage.json written by trace.py. Each executed
instruction marks its bytes as code. New code bytes go into notes/classmap/<image>.toml as
source = "trace" ranges, merged with the trace ranges already there, so coverage builds up
over many runs. Bytes already in a manual code range are left to that range. A traced
byte inside a manual data or text range is a conflict: it is reported and not written.
"""

import argparse
import json
import sys
from pathlib import Path

import classify
import romset

TRACE_DIR = romset.ROOT / "build" / "traces"

# Z80 instruction lengths, unprefixed.
BASE = [1] * 256
for op in (0x06, 0x0E, 0x16, 0x1E, 0x26, 0x2E, 0x36, 0x3E,  # ld r,n
           0xC6, 0xCE, 0xD6, 0xDE, 0xE6, 0xEE, 0xF6, 0xFE,  # alu n
           0x10, 0x18, 0x20, 0x28, 0x30, 0x38,              # djnz, jr
           0xD3, 0xDB, 0xCB):                               # out (n),a / in a,(n) / CB xx
    BASE[op] = 2
for op in (0x01, 0x11, 0x21, 0x31, 0x22, 0x2A, 0x32, 0x3A,
           0xC2, 0xC3, 0xCA, 0xD2, 0xDA, 0xE2, 0xEA, 0xF2, 0xFA,
           0xC4, 0xCC, 0xCD, 0xD4, 0xDC, 0xE4, 0xEC, 0xF4, 0xFC):
    BASE[op] = 3
ED_NN = {0x43, 0x4B, 0x53, 0x5B, 0x63, 0x6B, 0x73, 0x7B}  # ld (nn),rr / ld rr,(nn)
# Opcodes with an (hl) operand: after DD/FD they take a displacement byte.
HL_INDIRECT = {0x34, 0x35, 0x36, 0x46, 0x4E, 0x56, 0x5E, 0x66, 0x6E, 0x7E,
               0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x77,
               0x86, 0x8E, 0x96, 0x9E, 0xA6, 0xAE, 0xB6, 0xBE}


def z80_length(code: bytes, i: int) -> int:
    def at(k: int) -> int:
        return code[k] if k < len(code) else 0

    op = at(i)
    if op == 0xED:
        return 4 if at(i + 1) in ED_NN else 2
    if op in (0xDD, 0xFD):
        op2 = at(i + 1)
        if op2 == 0xCB:
            return 4
        if op2 in (0xDD, 0xFD, 0xED):
            return 1  # a prefix that only delays the next one
        return 1 + BASE[op2] + (op2 in HL_INDIRECT)
    return BASE[op]


def load_coverage() -> tuple[dict[str, set[int]], list[str]]:
    pcs: dict[str, set[int]] = {}
    runs = []
    for path in sorted(TRACE_DIR.glob("*/coverage.json")):
        runs.append(path.parent.name)
        for image, addrs in json.loads(path.read_text()).items():
            pcs.setdefault(image, set()).update(int(a, 16) for a in addrs)
    return pcs, runs


def to_ranges(addrs: set[int]) -> list[tuple[int, int]]:
    out = []
    for a in sorted(addrs):
        if out and a == out[-1][1] + 1:
            out[-1][1] = a
        else:
            out.append([a, a])
    return [tuple(r) for r in out]


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--roms", type=Path, help="ROM directory or zip")
    ap.add_argument("--dry-run", action="store_true", help="report only, change no map")
    args = ap.parse_args()
    try:
        imgs = romset.images(romset.load(args.roms))
    except romset.RomError as e:
        print(e, file=sys.stderr)
        return 1
    pcs, runs = load_coverage()
    if not runs:
        print("no coverage: run tools/trace.py first", file=sys.stderr)
        return 1
    print("runs: " + ", ".join(runs))
    if "main_bank_unknown" in pcs:
        print(f"skipped {len(pcs.pop('main_bank_unknown'))} bank-window addresses "
              "executed before the first bank write")

    for image, data in imgs.items():
        stem = Path(image).stem
        base = romset.IMAGES[image][3]
        path = classify.MAP_DIR / f"{stem}.toml"
        ranges = classify.read_map(path)
        z80 = stem != "mcu"

        traced = set()
        for pc in pcs.get(stem, ()):
            i = pc - base
            if not 0 <= i < len(data):
                print(f"{stem}: {pc:04X} is outside the image", file=sys.stderr)
                continue
            n = z80_length(data, i) if z80 else 1  # MCU: check the opcode byte only
            traced.update(range(pc, min(pc + n, base + len(data))))
        for r in ranges:
            if r["source"] == "trace":
                traced.update(range(r["start"], r["end"] + 1))

        kept = [r for r in ranges if r["source"] not in ("auto", "trace")]
        manual_code = set()
        conflicts = []
        for r in kept:
            span = set(range(r["start"], r["end"] + 1))
            hit = span & traced
            if not hit:
                continue
            if r["kind"] == "code":
                manual_code |= hit
            else:
                conflicts.append((r, min(hit)))
                traced -= hit
        new = traced - manual_code
        trace_ranges = [classify.rng(a, b, "code", "executed in MAME", "trace")
                        for a, b in to_ranges(new)]
        auto = [r for r in ranges if r["source"] == "auto"
                and not any(classify.overlaps(r, t) for t in trace_ranges)]
        dropped = sum(1 for r in ranges if r["source"] == "auto") - len(auto)

        code, known = set(new), set(new)
        for r in kept + auto:
            span = range(r["start"], r["end"] + 1)
            known.update(span)
            if r["kind"] == "code":
                code.update(span)
        print(f"{stem:11} traced {len(traced | manual_code):#7x}  code {len(code):#7x}  "
              f"unknown {len(data) - len(known):#7x}"
              + (f"  ({dropped} auto ranges replaced)" if dropped else ""))
        for r, a in conflicts:
            print(f"  conflict: {a:04X} executed, but {r['start']:04X}-{r['end']:04X} is "
                  f"{r['source']} {r['kind']} ({r.get('note', '')})")
        if not args.dry_run and z80:
            classify.write_map(path, image, kept + trace_ranges + auto)
    return 0


if __name__ == "__main__":
    sys.exit(main())
