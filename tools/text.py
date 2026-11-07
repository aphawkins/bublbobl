"""Catalogue the text in the main CPU images, and say who prints each string.

Usage: python tools/text.py [--roms DIR] [--out DIR] [--check]

Needs build/lst/ from tools/build.py. Writes to build/text/:

strings.csv, one row per string:
    image, address, offset, form, length, hint, used_by, text
address is the CPU address (`1234` in the fixed ROM, `bank1:9C40` in a bank), offset is
the offset in the ROM file. form is `prefixed` (length byte, then the characters; the
length byte is at address) or `raw` (a run of text characters with no length byte).
hint is `ascending` for a raw run whose characters mostly step up by 0-4: usually a list
of tile numbers that happen to be printable, not text.
used_by names the routines that print the string. A row with no used_by is only a
candidate from the byte patterns: nothing in the source prints it.

prints.csv, one row per time the code prints a string:
    image, site, routine, printer, string, tile, layer, column, row, colour, text
site is the address of the call, or of the record in an ending. tile is the first tile's
address, empty if the code works it out at run time. layer is `walls` (CD00-D4FF) or
`front` (D500-DCFF), 32 columns of 0x40 bytes, 2 bytes a row in each. For an ending, row
is the scroll row, and the tile is where that row is drawn.

Characters are ASCII; the font has its tiles at the ASCII codes, with `@` drawn as (C).
The score bar's font follows at 60-89 (blank, A-Z, 0-9), and is shown in lower case, with
a space for the blank. Other bytes are shown as {XX}.

--check looks for every print in the RAM snapshots of build/traces and build/snaps: a
print with a known tile is seen if a snapshot holds all its characters and its colour at
that tile. Blanks are skipped, because the game fills some of them in afterwards. It also
says whether each call ran in any trace's coverage.json.
"""

import argparse
import csv
import json
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
SRC_NAMES = ["fixed", "bank0", "bank1", "bank2", "bank3"]
STRING_PRINTERS = ("PRINT_TEXT", "PRINT_COUNTED")
TABLE_PRINTER = "PRINT_TEXTS"
RECORD = 5  # PRINT_TEXTS: tile, string, colour
# ENDING_SCROLL's scripts in bank 1: label, rows (ENDING_ROW_DRAW's limit), next label
ENDINGS = [("ENDING_TEXT_2P", 0x8B, "ENDING_TEXT_1P"),
           ("ENDING_TEXT_1P", 0x1A, "ENDING_TEXT_SUPER"),
           ("ENDING_TEXT_SUPER", 0x8B, "GRID_EDGES")]
ENDING_TILES = 0xD500
BLANKS = (0x20, 0x60)
# Prints whose string comes from a table at run time: routine -> the strings it can print
INDIRECT = {"VIDEO_RAM_TEST": (0x807C, 0x808D)}  # VIDEO_RAM_AREAS
WALLS, FRONT, LAYER_END = 0xCD00, 0xD500, 0xDD00
LISTING = re.compile(r"\s*\d+ ([0-9a-f]{4}) [0-9A-F ]+\t(.*)")
LABEL_LINE = re.compile(r"\s*\d+\s+\t(\w+):\s*;\s*([0-9A-F]{4})")
PRINT_CALL = re.compile(r"(call|jp) (PRINT_\w+)$")
LOAD = re.compile(r"ld (hl|de|iy|c|b),([^()]+)$")
DE_CHANGED = re.compile(r"ld [de],|(pop|inc|dec) de|ex de,hl|call ")
# Between `ld hl,A` and `ld hl,B`, these leave A a possible argument of the next print
KEEPS_CHOICE = re.compile(r"ld (c|a|de|e|d),|(and|or) a$|cp |jr |bit ")


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


def show_char(b: int) -> str:
    if 0x20 <= b <= 0x5F or 0x61 <= b <= 0x7A:
        return chr(b)
    if b == 0x60:
        return " "
    if 0x7B <= b <= 0x84:
        return str(b - 0x7B)
    return f"{{{b:02X}}}"


def show(data: bytes) -> str:
    return "".join(map(show_char, data))


def strings(image: str, data: bytes, printed: dict[int, set[str]]) -> list[dict]:
    """The strings in an image. printed: length byte address -> routines printing it."""
    _rom, off, _length, base = romset.IMAGES[image]

    def counted(a: int) -> bytes:
        return data[a - base + 1 : a - base + 1 + data[a - base]]

    rows = [("prefixed", a, data[a - base], show(counted(a))) for a in printed]
    taken = [(a, a + data[a - base]) for a in printed]

    def free(s: int, e: int) -> bool:
        return not any(s <= te and ts <= e for ts, te in taken)

    prefixed = [r for r in classify.find_text(data, base) if free(r["start"], r["end"])]
    for r in prefixed:
        rows.append(("prefixed", r["start"], r["end"] - r["start"], r["note"]))
    taken += [(r["start"], r["end"]) for r in prefixed]
    for r in find_raw(data, base, taken):
        rows.append(("raw", r["start"], r["end"] - r["start"] + 1, r["note"]))
    return [
        {"image": image, "address": address(image, a), "offset": f"{off + a - base:05X}",
         "form": form, "length": n,
         "hint": "ascending" if form == "raw" and ascending(text) else "",
         "used_by": " ".join(sorted(printed.get(a, ()))), "text": text}
        for form, a, n, text in sorted(rows, key=lambda r: r[1])
    ]


def read_listing(name: str) -> tuple[list[tuple[int | None, str]], dict[str, int]]:
    """build/lst/<name>.lst as (address, instruction) lines, labels as (None, label)."""
    base = 0 if name == "fixed" else 0x8000
    lines, labels = [], {}
    path = ROOT / "build" / "lst" / f"{name}.lst"
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        if m := LABEL_LINE.match(line):
            labels[m[1]] = int(m[2], 16)
            lines.append((None, m[1]))
        elif m := LISTING.match(line):
            lines.append((base + int(m[1], 16), " ".join(m[2].split(";")[0].split())))
    return lines, labels


def layer_of(tile: int | None) -> tuple[str, str, str]:
    """Layer, column and row of a tile address, empty outside the two layers."""
    if tile is None or not WALLS <= tile < LAYER_END:
        return "", "", ""
    layer, start = ("walls", WALLS) if tile < FRONT else ("front", FRONT)
    return layer, str((tile - start) // 0x40), str((tile & 0x3F) // 2)


def print_row(image: str, site: int, routine: str, printer: str, source: str, ref: int,
              text: bytes, tile: int | None, colour: int | None) -> dict:
    layer, column, row = layer_of(tile)
    return {"image": image, "site": address(image, site), "routine": routine,
            "printer": printer, "string": address(source, ref),
            "tile": "" if tile is None else f"{tile:04X}", "layer": layer, "column": column,
            "row": row, "colour": "" if colour is None else f"{colour:02X}",
            "text": show(text), "_source": source, "_ref": ref, "_bytes": text,
            "_tile": tile, "_colour": colour}


class Sites:
    """Walks one image's listing and collects its prints."""

    def __init__(self, name: str, imgs: dict[str, bytes], labels: dict[str, dict[str, int]]):
        self.name, self.imgs, self.labels = name, imgs, labels
        self.image = f"main_{name}.bin"
        self.prints: list[dict] = []
        self.unresolved: list[str] = []

    def value(self, text: str) -> int | None:
        """The number or ROM label a source operand stands for."""
        text = text.strip()
        if text.startswith("0x"):
            return int(text, 16)
        return self.labels[self.name].get(text, self.labels["fixed"].get(text))

    def rom(self, ref: int) -> tuple[str, bytes, int]:
        """The image, bytes and base address that ref reads when this image is mapped."""
        image = "main_fixed.bin" if ref < 0x8000 else self.image
        return image, self.imgs[image], romset.IMAGES[image][3]

    def add(self, site: int, routine: str, printer: str, ref: int, tile: int | None,
            colour: int | None) -> None:
        image, data, base = self.rom(ref)
        n = data[ref - base]
        self.prints.append(print_row(self.image, site, routine, printer, image, ref,
                                     data[ref - base + 1 : ref - base + 1 + n], tile, colour))

    def table(self, site: int, routine: str, iy: int, count: int) -> None:
        _image, data, base = self.rom(iy)
        for i in range(count):
            r = data[iy - base + i * RECORD : iy - base + (i + 1) * RECORD]
            self.add(site, routine, TABLE_PRINTER, r[2] | r[3] << 8, r[0] | r[1] << 8, r[4])

    def walk(self, lines: list[tuple[int | None, str]]) -> None:
        routine = ""
        choices: list[list[int | None]] = []  # [string, colour] the next print may use
        de = colour = iy = count = None
        for addr, op in lines:
            if addr is None:
                if not op.startswith("L_"):
                    routine = op
                continue
            if m := PRINT_CALL.match(op):
                printer = m[2]
                if routine != TABLE_PRINTER:
                    if printer == TABLE_PRINTER:
                        self.table(addr, routine, iy, count)
                    elif printer in STRING_PRINTERS:
                        if routine in INDIRECT:
                            choices = [[ref, colour] for ref in INDIRECT[routine]]
                        if not choices:
                            self.unresolved.append(f"{self.name}:{addr:04X} {routine}")
                        for ref, c in choices:
                            self.add(addr, routine, printer, ref, de, c)
                choices, de = [], None
            elif m := LOAD.match(op):
                reg, v = m[1], self.value(m[2])
                if reg == "hl":
                    if v is None or v >= 0xC000:
                        choices = []
                    else:
                        choices.append([v, colour])
                elif reg == "c":
                    colour = v
                    if choices:
                        choices[-1][1] = v
                elif reg == "de":
                    de = v
                elif reg == "iy":
                    iy = v
                else:
                    count = v
            else:
                if DE_CHANGED.match(op):
                    de = None
                if not KEEPS_CHOICE.match(op):
                    choices = []


def ending_prints(imgs: dict[str, bytes], labels: dict[str, int]) -> list[dict]:
    """ENDING_ROW_DRAW's records: colour, column, length, characters; FF ends a row."""
    image = "main_bank1.bin"
    data, base = imgs[image], romset.IMAGES[image][3]
    out = []
    for label, rows, after in ENDINGS:
        p = labels[label] - base
        for row in range(rows):
            while data[p] != 0xFF:
                colour, column, n = data[p : p + 3]
                tile = ENDING_TILES + column * 0x40 + (row & 0x1F) * 2
                r = print_row(image, base + p, label, "ENDING_ROW_DRAW", image, base + p + 2,
                              data[p + 3 : p + 3 + n], tile, colour)
                r["row"] = str(row)
                out.append(r)
                p += 3 + n
            p += 1
        if p + base != labels[after]:
            raise ValueError(f"{label} ends at {p + base:04X}, not at {after}")
    return out


def find_prints(imgs: dict[str, bytes]) -> tuple[list[dict], list[str]]:
    listings = {n: read_listing(n) for n in SRC_NAMES}
    labels = {n: listing[1] for n, listing in listings.items()}
    prints, unresolved = [], []
    for name in SRC_NAMES:
        sites = Sites(name, imgs, labels)
        sites.walk(listings[name][0])
        prints += sites.prints
        unresolved += sites.unresolved
    return prints + ending_prints(imgs, labels["bank1"]), unresolved


def snapshots() -> list[Path]:
    build = ROOT / "build"
    return sorted(build.glob("traces/*/snap/ram_*.bin")) + \
        sorted(build.glob("snaps/*/snap/ram_*.bin"))


def coverage() -> dict[str, set[str]]:
    ran: dict[str, set[str]] = {}
    for pattern in ("traces/*/coverage.json", "snaps/*/coverage.json"):
        for path in (ROOT / "build").glob(pattern):
            for image, addrs in json.loads(path.read_text()).items():
                ran.setdefault(image, set()).update(addrs)
    return ran


def check(prints: list[dict]) -> int:
    """Report the prints found in snapshots, and the calls that ran in traces."""
    known = [p for p in prints if p["_tile"] is not None and p["text"].strip()]
    wants = [(p, [(p["_tile"] - 0xC000 + i * 0x40, b, p["_colour"])
                  for i, b in enumerate(p["_bytes"]) if b not in BLANKS]) for p in known]
    seen: set[int] = set()
    other_colour: set[int] = set()
    paths = snapshots()
    for path in paths:
        ram = path.read_bytes()
        for p, cells in wants:
            if id(p) not in seen and all(ram[o] == b for o, b, _c in cells):
                if all(ram[o + 1] == c for o, _b, c in cells):
                    seen.add(id(p))
                else:
                    other_colour.add(id(p))
    ran = coverage()
    calls = {(p["image"], p["site"]): p for p in prints if p["printer"] != "ENDING_ROW_DRAW"}
    not_run = [p for (image, site), p in calls.items()
               if site.split(":")[-1] not in ran.get(image.removesuffix(".bin"), ())]
    print(f"{len(paths)} snapshots: {sum(id(p) in seen for p in known)} of {len(known)} "
          f"prints with a known tile seen")
    for p in known:
        if id(p) not in seen:
            note = " (characters there, other colour)" if id(p) in other_colour else ""
            print(f"  not seen: {p['routine']} {p['string']} {p['tile']} {p['text']!r}{note}")
    print(f"{len(calls) - len(not_run)} of {len(calls)} calls ran in a trace")
    for p in not_run:
        print(f"  not run: {p['site']} {p['routine']} {p['text']!r}")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--roms", type=Path, help="ROM directory or zip")
    ap.add_argument("--out", type=Path, default=ROOT / "build" / "text")
    ap.add_argument("--check", action="store_true", help="look for the prints in snapshots")
    args = ap.parse_args()
    try:
        imgs = romset.images(romset.load(args.roms))
    except romset.RomError as e:
        print(e, file=sys.stderr)
        return 1
    try:
        prints, unresolved = find_prints(imgs)
    except FileNotFoundError as e:
        print(f"{e}: run tools/build.py first", file=sys.stderr)
        return 1
    printed: dict[str, dict[int, set[str]]] = {}
    for p in prints:
        printed.setdefault(p["_source"], {}).setdefault(p["_ref"], set()).add(p["routine"])
    args.out.mkdir(parents=True, exist_ok=True)
    fields = ["image", "address", "offset", "form", "length", "hint", "used_by", "text"]
    with (args.out / "strings.csv").open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fields, lineterminator="\n")
        w.writeheader()
        for image in MAIN:
            rows = strings(image, imgs[image], printed.get(image, {}))
            w.writerows(rows)
            forms = {k: sum(r["form"] == k for r in rows) for k in ("prefixed", "raw")}
            used = sum(bool(r["used_by"]) for r in rows)
            print(f"{image:16} prefixed={forms['prefixed']:4}  raw={forms['raw']:4}  "
                  f"printed={used:4}")
    fields = ["image", "site", "routine", "printer", "string", "tile", "layer", "column",
              "row", "colour", "text"]
    with (args.out / "prints.csv").open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fields, lineterminator="\n", extrasaction="ignore")
        w.writeheader()
        w.writerows(prints)
    print(f"{len(prints)} prints; strings.csv and prints.csv in {args.out}")
    for site in unresolved:
        print(f"  no string known at {site}")
    return check(prints) if args.check else 0


if __name__ == "__main__":
    sys.exit(main())
