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
| 1 | open, the air moves bubbles up |
| 2 | open, right |
| 3 | open, left |
| 4 | open, down |

The game reads cells through `GRID_CELL` (`174B`: object X in H, Y in L), and object code
probes the cells around a sprite with it, so the grid is also the collision map. It is also
the air current. `BUBBLE_DRIFT` (`6175`) moves a floating bubble one pixel by the value of
its cell (`IX+0A`), through the table at `61F4`: 0 and 1 add 1 to Y (up the screen), 2 adds
1 to X, 3 takes 1 from X, 4 takes 1 from Y. 5 and 6 would leave it still, but no layout uses
them. A bubble reads its cell again (`61E4`) only when it reaches an 8-pixel boundary in the
direction it is moving. `BUBBLE_SPEED` (`6144`) decides how many pixels a frame, from the
speed pattern that record byte 9 selects (below). In round 1, rows 5–8 are 2 on the left, 3
on the right and 4 in the middle, so the bubbles gather under the ceiling in the centre.

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

## The round record

`ROUND_RECORDS` (`bank1:A73A`) holds 0x2B bytes a round. `LOAD_ROUND_REC` (`1775`) copies
the current one to `ROUND_RECORD` (`E598`) and then changes some bytes (next section).
`tools/levels.py` writes the decoded fields into each `round_NNN.json`. Positions are
object coordinates, Y first: a 16 × 16 sprite's top left is at screen (X, −Y mod 256).

| Byte | Field | Read by |
|---|---|---|
| 0 | Round palette, an index into `ROUND_PALETTES` | `LOAD_ROUND_PAL` (`0B43`) |
| 1–2 | Y, X of the points item | `POINTS_RUN` (`bank2:8499`) |
| 3 | Ceiling and floor patterns (high, low nibble) and the row 0 gaps (b7, b5) | `LOAD_GRID_EDGES`, `SHADE_GRID_ROW`, `SPAWN_BUBBLE` |
| 4–6 | Enemies in groups 0–5, one nibble each, high nibble first | `ROUND_ENEMIES` (`bank0:85A9`) |
| 7 | Seconds an enemy stays in a bubble before it escapes | `5DFC`, into the bubble's `IX+0D` |
| 8 | Enemy speed: a row of `SPEED_PATTERNS` (`11CE`); +6 (up to 0x28) when angry | `ENEMY_SPEED` (`bank0:885A`), every kind |
| 9 | Bubble speed: copied to the MCU's `SPEED2_SEL` (`FC76`) | `5BA3`; `BUBBLE_SPEED` (`6144`) |
| 10–11 | Y, X of the special item | `SPECIAL_RUN` (`bank2:8686`) |
| 12 | `ENEMY_SWAP`: b0 group 0 is the second kind, b4 group 2 is | the enemy inits |
| 13 | Seconds until HURRY UP; no special item appears in the last 3 | `HURRY_CHECK` (`0742`) |
| 14 | Round palette in the super mode: (byte 14 + 3) mod 8 | `LOAD_ROUND_PAL` (`0B5B`) |
| 15 | Seconds after HURRY UP until Skel-Monsta comes | `GHOST_CLOCK` (`085F`) |
| 16 | Always 1; nothing reads it | — |
| 17–37 | Seven 3-byte enemy entries: delay, X, Y | `ENEMY_ENTRY` (`bank0:87BE`) |
| 38–41 | How many of the 16 `SPECIAL_LIST` entries are lightning, water, fire, and type 4 | `5BB3` |
| 42 | Enemy n's facing: bit n set gives `IX+7`/`IX+8` = 1, clear 3 | `ENEMY_ENTRY` |

**Enemies.** Every enemy kind's init calls `ENEMY_ENTRY` with `IX+9` = the enemy's number
in the round, counted across the groups in the order `ROUND_ENEMIES` sets them up
(`ED46`). Entry n gives the delay in frames, the X position (set at once) and the Y it
drops to. `ENEMY_DROP` (`bank0:8805`) waits the delay, moves Y one pixel a frame to the
target, then waits 0xB4 frames before the enemy starts (no wait in round 1). In round 1 the
three Zen-chan all use X 120 and Y 144, with delays 1, 21 and 41: they drop in one after
another. Entries past the round's enemy count are zero, apart from a seventh entry in
round 100, which has six enemies.

**Items.** Two items appear in each round, each with its own timer and state (`POINTS_*`
and `SPECIAL_*` in `symbols.toml`). The points item appears at bytes 1–2 after 0x1A4
frames, the special item at bytes 10–11 after 0x2D0 (both 0xF0 when `F44D` is set). Each
stays for 0x258 or 0x384 frames. The special item never appears once `NO_SPECIAL` is set,
or with no enemies left. Which item is chosen (`POINTS_PICK`, `SPECIAL_PICK`) depends on
counters of what the players have done, not on the record; that is still to decode.

**Special bubbles.** `5BB3` fills `SPECIAL_LIST` (`E745`, 16 bytes) in order: byte 38
entries of 1, byte 39 of 2, byte 40 of 3, byte 41 of 4. `SPAWN_BUBBLE` (`6D9B`) makes a
bubble come out of the floor or ceiling gaps every 0x80 frames while there are fewer than 16,
and may give it the type at a random entry of the list. The pop handlers show what the types
are: 1 is lightning (`66A1`), 2 water (`660D`) and 3 fire (`6633`). Type 4 sets b4 of the
bubble's `IX+21` and draws tile 0xC4 (`6E61`); what it is, is not known yet. In the rounds
with special bubbles the four bytes add up to 3–16.

## Difficulty and the super mode

After the copy, and only when `ROUND_MAIN` is not 0x64 (the title), `LOAD_ROUND_REC`
changes the record:

- **Super mode** (`SUPER_MODE`, `E5DB`, nonzero): `ENEMY_SWAP` b4 is toggled and b0
  cleared, and the enemy counts of groups 0 and 3, and of 4 and 5, change places. Byte 3,
  the walls, stays the same, and byte 14 picks the palette.
- **Difficulty** (`DIFFICULTY`, `E5DC`, 0–0x1E). `22C6` (called from `1DFA`) sets it from
  DSW1 b0–1 through the table at `22D6` (0x0D, 0x0A, 0x04, 0x07), and `2B3A` and `2EE0`
  set it to 7. It moves during play: `22F0` adds C (called from `32EF`, `3303`) and
  `22FE` takes C away, down to no less than `E5DD` (called from `4080`, `4153`, `4189`). Byte 7 gets the signed step at `1851 + DIFFICULTY`: +7 at 0, 0 at
  7, −8 from 15, at least 1. From 0x10 up, bytes 13, 15 and 8 get the steps at `1870`,
  `187F` and `188E` + (DIFFICULTY − 0x10), with byte 13 at least 5, byte 15 at least 2 and
  byte 8 at most 0x1E. So a harder game has shorter trap times, an earlier HURRY UP and
  Skel-Monsta, and faster enemies.

## Check

`python tools/levels.py --check build/snaps/*/snap` rebuilds the grid and the tile
columns from the ROMs. It compares them with every RAM snapshot taken in a round. All 36
grids match a decoded round: rounds 1, 2, 50 and 100. Where the round had finished
drawing, the tile columns match too, rows 4–31 byte for byte. The rest are the title,
high-score and ending screens, which draw over the playfield. One snapshot in the 1P
ending holds round 100's grid while `ROUND_MAIN` already says round 50.

It also replays `LOAD_ROUND_REC` and compares the result with `ROUND_RECORD` in RAM.
All 35 records that can be checked match. In 11 of them, the snapshot's `DIFFICULTY` had
moved after the round started. Each of these matches one earlier value, and those values
fit one game: round 1 loaded at 7 and round 2 at 5, and in the snapshots after each load
the value only fell.

The round 1 preview matches MAME's screenshot of round 1.

## Still open

- Bubble type 4 (record byte 41).
- How `POINTS_PICK` and `SPECIAL_PICK` choose the item, and the effect table at
  `bank2:8AFF`.
- What sets `SUPER_MODE` (`20C7`), and a traced super-mode round to check the swaps.
- What moves `DIFFICULTY` up and down.
- Round 100's walls are drawn as usual, but the boss and the endings draw over them.
