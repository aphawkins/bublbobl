"""List the main CPU's data that no run has read, and what in it could be a pointer.

Usage: python tools/unread.py [DIR...] [--all]

Reads the logs of tools/romreads.py in build/romreads/ and any .csv under the DIRs named, such as
the reads that `reloc.py --reads` leaves. Then, for each .incbin range of src/main/, it counts the
bytes that were read, leaving out the ROM sums, which read everything by number.

The relocation test can only see a pointer that is read, so what this prints is where a pointer
left as bytes could still hide (notes/relocation.md). A "word" is a pair of unread bytes that gives
the address of a label in that image or the fixed ROM: a pointer would look like that, but so do
many pairs that are not. --all prints every unread stretch, and not only those with words in.
"""

import argparse
import re
import sys
from collections import defaultdict
from pathlib import Path

import romset

ROOT = romset.ROOT
IMAGES = {"fixed": 0x0000, "bank0": 0x8000, "bank1": 0x8000, "bank2": 0x8000, "bank3": 0x8000}
LABEL = re.compile(r"([A-Za-z_]\w*):\s*;\s*([0-9A-F]{4})")
INCBIN = re.compile(r'\s+\.incbin\s+"[^"]+",\s*0x([0-9A-Fa-f]+),\s*0x([0-9A-Fa-f]+)')
SUM_LOOP = re.compile(r"^L_(\w+):.*\n +ld +de,\(0x\w+\)\n +ld +a,\(de\)\n +ld +hl,0x\w+\n +add +a,\(hl\)", re.M)
SUM_LOOP_READ = 4  # as in tools/reloc.py
FILL = (0x00, 0xFF)


def image_of(page: int, addr: int) -> str | None:
    if addr < 0x8000:
        return "fixed"
    return f"bank{page}" if page < 4 else None


def source(image: str) -> str:
    return (ROOT / "src" / "main" / f"{image}.s").read_text(encoding="utf-8")


def labels(image: str) -> dict[int, str]:
    return {int(m[2], 16): m[1] for m in LABEL.finditer(source(image))}


def data_ranges(image: str) -> list[tuple[int, int, str]]:
    """Each .incbin as (address, length, the label before it)."""
    found, name = [], "?"
    for line in source(image).split("\n"):
        if m := LABEL.match(line):
            name = m[1]
        elif m := INCBIN.match(line):
            found.append((int(m[1], 16) + IMAGES[image], int(m[2], 16), name))
    return found


def read_bytes(folders: list[Path]) -> dict[str, set[int]]:
    """Every address read as data in each image, by anything but a ROM sum."""
    sums = {(image, int(a, 16) + SUM_LOOP_READ) for image in IMAGES for a in SUM_LOOP.findall(source(image))}
    seen: dict[str, set[int]] = defaultdict(set)
    logs = [p for folder in folders for p in sorted(folder.rglob("*.csv"))]
    for log in logs:
        for line in log.read_text().split("\n"):
            if line:
                page, addr, pc = line.split(",")
                page, addr, pc = int(page), int(addr, 16), int(pc, 16)
                image = image_of(page, addr)
                if image and (image_of(page, pc), pc) not in sums:
                    seen[image].add(addr)
    print(f"{len(logs)} logs")
    return seen


def stretches(addrs: list[int]) -> list[tuple[int, int]]:
    runs: list[tuple[int, int]] = []
    for a in addrs:
        if runs and a == runs[-1][1] + 1:
            runs[-1] = (runs[-1][0], a)
        else:
            runs.append((a, a))
    return runs


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("folders", nargs="*", type=Path)
    ap.add_argument("--all", action="store_true")
    args = ap.parse_args()
    seen = read_bytes([ROOT / "build" / "romreads", *args.folders])
    fixed_labels = labels("fixed")
    total_words = 0
    for image, base in IMAGES.items():
        rom = (ROOT / "build" / "images" / f"main_{image}.bin").read_bytes()
        targets = fixed_labels | labels(image)
        size = unread = filler = 0
        report = []
        for start, length, name in data_ranges(image):
            size += length
            missing = [a for a in range(start, start + length) if a not in seen[image]]
            real = [a for a in missing if rom[a - base] not in FILL]
            unread += len(real)
            filler += len(missing) - len(real)
            for first, last in stretches(real):
                words = [(a, rom[a - base] | rom[a + 1 - base] << 8) for a in range(first, last)]
                words = [(a, w) for a, w in words if w in targets]
                total_words += len(words)
                if words or args.all:
                    report.append(f"  {first:04X}-{last:04X} after {name}: "
                                  + " ".join(f"{a:04X}->{targets[w]}" for a, w in words))
        print(f"{image}: {size} bytes of .incbin, {size - unread - filler} read, "
              f"{unread} unread, {filler} unread 00 or FF")
        print("\n".join(report))
    print(f"{total_words} unread pairs give a label's address")
    return 0


if __name__ == "__main__":
    sys.exit(main())
