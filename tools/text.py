"""Catalogue the text in the main CPU images.

Usage: python tools/text.py [--roms DIR] [--out FILE]

Writes build/text/strings.csv with one row per string:
    image, address, offset, form, length, hint, text
address is the CPU address (`1234` in the fixed ROM, `bank1:9C40` in a bank), offset is
the offset in the ROM file. form is `prefixed` (length byte, then the characters; the
length byte is at address) or `raw` (a run of text characters with no length byte).
hint is `ascending` for a raw run whose characters mostly step up by 0-4: usually a list
of tile numbers that happen to be printable, not text.
Characters are ASCII; the font has its tiles at the ASCII codes, with `@` drawn as ©.
Candidates only: who prints each string, and how, is still to be traced.
"""

import argparse
import csv
import re
import sys
from pathlib import Path

import classify
import romset

ROOT = romset.ROOT
MAIN = ["main_fixed.bin", "main_bank0.bin", "main_bank1.bin", "main_bank2.bin",
        "main_bank3.bin"]
RAW_CHARS = re.compile(rb"[A-Z0-9 .,!?:'\-~&()/\"@]{6,}")
MIN_RAW_LETTERS = 4


def ascending(text: str) -> bool:
    steps = [b - a for a, b in zip(map(ord, text), map(ord, text[1:]))]
    return sum(0 <= d <= 4 for d in steps) >= 0.6 * len(steps)


def address(image: str, addr: int) -> str:
    bank = image.removeprefix("main_").removesuffix(".bin")
    return f"{addr:04X}" if bank == "fixed" else f"{bank}:{addr:04X}"


def find_raw(data: bytes, base: int, taken: list[tuple[int, int]]) -> list[dict]:
    """Runs of text characters outside the prefixed strings, with enough letters."""
    out = []
    for m in RAW_CHARS.finditer(data):
        s, e = base + m.start(), base + m.end() - 1
        if any(s <= te and ts <= e for ts, te in taken):
            continue
        text = m.group().strip(b" ")
        if sum(65 <= c <= 90 for c in text) >= MIN_RAW_LETTERS:
            out.append({"start": s, "end": e, "note": m.group().decode("ascii")})
    return out


def strings(image: str, data: bytes) -> list[dict]:
    _rom, off, _length, base = romset.IMAGES[image]
    rows = []
    prefixed = classify.find_text(data, base)
    for r in prefixed:
        rows.append(("prefixed", r["start"], r["end"] - r["start"], r["note"]))
    for r in find_raw(data, base, [(r["start"], r["end"]) for r in prefixed]):
        rows.append(("raw", r["start"], r["end"] - r["start"] + 1, r["note"]))
    return [
        {"image": image, "address": address(image, a), "offset": f"{off + a - base:05X}",
         "form": form, "length": n,
         "hint": "ascending" if form == "raw" and ascending(text) else "", "text": text}
        for form, a, n, text in sorted(rows, key=lambda r: r[1])
    ]


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--roms", type=Path, help="ROM directory or zip")
    ap.add_argument("--out", type=Path, default=ROOT / "build" / "text" / "strings.csv")
    args = ap.parse_args()
    try:
        imgs = romset.images(romset.load(args.roms))
    except romset.RomError as e:
        print(e, file=sys.stderr)
        return 1
    args.out.parent.mkdir(parents=True, exist_ok=True)
    fields = ["image", "address", "offset", "form", "length", "hint", "text"]
    with args.out.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fields, lineterminator="\n")
        w.writeheader()
        for image in MAIN:
            rows = strings(image, imgs[image])
            w.writerows(rows)
            forms = {k: sum(r["form"] == k for r in rows) for k in ("prefixed", "raw")}
            print(f"{image:16} prefixed={forms['prefixed']:4}  raw={forms['raw']:4}")
    print(f"strings in {args.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
