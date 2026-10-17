# Levels

How a round's walls are stored and drawn, from the code and checked against RAM snapshots.
`tools/levels.py` decodes all 100 rounds into `build/levels/round_NNN.json` and `.png`, plus
`rounds.png` with all 100 on one sheet.

## The grid

A round is `ROUND_GRID` (`E398–E597`): 32 rows of 32 cells, each cell 8 × 8 pixels, so the
grid covers the whole 256 × 256 frame. A row is 16 bytes, two cells a byte, high nibble
first. The values seen in the 100 rounds are 0–4:

| Value | Meaning |
|---|---|
| 0 | wall |
| 1–4 | open |

The game reads cells through `GRID_CELL` (`174B`: object X in H, Y in L), and object code
probes the cells around a sprite with it, so the grid is also the collision map. The open
values look like the air current that carries bubbles. In round 1, rows 5–8 are 2 on the
left, 3 on the right and 4 in the middle, and the rest is 1. Bubbles rise there and gather
at the top centre, which fits 1 = up, 2 = right, 3 = left, 4 = hold or down. The code that
acts on the values has not been traced yet, so this reading is not confirmed.

Rows 0–3 are behind the score line and rows 30–31 are below the screen, so rows 4–29 are
the visible playfield.

## Where it comes from

Three pieces fill the grid at round start:

- **Rows 5–28 (`E3E8`, 0x180 bytes) come from the sub CPU.** `LOAD_GRID_EDGES` (`1700`)
  sets `GRID_REQUEST` (`E397`) to 1 and waits. The sub CPU's `GRID_UNPACK` (sub `00A9`)
  reads 0x120 bytes at `ROUND_LAYOUTS` (sub `0CFC`) + round × 0x120. It treats them as a
  bit stream, 3 bits a cell, and writes each pair of cells as bits 6-4 and 2-0 of one byte.
  Then it sets `GRID_REQUEST` to FF. The 100 layouts fill sub `0CFC–7D7B`. This is most of
  what the sub CPU's ROM holds.
- **Rows 0–4 and 29–31 come from bank 1.** `ROUND_RECORD` byte 3 holds two pattern
  numbers. The high nibble picks a 0x50-byte top pattern (rows 0–4) and the low nibble a
  bottom one (rows 29–31), both through entries 0–15 of `GRID_EDGES` (`bank1:95AA`). The
  bottom copy is the first 0x30 bytes of a top pattern. Entries 16–31 point at
  `GRID_EDGE_LOW` (`98BA`): 0x30-byte copies of those same bytes, which this code never
  reads. The patterns are the ceiling and the floor, with or without the gaps at columns
  9–12 and 19–22. All nine patterns are used. Byte 3 takes the values 00, 04, 15, 19, 22,
  48, 4A, 50, 55, 5A, 6A, 88, 99, A0 and AA.

## Drawing

There is no tilemap (see `tools/objects.py`). The walls are tile columns at `CD00–D4FF`,
0x40 bytes a column, 2 bytes a row: the tile's low byte, then (tile >> 8) | colour << 2.
`GRID_DRAW_ROW` (`E5C4`) counts the rows from 0 to 0x20 during the round's opening, and
each frame draws one row:

- `DRAW_GRID_ROW` (`1958`) puts the wall tile in every 0 cell. The wall tile is 0x208 +
  5 × round (0-based), from `GRID_WALL_TILE` (`1929`), in colour 14 on even rounds and 15
  on odd ones. These are the palettes `LOAD_ROUND_PAL` fills from the round's palette index.
- `SHADE_GRID_ROW` (`199C`) gives open cells next to a wall a shadow tile, F0–F5, chosen by
  the cells above, to the left and above-left. Then, in row 0 only, column 9 gets F4 unless
  byte 3 b7 is set, and column 19 gets F4 unless b5 is set.
- `SIDE_WALL_ROW` (`1A99`) replaces columns 0–1 and 30–31 with the 2 × 2 block at
  0x204 + 5 × round, where those cells hold the wall tile, and clears them where they don't.
  It runs two rows behind the others.

So each round owns five tiles: four for the side-wall block and one for the walls.

## Check

`python tools/levels.py --check build/snaps/*/snap` rebuilds the grid and the tile
columns from the ROMs. It compares them with every RAM snapshot taken in a round. All 36
grids match a decoded round: rounds 1, 2, 50 and 100. Where the round had finished
drawing, the tile columns match too, rows 4–31 byte for byte. The rest are the title,
high-score and ending screens, which draw over the playfield. One snapshot in the 1P
ending holds round 100's grid while `ROUND_MAIN` already says round 50.

The round 1 preview matches MAME's screenshot of round 1.

## Still open

- What the open values 1–4 do (the bubble code that reads them).
- The rest of the round record: bytes 1–2, 7–11 and 13–42.
- `LOAD_ROUND_REC` changes the record when `E5DB` is nonzero, probably the super mode. It
  toggles `ENEMY_SWAP` b4, clears b0 and swaps the counts of groups 0 and 3 (bytes 4–5).
  It goes on from `17CE`, not yet read. The part read so far leaves byte 3, the walls, alone.
- Round 100's walls are drawn as usual, but the boss and the endings draw over them.
