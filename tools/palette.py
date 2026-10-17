"""Extract the palettes from the main CPU ROMs.

Usage: python tools/palette.py [--roms DIR] [--out DIR] [--scale N]

Palette RAM (F800-F9FF) is 256 colours, 16 palettes x 16 colours, each colour two bytes
RGBx_444 big-endian: byte 0 = R << 4 | G, byte 1 = B << 4. There is no colour PROM, so
every colour comes from tables the main CPU copies in:

- bank1:8000, 0x200 bytes: the whole of palette RAM, copied by 0B30 (bank page 1).
  Palettes 14 and 15 are zero there; the round sets them.
- bank1:8200, 8 x 0x20: round palettes, copied by 0B43 into palette 14 (F9C0) or 15
  (F9E0). The index is the first byte of the round's record (E598), and the records are
  0x2B bytes per round at bank1:A73A (copied by 1775).
- 3CC2, 0x40 bytes: palettes 7-8, copied by 3C60.
- 1BAE, 6 words: colour cycle for palette 1 colour 14 (F83C), stepped by 1B90.
- 2895, 16 colours: a red ramp from black for palette 1 colour 1 (F822). 2873 steps
  E61D through it, one step every 5 calls, and stops at 15.

Writes build/gfx/palettes.json and build/gfx/palettes.png (one row of swatches per
palette).
"""

import argparse
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw

import romset

ROOT = romset.ROOT

BASE = 0x0000          # bank1 offset of the 0x200-byte palette RAM image
ROUND_PALS = 0x0200    # bank1 offset of the round palettes
ROUND_PAL_COUNT = 8
ROUND_RECORDS = 0x273A  # bank1 offset of the round records (bank1:A73A)
ROUND_RECORD_SIZE = 0x2B
ROUNDS = 100
ALT_78 = 0x3CC2        # fixed ROM: palettes 7-8
CYCLE_1_14 = 0x1BAE    # fixed ROM: 6 colours for palette 1 colour 14
CYCLE_1_14_LEN = 6
COLOUR_1_1 = 0x2895    # fixed ROM: words for palette 1 colour 1
COLOUR_1_1_LEN = 16


def rgb(hi: int, lo: int) -> tuple[int, int, int]:
    """One RGBx_444 big-endian colour as 8-bit RGB, expanded as MAME's pal4bit does."""
    return ((hi >> 4) * 0x11, (hi & 0x0F) * 0x11, (lo >> 4) * 0x11)


def colours(data: bytes) -> list[tuple[int, int, int]]:
    return [rgb(data[i], data[i + 1]) for i in range(0, len(data), 2)]


def hexes(cols: list[tuple[int, int, int]]) -> list[str]:
    return ["#%02x%02x%02x" % c for c in cols]


def extract(fixed: bytes, bank1: bytes) -> dict:
    base = colours(bank1[BASE:BASE + 0x200])
    rounds = [colours(bank1[ROUND_PALS + i * 0x20:ROUND_PALS + (i + 1) * 0x20])
              for i in range(ROUND_PAL_COUNT)]
    round_index = [bank1[ROUND_RECORDS + r * ROUND_RECORD_SIZE] for r in range(ROUNDS)]
    return {
        "format": "RGBx_444 big-endian; colours are #rrggbb, 4-bit channels times 0x11",
        "base": {
            "source": "bank1:8000",
            "palettes": [hexes(base[p * 16:(p + 1) * 16]) for p in range(16)],
        },
        "round": {
            "source": "bank1:8200",
            "target": "palette 14 (F9C0) or 15 (F9E0)",
            "palettes": [hexes(p) for p in rounds],
            "index_by_round": round_index,
        },
        "palettes_7_8": {
            "source": "3CC2",
            "palettes": [hexes(p) for p in
                         (colours(fixed[ALT_78:ALT_78 + 0x20]),
                          colours(fixed[ALT_78 + 0x20:ALT_78 + 0x40]))],
        },
        "cycle_1_14": {
            "source": "1BAE",
            "colours": hexes(colours(fixed[CYCLE_1_14:CYCLE_1_14 + CYCLE_1_14_LEN * 2])),
        },
        "colour_1_1": {
            "source": "2895",
            "colours": hexes(colours(fixed[COLOUR_1_1:COLOUR_1_1 + COLOUR_1_1_LEN * 2])),
        },
    }


def ram_palette(ram: bytes) -> list[tuple[int, int, int]]:
    """The 256 colours of a palette RAM image (0x200 bytes from F800)."""
    return colours(ram)


def swatches(rows: list[tuple[str, list[str]]], scale: int) -> Image.Image:
    cell = 12 * scale
    label = 90
    img = Image.new("RGB", (label + 16 * cell, len(rows) * cell), (64, 64, 64))
    draw = ImageDraw.Draw(img)
    for y, (name, cols) in enumerate(rows):
        draw.text((2, y * cell + 1), name, fill=(255, 255, 255))
        for x, c in enumerate(cols):
            v = int(c[1:], 16)
            draw.rectangle([label + x * cell, y * cell, label + (x + 1) * cell - 2, (y + 1) * cell - 2],
                           fill=(v >> 16, (v >> 8) & 0xFF, v & 0xFF))
    return img


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--roms", type=Path, help="ROM directory or zip")
    ap.add_argument("--out", type=Path, default=ROOT / "build" / "gfx")
    ap.add_argument("--scale", type=int, default=2, help="swatch magnification")
    args = ap.parse_args()
    try:
        images = romset.images(romset.load(args.roms))
    except romset.RomError as e:
        print(e, file=sys.stderr)
        return 1
    pal = extract(images["main_fixed.bin"], images["main_bank1.bin"])
    args.out.mkdir(parents=True, exist_ok=True)
    (args.out / "palettes.json").write_text(json.dumps(pal, indent=1) + "\n")
    rows = [(f"base {p}", c) for p, c in enumerate(pal["base"]["palettes"])]
    rows += [(f"round {i}", c) for i, c in enumerate(pal["round"]["palettes"])]
    rows += [(f"3CC2 pal {7 + i}", c) for i, c in enumerate(pal["palettes_7_8"]["palettes"])]
    rows += [("cycle 1:14", pal["cycle_1_14"]["colours"]), ("1:1", pal["colour_1_1"]["colours"])]
    swatches(rows, args.scale).save(args.out / "palettes.png")
    used = sorted(set(pal["round"]["index_by_round"]))
    print(f"palettes.json, palettes.png  (round palette indexes used: {used})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
