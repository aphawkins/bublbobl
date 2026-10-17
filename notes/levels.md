# Levels

How a round's walls are stored and drawn, from the code and checked against RAM snapshots.
`tools/levels.py` decodes all 100 rounds into `build/levels/round_NNN.json` and `.png`, plus
`rounds.png` with all 100 on one sheet. `round_NNN_super.png` and `rounds_super.png` show
the rounds in the super mode's palettes, and `items.json` holds the item tables.

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
  Then it sets `GRID_REQUEST` to FF. The 100 layouts fill sub `0CFC–7D7B`. Two more
  follow: layout 100 (`ATTRACT_LAYOUT`, `7D7C`) is in `ROUND_GRID` in every attract and
  title snapshot, where `ROUND_MAIN` is 0x64; layout 101 (`7E9C`) is in no trace or
  snapshot. This is most of what the sub CPU's ROM holds. The rest of the sub CPU is the
  hit tests (`notes/sub.md`).
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
or with no enemies left. Which item comes depends on what the players have done, not on the
record (next section).

**Special bubbles.** `5BB3` fills `SPECIAL_LIST` (`E745`, 16 bytes) in order: byte 38
entries of 1, byte 39 of 2, byte 40 of 3, byte 41 of 4. `SPAWN_BUBBLE` (`6D9B`) makes a
bubble come out of the floor or ceiling gaps every 0x80 frames while there are fewer than 16,
and may give it the type at a random entry of the list. The pop handlers show what the types
are: 1 is lightning (`66A1`), 2 water (`660D`) and 3 fire (`6633`). In the rounds with
special bubbles the four bytes add up to 3–16.

Type 4 never appears. Only round 100 lists it (2 of 16), and `SPAWN_BUBBLE` makes no bubbles
when byte 3 is `AA`, the closed ceiling and floor, as in round 100. Rounds 41, 44 and 93 also
list special bubbles under a closed ceiling and floor, so theirs never appear either; a
traced round 100 never ran the spawn code. Its handler (`6E61`) draws tiles `0C4–0C7` and
sets b4 of the bubble's `IX+21`, which no code tests, and unlike types 0–3 it gives the
bubble no state in `IX+0`.

## Items

`POINTS_PICK` (`bank2:83E8`) and `SPECIAL_PICK` (`bank2:85EB`) run at round start (`3E0B`,
`3E0E`). `items.json` holds their tables.

**The points item** (`POINTS_KIND`) is the first that applies of:

1. In the attract demo (`ATTRACT`, `E5D3`): 0x14 + a random 0–31.
2. On round 1: 0x15 + a random 0–15.
3. A flag from the last round, through `POINTS_FLAGS` (`8463`), cleared when used: Skel-Monsta
   came (`F454`, kinds 0–9 and 0–5), HURRY UP came (`F453`, kinds 0A–13 and 0A–0F), or a
   special item of kind 06–08 was taken (`F452`, every third kind from 01 to 2F). The kind is one of the 16 at
   random.
4. Otherwise the time the last round took, in seconds (`ROUND_CLOCK`, `F456`, which a
   death does not reset, unlike `ROUND_SECONDS`): kind 0x31 − s,
   down to 0x14 at 0x1D s, in a 1P game; 0x3B − s, down to 0x14 at 0x27 s, with two players.
   So a quick round gives a higher kind.

`POINTS_PICK` then clears `F44E–F456`, so the clock and the flags start again.

**The special item** (`SPECIAL_KIND`):

- None in the attract demo or on round 100.
- If `SKIP_KINDS` (`E612`) is set, it counts down and gives kinds 0B, 0A, 09 in turn. Kind
  2F's effect sets it to 3 (`8AA9`).
- Otherwise `SPECIAL_RULES` (`B4F2`): 0x36 rules, tried from kind 0x35 down to 0. Each has a
  counter in RAM and four thresholds; `SPECIAL_CLASS` (`8667`) picks the column by
  `DIFFICULTY` (0–4, 5–7, 8–11, 12 and up). The first counter at or past its threshold wins
  and is cleared. If none has, no special item comes this round. Kind 0E does not appear:
  it calls `90DD` and sets `F513` to FF instead.

The counters count what the players do. Several counters feed more than one rule with rising
thresholds, and the higher kind is tried first: `E5E3` gives kind 06 at 15, 07 at 20 and 08 at
25, and these three set `E350` to 3, 5 and 7 when taken, probably the umbrellas that skip 3, 5
and 7 rounds.
`E5E7` gives kinds 09–0D at 15–19. Counters confirmed so far: `E5F6` counts the special items
taken (`8794`), `E5FE` the HURRY UPs (`0839`) and `E611` the times Skel-Monsta came (`0888`),
which gives kind 30. `E5F4` counts the enemies killed by a bubble in state b5 (sub `0572`). Kind 2E sets `F44D` (`8AA3`), so both items come after 0xF0 frames. The
rest of the counters are listed by address in `items.json`; what each counts is still open.

`BANK2_CHECK` (`85AE`), called from kind 0's effect (`87B1`), `9104`, `A318` and `A978`, is
a tamper check: it adds
one byte a call of bank 2 `9532–B787`, every other byte, and at the end compares the sum
with `BANK2_SUM` (`F45D`), which `2529` copies from bank 3 `938A` (`FA`, the right sum). If
they differ it pushes AF and runs on into `SPECIAL_PICK`, so the pick's RET returns to the
wrong place.

## Difficulty and the super mode

After the copy, and only when `ROUND_MAIN` is not 0x64 (the title), `LOAD_ROUND_REC`
changes the record:

- **Super mode** (`SUPER_MODE`, `E5DB`, nonzero): `ENEMY_SWAP` b4 is toggled and b0
  cleared, and the enemy counts of groups 0 and 3, and of 4 and 5, change places. Byte 3,
  the walls, stays the same. `LOAD_ROUND_PAL` uses byte 14 + 3, less 8 from 8 up, in
  place of byte 0.
- **Difficulty** (`DIFFICULTY`, `E5DC`, 0–0x1E). `22C6` (called from `1DFA`) sets it from
  DSW1 b0–1 through the table at `22D6` (0x0D, 0x0A, 0x04, 0x07), and `2B3A` and `2EE0`
  set it to 7. It moves during play: `22F0` adds C (called from `32EF`, `3303`) and
  `22FE` takes C away, down to no less than `E5DD` (called from `4080`, `4153`, `4189`). Byte 7 gets the signed step at `1851 + DIFFICULTY`: +7 at 0, 0 at
  7, −8 from 15, at least 1. From 0x10 up, bytes 13, 15 and 8 get the steps at `1870`,
  `187F` and `188E` + (DIFFICULTY − 0x10), with byte 13 at least 5, byte 15 at least 2 and
  byte 8 at most 0x1E. So a harder game has shorter trap times, an earlier HURRY UP and
  Skel-Monsta, and faster enemies.

### Entering the super mode

On the title screen (from boot to about frame 450, and each time the attract loop shows
it), `CODE_CHECK` (`1BCF`) records the first 8 changes of player 1's inputs in
`CODE_INPUTS` (`E5C8`). Releasing every input does not count, so a code never repeats an
input twice in a row. The 8th is compared with the three codes at `TITLE_CODES` (`1CBE`),
where S is Start, J jump (button 2), B bubble (button 1), L and R the joystick:

| Code | Result |
|---|---|
| S J B L R J S R | `SUPER_MODE` = 1 and the "Super" logo (`1C06`) |
| B J B J B J R S | after the ROM checks at `1C3D`, "ORIGINAL GAME..." and `ORIGINAL_GAME` (`E5D1`); a failed check prints "DEAD COPY GAME !!!" |
| L J L S L B L S | "POWER UP!" and `POWER_UP` (`E5D2`) |

When a game starts with `SUPER_MODE` set, `MODE_SELECT` (`2931`) shows SELECT GAME MODE with
NOMAL GAME (the ROM's spelling) and SUPER GAME. Left clears `SUPER_MODE` (`29F6`), right
sets it (`2A18`), and either button starts. After 0x4B0 frames (20 s) it clears
`SUPER_MODE` and starts the normal game (`29C6`). Both ways back to the attract loop (`1F10`,
`1FDE`) clear all three flags. `SUPER_MODE` also changes the 2P ending (`5651`, `bank0:ABA5`,
`1EC4`).

`trace.py super1p` enters the code, picks SUPER GAME and plays. Round 1 has palette 0 in
place of 5, and its three enemies move from group 0 to group 3. `--check` matches the
record and the palette (`build/snaps/snap_super1p`). Round 77 (`--round 77`,
`snap_super_r77`) tests every swap, since its record has `ENEMY_SWAP` b0 and enemies in
groups 4 and 5, and it matches as well.

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

The round palette (palette 14 or 15) is checked too, wherever the round is on screen: all 35
match, 14 of them in the super mode.

The round 1 preview matches MAME's screenshot of round 1.

## Still open

- What most of the `SPECIAL_RULES` counters count, and each kind's effect
  (`SPECIAL_EFFECTS`, `bank2:8AFF`) and name.
- What `ORIGINAL_GAME` changes (read at `227C`), and what `F463` does.
- What moves `DIFFICULTY` up and down.
- Whether layout 101 (sub `7E9C`) is ever used.
- Round 100's walls are drawn as usual, but the boss and the endings draw over them.
