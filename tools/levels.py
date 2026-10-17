"""Decode the 100 round layouts into JSON and PNG previews.

Usage: python tools/levels.py [--roms DIR] [--out DIR] [--scale N]
       python tools/levels.py --check SNAPDIR [SNAPDIR ...]

Writes build/levels/round_NNN.json and round_NNN.png for rounds 1-100, and rounds.png,
all 100 on one sheet. --check rebuilds the grid and the wall tiles of every ram_<frame>.bin
in a trace.py snap/ folder from the ROMs, and compares them with the RAM.

A round is a 32 x 32 grid of 8 x 8 cells, ROUND_GRID (E398-E597): 16 bytes a row, two
cells a byte, high nibble first. 0 is wall; 1-4 are open, and look like the air current
that moves bubbles (notes/levels.md). Three sources fill it at round start:
- Rows 5-28 (E3E8, 0x180 bytes) come from the sub CPU. When the main CPU sets
  GRID_REQUEST (E397) to 1, the sub CPU's GRID_UNPACK (sub 00A9) reads 0x120 bytes at
  ROUND_LAYOUTS (sub 0CFC) + round x 0x120 as a bit stream, 6 bits a byte, 3 bits a cell,
  and sets GRID_REQUEST to FF.
- Rows 0-4 (0x50 bytes) and rows 29-31 (0x30 bytes) come from LOAD_GRID_EDGES (1700):
  ROUND_RECORD byte 3, high nibble = top pattern, low nibble = bottom pattern, both
  through entries 0-15 of bank1:GRID_EDGES. The bottom copy takes the first 0x30 bytes
  of a top pattern. Entries 16-31 point at 0x30-byte copies of the same bytes, never read.

DRAW_GRID_ROW (1958) and SHADE_GRID_ROW (199C) then draw the grid row by row into the
tile columns at CD00-D4FF, 0x40 bytes a column, 2 bytes a row: tile low byte, then
(tile >> 8) | colour << 2. The wall tile is 0x208 + 5 x round (0-based), the side walls
(columns 0-1 and 30-31) the 2 x 2 block at 0x204 + 5 x round, colour 15 on odd rounds and
14 on even, the palettes LOAD_ROUND_PAL fills. Open cells next to a wall get a shadow tile
F0-F5. Rows 0-3 are then overwritten by the score line and rows 30-31 are off screen.
"""

import argparse
import json
import struct
import sys
from pathlib import Path

from PIL import Image

import gfx
import palette
import romset

ROOT = romset.ROOT

ROUNDS = 100
GRID_ROWS = 32
GRID_COLS = 32
ROW_BYTES = GRID_COLS // 2
GRID_EDGES = 0x15AA        # bank1 offset of the pointer table (bank1:95AA)
TOP_BYTES = 0x50           # rows 0-4
BOTTOM_BYTES = 0x30        # rows 29-31
ROUND_LAYOUTS = 0x0CFC     # sub CPU
LAYOUT_BYTES = 0x120
LAYOUT_CELLS = 0x180 * 2   # rows 5-28
WALL_TILE = 0x208
SIDE_TILE = 0x204
TILES_PER_ROUND = 5
SHADOW = 0xF0              # F0-F5
FIRST_ROW = 4              # rows 0-3 are the score line
LAST_ROW = 29              # rows 30-31 are below the visible area
VISIBLE_ROWS = (2, 30)     # screen Y 16-239

RAM_BASE = 0xC000
RAM_GRID = 0xE398 - RAM_BASE
RAM_TILES = 0xCD00 - RAM_BASE
RAM_ROUND = 0xE64B - RAM_BASE
RAM_DRAW_ROW = 0xE5C4 - RAM_BASE  # next row to draw; 0x20 once the round is drawn


def record(bank1: bytes, r: int) -> bytes:
    o = palette.ROUND_RECORDS + r * palette.ROUND_RECORD_SIZE
    return bank1[o:o + palette.ROUND_RECORD_SIZE]


def edge(bank1: bytes, index: int, size: int) -> bytes:
    ptr = struct.unpack_from("<H", bank1, GRID_EDGES + 2 * index)[0] - 0x8000
    return bank1[ptr:ptr + size]


def grid(bank1: bytes, sub: bytes, r: int) -> bytes:
    """ROUND_GRID for round r (0-based) as the game builds it: 0x200 bytes."""
    patterns = record(bank1, r)[3]
    src = sub[ROUND_LAYOUTS + r * LAYOUT_BYTES:][:LAYOUT_BYTES]
    bits = int.from_bytes(src, "big")
    total = LAYOUT_BYTES * 8
    mid = bytearray()
    for i in range(0, LAYOUT_CELLS, 2):
        pair = (bits >> (total - 3 * (i + 2))) & 0x3F
        mid.append((pair >> 3) << 4 | (pair & 7))
    return edge(bank1, patterns >> 4, TOP_BYTES) + bytes(mid) + edge(bank1, patterns & 15, BOTTOM_BYTES)


def cells(g: bytes) -> list[list[int]]:
    """[row][col] cell values."""
    return [[(g[row * ROW_BYTES + col // 2] >> (0 if col & 1 else 4)) & 15
             for col in range(GRID_COLS)] for row in range(GRID_ROWS)]


def word(tile: int, colour: int) -> int:
    return ((tile >> 8) | colour << 2) << 8 | (tile & 0xFF)


def tile_words(r: int, g: bytes, patterns: int) -> list[list[int]]:
    """[col][row] tile entries for the playfield, as DRAW_GRID_ROW, SHADE_GRID_ROW and the
    side-wall pass (1A99) leave them."""
    colour = 15 if r & 1 else 14
    wall = word(WALL_TILE + TILES_PER_ROUND * r, colour)
    c = cells(g)
    t = [[wall if c[row][col] == 0 else 0 for row in range(GRID_ROWS)] for col in range(GRID_COLS)]

    def at(col: int, row: int) -> int:
        return t[col][row] if 0 <= col < GRID_COLS and 0 <= row < GRID_ROWS else 0

    for row in range(GRID_ROWS):
        for col in range(GRID_COLS):
            if t[col][row]:
                continue
            up = at(col, row - 1) == wall
            left = at(col - 1, row) == wall
            corner = at(col - 1, row - 1)
            # SHADE_GRID_ROW compares the two bytes one at a time: "not a wall" for F1
            # needs both to differ, for F3 only the high byte of the cell to the left.
            corner_wall = corner == wall
            corner_clear = (corner & 0xFF) != (wall & 0xFF) and (corner >> 8) != (wall >> 8)
            left_high = (at(col - 1, row) >> 8) == (wall >> 8)
            if up and left:
                s = 0
            elif left and corner_clear:
                s = 1
            elif up and corner_wall:
                s = 2
            elif corner_wall and not left_high:
                s = 3
            elif left:
                s = 4
            elif up:
                s = 5
            else:
                continue
            t[col][row] = colour << 10 | SHADOW + s
    # Row 0 of columns 9 and 19 gets low byte F4 unless ROUND_RECORD byte 3 b7 / b5.
    for col, bit in ((9, 0x80), (19, 0x20)):
        if not patterns & bit:
            t[col][0] = t[col][0] & 0xFF00 | 0xF4
    side = SIDE_TILE + TILES_PER_ROUND * r
    for row in range(GRID_ROWS):
        for col in (0, 30):
            if t[col][row] == wall:
                first = side + (2 if row & 1 else 0)
                t[col][row] = word(first, colour)
                t[col + 1][row] = word(first + 1, colour)
            else:
                t[col][row] = t[col + 1][row] = 0
    return t


def tile_block(t: list[list[int]]) -> bytes:
    out = bytearray(GRID_COLS * GRID_ROWS * 2)
    for col in range(GRID_COLS):
        for row in range(GRID_ROWS):
            o = col * GRID_ROWS * 2 + row * 2
            out[o] = t[col][row] & 0xFF
            out[o + 1] = t[col][row] >> 8
    return bytes(out)


class Painter:
    def __init__(self, files: dict[str, bytes], pal: dict):
        self.low, self.high = gfx.planes(files)
        self.pal = pal
        self.tiles: dict[int, bytes] = {}

    def tile(self, code: int) -> bytes:
        t = self.tiles.get(code)
        if t is None:
            t = self.tiles[code] = gfx.decode_tile(self.low, self.high, code)
        return t

    def render(self, r: int, t: list[list[int]]) -> Image.Image:
        """The visible 256 x 224 playfield; colour 15 and the score rows are black."""
        top, bottom = VISIBLE_ROWS
        pens = bytearray([16]) * (256 * (bottom - top) * 8)
        for col in range(GRID_COLS):
            for row in range(FIRST_ROW, LAST_ROW + 1):
                w = t[col][row]
                if not w:
                    continue
                code = (w >> 8 & 3) << 8 | (w & 0xFF)
                pix = self.tile(code)
                for y in range(8):
                    base = ((row - top) * 8 + y) * 256 + col * 8
                    for x in range(8):
                        p = pix[y * 8 + x]
                        if p != 15:
                            pens[base + x] = p
        cols = self.pal["round"]["palettes"][self.pal["round"]["index_by_round"][r]]
        img = Image.new("P", (256, (bottom - top) * 8))
        img.putpalette([int(c[i:i + 2], 16) for c in cols for i in (1, 3, 5)] + [0, 0, 0])
        img.frombytes(bytes(pens))
        return img


def round_json(r: int, rec: bytes, g: bytes, sub_offset: int) -> dict:
    c = cells(g)
    counts = [rec[4 + i // 2] >> (0 if i & 1 else 4) & 15 for i in range(6)]
    return {
        "round": r + 1,
        "record": {
            "source": f"bank1:{0x8000 + palette.ROUND_RECORDS + r * palette.ROUND_RECORD_SIZE:04X}",
            "bytes": rec.hex(" "),
            "palette": rec[0],
            "top_edge": rec[3] >> 4,
            "bottom_edge": rec[3] & 15,
            "enemy_counts": counts,
            "enemy_swap": rec[12],
        },
        "layout_source": f"sub:{sub_offset:04X}",
        "wall_tile": f"{WALL_TILE + TILES_PER_ROUND * r:03X}",
        "side_tiles": f"{SIDE_TILE + TILES_PER_ROUND * r:03X}",
        "colour": 15 if r & 1 else 14,
        "cells": "0 = wall, 1-4 = open (air current); row 0 at the top, rows 4-29 on screen",
        "grid": ["".join(str(v) for v in row) for row in c],
    }


def check(images: dict[str, bytes], folder: Path) -> int:
    bank1, sub = images["main_bank1.bin"], images["sub.bin"]
    grids = [grid(bank1, sub, r) for r in range(ROUNDS)]
    blocks = [tile_block(tile_words(r, grids[r], record(bank1, r)[3])) for r in range(ROUNDS)]
    keep = [i for i in range(len(blocks[0])) if (i % (GRID_ROWS * 2)) // 2 >= FIRST_ROW]
    bad = 0
    for f in sorted(folder.glob("ram_*.bin")):
        ram = f.read_bytes()
        r = ram[RAM_ROUND]
        g = ram[RAM_GRID:RAM_GRID + GRID_ROWS * ROW_BYTES]
        if r >= ROUNDS or not any(g[TOP_BYTES:-BOTTOM_BYTES]):
            continue
        # The grid can be a round behind ROUND_MAIN (the 1P ending's warp keeps round 100's).
        match = [n for n in range(ROUNDS) if grids[n] == g]
        if not match:
            print(f"{f.name}: round {r + 1}: grid matches no round")
            bad += 1
            continue
        n = match[0]
        drawn = ram[RAM_DRAW_ROW] == GRID_ROWS
        block = ram[RAM_TILES:RAM_TILES + len(blocks[n])]
        same = all(block[i] == blocks[n][i] for i in keep)
        state = "tiles match" if same else ("tiles differ" if drawn else "still drawing")
        print(f"{f.name}: round {n + 1}: grid matches, {state}")
    return bad


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--roms", type=Path, help="ROM directory or zip")
    ap.add_argument("--out", type=Path, default=ROOT / "build" / "levels")
    ap.add_argument("--scale", type=int, default=1, help="integer magnification")
    ap.add_argument("--check", type=Path, nargs="+", metavar="SNAPDIR")
    args = ap.parse_args()
    try:
        files = romset.load(args.roms)
    except romset.RomError as e:
        print(e, file=sys.stderr)
        return 1
    images = romset.images(files)
    if args.check:
        return 1 if sum(check(images, d) for d in args.check) else 0
    bank1, sub = images["main_bank1.bin"], images["sub.bin"]
    painter = Painter(files, palette.extract(images["main_fixed.bin"], bank1))
    args.out.mkdir(parents=True, exist_ok=True)
    thumbs = []
    for r in range(ROUNDS):
        rec = record(bank1, r)
        g = grid(bank1, sub, r)
        name = f"round_{r + 1:03d}"
        doc = round_json(r, rec, g, ROUND_LAYOUTS + r * LAYOUT_BYTES)
        (args.out / f"{name}.json").write_text(json.dumps(doc, indent=1) + "\n")
        img = painter.render(r, tile_words(r, g, rec[3]))
        thumbs.append(img.convert("RGB"))
        if args.scale > 1:
            img = img.resize((img.width * args.scale, img.height * args.scale), Image.NEAREST)
        img.save(args.out / f"{name}.png")
    w, h = thumbs[0].size
    sheet = Image.new("RGB", (10 * (w + 4), 10 * (h + 4)), (40, 40, 40))
    for r, img in enumerate(thumbs):
        sheet.paste(img, ((r % 10) * (w + 4) + 2, (r // 10) * (h + 4) + 2))
    sheet = sheet.resize((sheet.width // 2, sheet.height // 2), Image.LANCZOS)
    sheet.save(args.out / "rounds.png")
    print(f"{ROUNDS} rounds: round_001-{ROUNDS:03d}.json/.png, rounds.png -> {args.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
