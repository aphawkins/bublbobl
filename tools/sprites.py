"""Build sprite sheets from the sprite draws logged by tools/trace.py.

Usage: python tools/sprites.py [TRACE_DIR ...] [--roms DIR] [--out DIR] [--scale N]

Every 16 x 16 sprite the main CPU draws goes through SPRITE (147D) or SPRITE_FLIPX (149C).
Each takes A = gfx_num (block in b0-4, quarter in b5-6), B = the first of four tile
numbers and C = the tile attribute byte (tile bits 8-9 in b0-1, colour in b2-5, flip X
b6, flip Y b7), and writes the tiles into rows 6-7 of that quarter of the gfx block:

    SPRITE         B    B+1        SPRITE_FLIPX   B+1  B      (each tile flipped in X)
                   B+2  B+3                       B+3  B+2

B counts in 8 bits (INC B), so B+1 after FF is 00 with the same tile bits 8-9. The tile
bank (x 1024 tiles) is the low nibble of the attribute of the object that shows the gfx
block. So a sprite frame is (bank, B, C), and the ROM frame tables are tables of B and C.

trace.lua writes sprites.csv in each trace folder: caller (the instruction that called
SPRITE, or the caller of the list helpers 14BD, 14E1, 1505 and 1517), flip (n or x),
gfx_num, bank, B, C, IX, count and the first frame seen. Most callers point IX at the
record of the thing they draw, so IX says whose frame it is (notes/sprites.md). This tool merges the folders (default:
every folder in build/traces and build/snaps) and writes, in build/gfx/sprites/:

  sprites.json      per caller: each frame's bank, tile, attribute, colour, flips seen,
                    gfx numbers, IX values and count. Frames are in (bank, tile, colour) order and
                    drawn unflipped; "flips" lists the forms the game used.
  <caller>.png      that caller's frames left to right, 16 per row, in the same order
  all.png           every caller's row of frames under its name, for an overview

Colours come from the base palettes (bank1:8000). Palettes 14 and 15 are the round's,
and are drawn with round palette 0.
"""

import argparse
import csv
import json
import sys
from collections import defaultdict
from pathlib import Path

from PIL import Image, ImageDraw

import gfx
import palette
import romset

ROOT = romset.ROOT
PER_ROW = 16
GAP = 2


def load_draws(folders: list[Path]) -> dict:
    """caller -> (bank, tile, attr & 0x3F) -> {flips, gfx, count, first}."""
    callers: dict = defaultdict(dict)
    for folder in folders:
        path = folder / "sprites.csv"
        if not path.exists():
            continue
        with path.open(newline="") as f:
            for row in csv.DictReader(f):
                if row["bank"] == "-":
                    continue  # drawn into a block no object showed
                attr = int(row["attr"], 16)
                b = int(row["tile"], 16)
                key = (int(row["bank"], 16), b, attr & 0x3F)
                flips = ("x" if row["flip"] == "x" else "") + ("y" if attr & 0x80 else "")
                fr = callers[row["caller"]].setdefault(
                    key, {"flips": set(), "gfx": set(), "ix": set(), "count": 0, "runs": set()})
                fr["flips"].add(flips or "-")
                fr["gfx"].add(int(row["gfx"], 16))
                if row.get("ix"):
                    fr["ix"].add(int(row["ix"], 16))
                fr["count"] += int(row["count"])
                fr["runs"].add(folder.name)
    return callers


def tile_codes(bank: int, b: int, attr: int) -> list[int]:
    hi = (attr & 0x03) * 256 + bank * gfx.BANK_TILES
    return [hi + ((b + i) & 0xFF) for i in range(4)]


class Painter:
    def __init__(self, files: dict[str, bytes]):
        self.low, self.high = gfx.planes(files)
        images = romset.images(files)
        pals = palette.extract(images["main_fixed.bin"], images["main_bank1.bin"])
        base = pals["base"]["palettes"]
        base[14] = base[15] = pals["round"]["palettes"][0]
        self.colours = [tuple(int(h[i:i + 2], 16) for i in (1, 3, 5)) for p in base for h in p]

    def frame(self, bank: int, b: int, attr: int) -> Image.Image:
        img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
        px = img.load()
        base = ((attr >> 2) & 0x0F) * 16
        for i, code in enumerate(tile_codes(bank, b, attr)):
            t = gfx.decode_tile(self.low, self.high, code)
            ox, oy = (i & 1) * 8, (i >> 1) * 8
            for n, c in enumerate(t):
                if c != 15:
                    px[ox + n % 8, oy + n // 8] = self.colours[base + c] + (255,)
        return img


def sheet(p: Painter, frames: list, scale: int) -> Image.Image:
    rows = (len(frames) + PER_ROW - 1) // PER_ROW
    cell = 16 + GAP
    img = Image.new("RGBA", (min(len(frames), PER_ROW) * cell, rows * cell), (40, 40, 40, 255))
    for n, (bank, b, attr) in enumerate(frames):
        f = p.frame(bank, b, attr)
        img.alpha_composite(f, ((n % PER_ROW) * cell, (n // PER_ROW) * cell))
    if scale > 1:
        img = img.resize((img.width * scale, img.height * scale), Image.NEAREST)
    return img


def overview(sheets: list[tuple[str, Image.Image]]) -> Image.Image:
    label = 14
    w = max(s.width for _, s in sheets)
    h = sum(label + s.height + 4 for _, s in sheets)
    img = Image.new("RGBA", (w, h), (24, 24, 24, 255))
    draw = ImageDraw.Draw(img)
    y = 0
    for name, s in sheets:
        draw.text((2, y + 1), name, fill=(220, 220, 220, 255))
        img.alpha_composite(s, (0, y + label))
        y += label + s.height + 4
    return img


def order(caller: str) -> tuple:
    bank, _, addr = caller.rpartition(":")
    return (bank, int(addr, 16))


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("folders", type=Path, nargs="*", help="trace folders (default: all)")
    ap.add_argument("--roms", type=Path, help="ROM directory or zip")
    ap.add_argument("--out", type=Path, default=ROOT / "build" / "gfx" / "sprites")
    ap.add_argument("--scale", type=int, default=2, help="integer magnification")
    args = ap.parse_args()
    folders = args.folders or sorted(
        p for d in ("traces", "snaps") for p in (ROOT / "build" / d).glob("*") if p.is_dir())
    callers = load_draws(folders)
    if not callers:
        print("no sprites.csv in " + ", ".join(str(f) for f in folders), file=sys.stderr)
        return 1
    try:
        p = Painter(romset.load(args.roms))
    except romset.RomError as e:
        print(e, file=sys.stderr)
        return 1
    args.out.mkdir(parents=True, exist_ok=True)
    meta = {}
    sheets = []
    for caller in sorted(callers, key=order):
        frames = sorted(callers[caller], key=lambda k: (k[0], (k[2] & 3) * 256 + k[1], k[2] >> 2))
        meta[caller] = [{
            "bank": bank,
            "tile": f"{bank * gfx.BANK_TILES + (attr & 3) * 256 + b:#06x}",
            "b": f"{b:02X}",
            "attr": f"{attr:02X}",
            "colour": attr >> 2,
            "flips": sorted(callers[caller][(bank, b, attr)]["flips"]),
            "gfx": [f"{g:02X}" for g in sorted(callers[caller][(bank, b, attr)]["gfx"])],
            "ix": [f"{i:04X}" for i in sorted(callers[caller][(bank, b, attr)]["ix"])],
            "count": callers[caller][(bank, b, attr)]["count"],
            "runs": sorted(callers[caller][(bank, b, attr)]["runs"]),
        } for bank, b, attr in frames]
        s = sheet(p, frames, args.scale)
        s.save(args.out / f"{caller.replace(':', '_')}.png")
        sheets.append((f"{caller}  ({len(frames)})", s))
    (args.out / "sprites.json").write_text(json.dumps(meta, indent=1))
    overview(sheets).save(args.out / "all.png")
    total = sum(len(v) for v in meta.values())
    print(f"{len(meta)} callers, {total} frames from {len(folders)} folders -> {args.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
