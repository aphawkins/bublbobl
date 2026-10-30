"""List the RAM addresses the sources use with no name in notes/symbols.toml.

Usage: python tools/ramgaps.py [--top N]

Counts each 0xNNNN operand in shared RAM (E000-F7FF: main, banks and sub) and in sound RAM
(8000-8FFF) that no name or sized range covers, most used first, with the name just below it
and the names whose notes mention it. Also lists sized ranges that hold later names: a size
that runs into the next name is often a clear count, not the table's size.
"""

import argparse
import collections
import re
import tomllib

import romset

ROOT = romset.ROOT
# whole regions, not tables: they hold every other name
REGIONS = {"SHARED_RAM", "MCU_RAM", "BANK_WINDOW", "RAM"}


def covered(tables: list[dict]) -> set[int]:
    c = set()
    for t in tables:
        for name, v in t.items():
            if name not in REGIONS:
                c.update(range(v["addr"], v["addr"] + v.get("size", 1)))
    return c


def scan(files: list, lo: int, hi: int, names: set[int]) -> dict:
    refs = collections.defaultdict(collections.Counter)
    for f in files:
        for line in f.read_text(encoding="utf-8").splitlines():
            for m in re.finditer(r"\b0x([0-9A-F]{4})\b", line.split(";")[0]):
                a = int(m.group(1), 16)
                if lo <= a < hi and a not in names:
                    refs[a][f.name] += 1
    return refs


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--top", type=int, default=40)
    args = ap.parse_args()
    data = tomllib.loads((ROOT / "notes" / "symbols.toml").read_text(encoding="utf-8"))
    notes = [(n, v.get("note", "")) for kinds in data.values() for t in kinds.values() for n, v in t.items()]

    print("Sized ranges that hold later names:")
    for cpu, kinds in data.items():
        for kind, names in kinds.items():
            items = list(names.items())
            for i, (name, v) in enumerate(items):
                end = v["addr"] + v.get("size", 1)
                inside = [n for n, w in items[i + 1:] if w["addr"] < end]
                if inside and "size" in v and name not in REGIONS:
                    print(f"  [{cpu}.{kind}] {name} {v['addr']:04X}+{v['size']:X}: {', '.join(inside)}")

    src = ROOT / "src"
    for title, files, lo, hi, tables in (
        ("shared RAM E000-F7FF", sorted((src / "main").glob("*.s")) + [src / "sub" / "sub.s"], 0xE000, 0xF800,
         [data["main"]["mem"], data["shared"]["mcu"]]),
        ("sound RAM 8000-8FFF", [src / "sound" / "sound.s"], 0x8000, 0x9000, [data["sound"]["mem"]]),
    ):
        refs = scan(files, lo, hi, covered(tables))
        below = sorted((v["addr"], n) for t in tables for n, v in t.items() if n not in REGIONS)
        print(f"\nUnnamed {title}: {len(refs)} addresses, {sum(sum(c.values()) for c in refs.values())} uses")
        for a, c in sorted(refs.items(), key=lambda x: (-sum(x[1].values()), x[0]))[:args.top]:
            under = [n for b, n in below if b < a]
            said = [n for n, t in notes if f"{a:04X}" in t]
            print(f"  {a:04X} {sum(c.values()):4}  after {under[-1] if under else '-':16} "
                  f"in {', '.join(f'{k} {n}' for k, n in c.most_common())}"
                  + (f"; notes: {', '.join(said[:4])}" if said else ""))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
