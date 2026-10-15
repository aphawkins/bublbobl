"""Decode the graphics ROMs into tile sheets.

Usage: python tools/gfx.py [--roms DIR] [--out DIR] [--scale N]

Writes build/gfx/tiles_bank<NN>.png: one sheet per 1024-tile bank (the bank an object's
attribute low nibble selects), 32 x 32 tiles of 8 x 8 pixels, tile n at column n % 32,
row n // 32. Pixels are the raw 4-bit colour index (15 = transparent for objects) on a
grey ramp in an indexed PNG, so a real palette can be swapped in later.

Layout from MAME bublbobl.cpp `charlayout`: the region is bit-inverted; planes are
{0, 4, half, half + 4} bits with plane 0 the most significant; x bits 3,2,1,0,11,10,9,8;
16 bits per row; 128 bits per tile. Banks 0-11 hold ROM; 12-15 are empty sockets.
"""

import argparse
import sys
from pathlib import Path

from PIL import Image

import romset

ROOT = romset.ROOT

# gfx1 region: a78-09..14 = planes 0-1, a78-15..20 = planes 2-3, each half padded to 0x40000.
LOW = ["a78-09.12", "a78-10.13", "a78-11.14", "a78-12.15", "a78-13.16", "a78-14.17"]
HIGH = ["a78-15.30", "a78-16.31", "a78-17.32", "a78-18.33", "a78-19.34", "a78-20.35"]
TILE_BYTES = 16
BANK_TILES = 1024
SHEET_COLS = 32


def planes(files: dict[str, bytes]) -> tuple[bytes, bytes]:
    """The two halves of the region, inverted as ROMREGION_INVERT does."""
    inv = bytes(range(255, -1, -1))
    low = b"".join(files[n] for n in LOW).translate(inv)
    high = b"".join(files[n] for n in HIGH).translate(inv)
    return low, high


def decode_tile(low: bytes, high: bytes, tile: int) -> bytes:
    """64 colour indexes (row-major) for one tile."""
    out = bytearray(64)
    base = tile * TILE_BYTES
    for y in range(8):
        for half in range(2):  # x 0-3 from the row's first byte, x 4-7 from the second
            a = low[base + y * 2 + half]
            b = high[base + y * 2 + half]
            for x in range(4):
                # x bit 3-x: plane 0/2 in the high nibble, plane 1/3 in the low nibble.
                hi_mask = 0x10 << x
                lo_mask = 0x01 << x
                out[y * 8 + half * 4 + x] = (
                    (8 if a & hi_mask else 0)
                    | (4 if a & lo_mask else 0)
                    | (2 if b & hi_mask else 0)
                    | (1 if b & lo_mask else 0)
                )
    return bytes(out)


def grey_palette() -> list[int]:
    return [v for i in range(16) for v in (i * 17,) * 3] + [0] * (256 - 16) * 3


def bank_sheet(low: bytes, high: bytes, bank: int) -> Image.Image:
    rows = BANK_TILES // SHEET_COLS
    img = Image.new("P", (SHEET_COLS * 8, rows * 8))
    img.putpalette(grey_palette())
    px = img.load()
    for n in range(BANK_TILES):
        pixels = decode_tile(low, high, bank * BANK_TILES + n)
        ox, oy = (n % SHEET_COLS) * 8, (n // SHEET_COLS) * 8
        for i, c in enumerate(pixels):
            px[ox + i % 8, oy + i // 8] = c
    return img


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--roms", type=Path, help="ROM directory or zip")
    ap.add_argument("--out", type=Path, default=ROOT / "build" / "gfx")
    ap.add_argument("--scale", type=int, default=1, help="integer magnification")
    args = ap.parse_args()
    try:
        files = romset.load(args.roms)
    except romset.RomError as e:
        print(e, file=sys.stderr)
        return 1
    low, high = planes(files)
    args.out.mkdir(parents=True, exist_ok=True)
    banks = len(low) // TILE_BYTES // BANK_TILES
    for bank in range(banks):
        img = bank_sheet(low, high, bank)
        if args.scale > 1:
            img = img.resize((img.width * args.scale, img.height * args.scale), Image.NEAREST)
        path = args.out / f"tiles_bank{bank:02d}.png"
        img.save(path)
        print(f"{path.name}  tiles {bank * BANK_TILES:#06x}-{(bank + 1) * BANK_TILES - 1:#06x}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
