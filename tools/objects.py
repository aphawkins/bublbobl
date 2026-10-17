"""Render the screen offline from a RAM image, as the arcade hardware draws it.

Usage: python tools/objects.py RAM.bin [RAM.bin ...] [--out DIR] [--scale N] [--full]
       python tools/objects.py --check SNAPDIR [SNAPDIR ...]

RAM.bin is the main CPU's C000-FFFF (0x4000 bytes), as tools/trace.py --snap writes it.
Each image is written as <name>.png next to it, or into --out. --check renders every
ram_<frame>.bin in a trace.py snap/ folder and compares it, pixel by pixel, with MAME's
screenshot taken at the same frame (the screenshots are numbered in the same order).

There is no tilemap. Everything on screen, walls and text included, is an object, as in
MAME bublbobl_v.cpp `screen_update_bublbobl`:

- Object RAM DD00-DFFF holds 192 objects of 4 bytes: Y, gfx_num, X, attr. An all-zero
  object is skipped. attr bits 0-3 = tile bank (x 1024), bit 6 = X - 256.
- gfx_num selects a 0x80-byte block of C000 RAM: (gfx_num & 0x1F) x 0x80, plus 0x1000
  when (gfx_num & 0xA0) == 0xA0. The block holds two 8-pixel columns (0x40 bytes each)
  of 2-byte tile entries: tile low byte, then tile bits 8-9 (b0-1), colour (b2-5),
  flip X (b6), flip Y (b7).
- The PROM a71-25 at 0x80 + (gfx_num & 0xE0) / 2 gives the object's shape, one byte per
  pair of tile rows (32 rows of 8 pixels, wrapping at 256): b3 = skip the row, b2 clear =
  start a new 16-pixel column at the object's X, b0-1 = which 0x10 quarter of each column
  the row reads.
- Objects are drawn in order with colour 15 transparent, over pen 255 (palette 15
  colour 15). The visible area is X 0-255, Y 16-239.
- The video enable and flip bits are FB40 b6 and b7; the RAM image has the main CPU's
  copy of FB40 at E1CB.
"""

import argparse
import sys
from pathlib import Path

from PIL import Image, ImageChops

import gfx
import palette
import romset

ROOT = romset.ROOT

RAM_BASE = 0xC000
OBJECT_RAM = 0xDD00 - RAM_BASE
OBJECT_COUNT = 0x300 // 4
PALETTE_RAM = 0xF800 - RAM_BASE
FB40_COPY = 0xE1CB - RAM_BASE
VISIBLE_Y = (16, 240)


class Renderer:
    def __init__(self, files: dict[str, bytes]):
        self.low, self.high = gfx.planes(files)
        self.prom = files["a71-25.41"]
        self.tiles: dict[int, bytes] = {}

    def tile(self, code: int) -> bytes:
        t = self.tiles.get(code)
        if t is None:
            t = self.tiles[code] = gfx.decode_tile(self.low, self.high, code)
        return t

    def render(self, ram: bytes, full: bool = False) -> Image.Image:
        """The 256 x 256 frame (or the visible 256 x 224) for one RAM image."""
        if len(ram) != 0x4000:
            raise ValueError(f"RAM image is {len(ram):#x} bytes, want 0x4000 (C000-FFFF)")
        colours = palette.ram_palette(ram[PALETTE_RAM:PALETTE_RAM + 0x200])
        pens = bytearray([255]) * (256 * 256)
        fb40 = ram[FB40_COPY]
        if fb40 & 0x40:
            self.draw(ram, pens, bool(fb40 & 0x80))
        img = Image.new("P", (256, 256))
        img.putpalette([v for c in colours for v in c])
        img.frombytes(bytes(pens))
        return img if full else img.crop((0, VISIBLE_Y[0], 256, VISIBLE_Y[1]))

    def draw(self, ram: bytes, pens: bytearray, flip: bool) -> None:
        sx = 0
        for n in range(OBJECT_COUNT):
            o = OBJECT_RAM + n * 4
            if not any(ram[o:o + 4]):
                continue
            y0, num, x0, attr = ram[o:o + 4]
            shape = 0x80 + ((num & 0xE0) >> 1)
            offs = (num & 0x1F) * 0x80
            if num & 0xA0 == 0xA0:
                offs |= 0x1000
            sy = -y0
            for yc in range(32):
                line = self.prom[shape + yc // 2]
                if line & 0x08:
                    continue
                if not line & 0x04:
                    sx = x0 - 256 if attr & 0x40 else x0
                for xc in range(2):
                    g = offs + xc * 0x40 + (yc & 7) * 2 + (line & 0x03) * 0x10
                    a = ram[g + 1]
                    code = ram[g] + 256 * (a & 0x03) + 1024 * (attr & 0x0F)
                    self.blit(pens, code, (a & 0x3C) >> 2, bool(a & 0x40), bool(a & 0x80),
                              sx + xc * 8, (sy + yc * 8) & 0xFF, flip)
            sx += 16

    def blit(self, pens: bytearray, code: int, colour: int, fx: bool, fy: bool,
             x: int, y: int, flip: bool) -> None:
        if flip:
            x, y, fx, fy = 248 - x, 248 - y, not fx, not fy
        t = self.tile(code)
        base = colour * 16
        for ty in range(8):
            py = y + ty
            if not 0 <= py < 256:  # MAME clips to the bitmap; it does not wrap
                continue
            row = (7 - ty if fy else ty) * 8
            for tx in range(8):
                px = x + tx
                if not 0 <= px < 256:
                    continue
                c = t[row + (7 - tx if fx else tx)]
                if c != 15:
                    pens[py * 256 + px] = base + c


def check(r: Renderer, folder: Path) -> int:
    """Compare each RAM image's render with MAME's screenshot. Returns the mismatches."""
    rams = sorted(folder.glob("ram_*.bin"))
    shots = sorted(folder.glob("[0-9]*.png"))
    bad = 0
    for ram, shot in zip(rams, shots):
        want = Image.open(shot).convert("RGB")
        got = r.render(ram.read_bytes()).convert("RGB")
        diff = ImageChops.difference(want, got).getbbox() if want.size == got.size else "size"
        if diff:
            bad += 1
            print(f"{folder.parent.name}/{ram.name} vs {shot.name}: differs in {diff}")
    print(f"{folder.parent.name}: {len(rams)} frames, {bad} differ")
    return bad


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("ram", type=Path, nargs="+", help="C000-FFFF RAM image(s), or snap folders with --check")
    ap.add_argument("--check", action="store_true", help="compare with MAME's screenshots")
    ap.add_argument("--roms", type=Path, help="ROM directory or zip")
    ap.add_argument("--out", type=Path, help="output folder (default: next to each image)")
    ap.add_argument("--scale", type=int, default=1, help="integer magnification")
    ap.add_argument("--full", action="store_true", help="the whole 256 x 256 bitmap")
    args = ap.parse_args()
    try:
        r = Renderer(romset.load(args.roms))
    except romset.RomError as e:
        print(e, file=sys.stderr)
        return 1
    if args.check:
        return 1 if sum(check(r, folder) for folder in args.ram) else 0
    for path in args.ram:
        img = r.render(path.read_bytes(), args.full)
        if args.scale > 1:
            img = img.resize((img.width * args.scale, img.height * args.scale), Image.NEAREST)
        out = (args.out or path.parent) / (path.stem + ".png")
        out.parent.mkdir(parents=True, exist_ok=True)
        img.save(out)
        print(out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
