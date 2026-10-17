# Bubble Bobble (Taito, 1986) — Code & Data Extraction Plan

Goal: turn the `bublbobl` arcade ROM set into a documented, rebuildable understanding of the
game — annotated disassemblies for all four CPUs plus extracted, viewable data (graphics,
palettes, text, levels, enemy tables, music) in open formats.

This file covers stages 1 and 2 of [PLAN.md](PLAN.md): disassembly to source, and
reassembly to a byte-exact set that runs in MAME. Stage 3, the C# reimplementation in
The Sharp Kind, consumes what these stages produce and is planned in `PLAN.md`.

Reference sources:
- ROMs: `roms\bublbobl\` (and `roms\bublbobl.zip`) — not in the repo; supply your own
- MAME driver: [mamedev/mame](https://github.com/mamedev/mame), cloned alongside this repo at
  `..\..\mamedev\mame` — `src\mame\taito\bublbobl.cpp`,
  `bublbobl_m.cpp` (MCU/IO glue), `bublbobl_v.cpp` (video), `bublbobl.h`
- MAME binaries: `C:\Games\Retro\mame` (`mame.exe`, `unidasm.exe`) — not on PATH; scripts
  read `MAME_DIR` from `config.local.toml`

> **The repo holds no ROM bytes.** Source in `src\` contains only what has been
> disassembled. Every region not yet understood is pulled in at build time from the
> verified images in `build\images\` with `.incbin`. So `src\` never builds without
> the user's ROMs, and nothing in the repo is a copy of a ROM.

---

## 1. The ROM set

The set exactly matches MAME's parent **`bublbobl` — Bubble Bobble (Japan, Ver 0.1)**.

| File | Size | CRC32 | CPU / use | Notes |
|---|---|---|---|---|
| `a78-06-1.51` | 32K | 567934b6 | Main Z80, fixed `0000–7FFF` | Game logic, text, "dead copy" tamper trap |
| `a78-05-1.52` | 64K | 9f8ee242 | Main Z80, banked `8000–BFFF` (4 × 16K) | Test mode, endings, credits, version stamp |
| `a78-08.37` | 32K | ae11a07b | Sub Z80 `0000–7FFF` | No readable text; role to be established |
| `a78-07.46` | 32K | 4f9a26e8 | Sound Z80 `0000–7FFF` | Music/SFX driver + data (YM2203 + YM3526) |
| `a78-01.17` | 4K | b1bfb53d | MC6801U4 MCU `F000–FFFF` | Protection/IO MCU, dated "29.JUN,1986" |
| `a78-09`…`a78-14` | 6 × 32K | — | Graphics, planes 0–1 | |
| `a78-15`…`a78-20` | 6 × 32K | — | Graphics, planes 2–3 | |
| `a71-25.41` | 256B | 2d0f8545 | Video timing / object-layout PROM | Used by the renderer, see §6 |

Known landmarks already found:
- `a78-05-1.52` @ `0xFF4C`: `VER 0.1 4.SEP,1986 SUMMER` (Ver 0.0 was `18.AUG,1986`).
- `a78-06-1.51` @ `0x333F`: tamper check — reads ROM `0x0B2E`, expects `0x4D`; on failure
  falls into the ASCII `dead copy` (`334A–3352`), which executes as Z80 opcodes and derails
  the CPU. The `:` after it is `3A`, the first byte of the routine at `3353` (`ld a,($E5D3)`),
  which runs in normal play.
- `a78-06-1.51` @ `0x37DF`: 3-letter name table (default high-score initials?), loaded at `0x375A`.
- MCU `F8F1`: EXTEND letter = shared RAM `FC7C`, incremented mod 6 every vblank.
- Strings are **length-prefixed ASCII** (e.g. `10 "SELECT GAME MODE"`, `13 "ALL RIGHTS RESERVED"`).
- The font is in tile bank 0 at the ASCII codes (`0x20–0x5F`, `@` drawn as ©), so a
  string's bytes are its tile numbers.
- Free space (`0xFF` runs) in `a78-05-1.52`: `0x785C`(+7A4), `0xBC9F`(+361), `0xD583`(+287D).
  `a78-06-1.51` has none.

> ROMs are copyrighted. Keep them **out of version control**; scripts take the ROM directory
> as an argument (or read `ROM_DIR` from a local, git-ignored config).

---

## 2. Hardware model (what every tool must agree on)

### Main Z80 (6 MHz)
| Range | Use |
|---|---|
| `0000–7FFF` | `a78-06-1.51` |
| `8000–BFFF` | Bank window into `a78-05-1.52`. Write to `FB40`: entry = `(data ^ 4) & 7`. Entries 0–3 = file offsets `0x0000/0x4000/0x8000/0xC000`; entries 4–7 = empty socket IC53. So the game writes **4–7** to select file pages 0–3. |
| `C000–DCFF` | "Video RAM" — actually tile-column data for objects (see §6) |
| `DD00–DFFF` | Object RAM (4 bytes per object: Y, gfx#, X, attr) |
| `E000–F7FF` | Work RAM shared with sub CPU |
| `F800–F9FF` | Palette RAM, 256 × RGBx_444 big-endian (2 bytes/colour) |
| `FA00` | Sound command (W) / sound reply (R) |
| `FA01` | Sound semaphores (R) |
| `FA03` | Sound CPU reset |
| `FA80` | Watchdog |
| `FB00` | NMI to sub CPU |
| `FB40` | Bank (bits 0–2), sub-CPU reset (b4), MCU reset (b5), video enable (b6), flip (b7) |
| `FC00–FFFF` | RAM shared with the MCU |

Interrupts: main CPU runs in **IM 2**; the MCU raises IRQ and the vector byte is read from
shared RAM `FC00`. Reset code is `DI / IM 2 / JP 00B9`.

### Sub Z80
`0000–7FFF` ROM, `E000–F7FF` shared work RAM, IRQ on vblank.

### Sound Z80
`0000–7FFF` ROM, `8000–8FFF` RAM, `9000/9001` YM2203, `A000/A001` YM3526,
`B000` command latch (R) / reply (W), `B001`/`B002` NMI enable/disable.
IRQs come from the sound chips; NMI from the main-CPU command latch.

### MCU (MC6801U4, 4 MHz/4)
ROM `F000–FFFF`. Vectors: RESET `F000` (→ `FEBB` test-jig check → `F003` start), IRQ1
(vblank) `F046`, OCF `F092` (never enabled; `F092` is the coin job, called from IRQ1).
The full contract with the main CPU is in `notes\mcu_shared_ram.md`. Shared-RAM access is through ports:
port 4 = address low, port 2 b0–3 = address high, b4 = strobe, port 1 b7 = read/write,
port 3 = data. Helpers: `F1BF` read (X=addr → B), `F1DB` write (B → X=addr).
Addresses `0x000–0x003` select DSW0/DSW1/IN1/IN2; `0xC00–0xFFF` = shared RAM.

---

## 3. Work area layout

```
bublbobl\                     ← repo root
  PLAN.md                     ← overall plan (all three stages)
  EXTRACTION_PLAN.md          ← this file
  README.md                   ← how to run everything
  config.local.toml           ← ROM_DIR etc. (git-ignored)
  tools\                      ← Python extraction scripts
    romset.py                 ← load + CRC-verify the set, build per-CPU images
    gfx.py, palette.py, text.py, levels.py, sound.py, ...
    build.py                  ← assemble src\ → build\roms\bublbobl\ and verify CRCs
  src\                        ← the assembler source: the golden source for stage 3
    main\  (fixed.s, bank0..3.s, include files)
    sub\   sound\   mcu\
  build\                      ← generated, git-ignored
    images\  (main_fixed.bin, main_bank0..3.bin, sub.bin, sound.bin, mcu.bin)
    gfx\  text\  levels\  sound\
    roms\bublbobl\            ← reassembled set, for mame -rompath
  disasm\                     ← raw unidasm passes, before conversion to src\
  notes\
    memory_map.md  ram_map.md  data_formats.md  routines.md  open_questions.md
  traces\                     ← MAME debugger traces/scripts (raw logs git-ignored)
```

Tooling: Python 3 (+ Pillow for PNG), GNU Binutils (§12.1), MAME at `C:\Games\Retro\mame` (`mame -debug`,
ROMs in `roms\bublbobl.zip`), and its bundled `unidasm.exe` (supports `-arch z80` and
`-arch m6801`), optionally Ghidra for interactive cross-referencing.

Output languages: main, sub and sound CPUs are **Z80** assembly; the MCU is **Motorola
6801** (6800-family) assembly.

`unidasm` notes: `-skip N` skips N file bytes, `-basepc` is the address of the *first
disassembled byte* (so `-skip 0x333f -basepc 0x333f`), and `-count` is in bytes. Banked
code needs the bank's file offset as `-skip` and `0x8000 + offset-within-bank` as `-basepc`.

---

## 4. Phase 0 — Foundations

1. **`romset.py`** — load every file, verify CRC32/SHA1 against the MAME list, refuse to run on
   mismatches. Emit per-CPU images into `build\images\`:
   - `main_fixed.bin` (0000–7FFF), `main_bank0..3.bin` (each 16K, mapped at 8000).
   - `sub.bin`, `sound.bin`, `mcu.bin` (based at F000).
2. **Symbol files** — a single source of truth (`notes\symbols.toml` or similar) for I/O
   ports, RAM variables and routine labels, exported to whatever format each disassembler
   needs. Seed it from §2.
3. **Byte classification map** per image: `code / data / text / fill / unknown`. Starts with
   fill runs and known strings; grows from traces (§5) and disassembly. Everything downstream
   uses it to avoid disassembling data.

Deliverable: reproducible images + symbol file + empty classification maps.

---

## 5. Phase 1 — Dynamic analysis in MAME (separating code from data)

Run `mame bublbobl -debug` and capture:

1. **Code coverage** — `trace build\traces\main.log,maincpu,noloop` (likewise `sub`,
   `audiocpu`, `mcu`) across attract mode, a 1P game through several rounds, a 2P game,
   continue, high-score entry, test mode (service switch) and, if possible, the endings
   (use the MAME cheat engine / RAM pokes to reach late rounds). Every executed PC is
   code; feed those addresses into the classification maps.
   For banked code also log the current bank (breakpoint on `FB40` writes with an action
   that prints the value) so coverage is attributed to the right bank file.
2. **Watchpoints** to discover RAM variables and who owns them, e.g.:
   - round number, lives, score, credits, player state, enemy slots;
   - `wpset dd00,300,w` (object RAM) to find sprite-building routines;
   - `wpset c000,1d00,w` at round start to find the level-drawing routine and its ROM source;
   - `wpset f800,200,w` to find palette loaders and their tables;
   - `wpset fa00,1,w` to log every sound command (with PC) → sound command catalogue.
3. **Snapshots** — `save` work RAM, object RAM, video RAM and palette at known moments
   (title, round 1, boss, ending). Palette RAM is the only source of colour (no colour PROM).
4. Record every discovered variable in `notes\ram_map.md` with address, size, meaning and
   writer routine(s).

Deliverable: coverage files per CPU, RAM map, sound-command log, snapshot set.

**Tooling done (2026-10-15).** `tools/trace.py` runs MAME 0.289 headless
(`-debug -debugger none`) with `tools/trace.lua` as the autoboot script:
- The debugger traces each CPU into files that change every second. `trace.py` reads
  and deletes each finished file, so a long run needs little disk space. A watchpoint on
  `FB40` puts a bank marker into the main CPU's trace, so code in the bank window is
  credited to the right page.
- Lua memory taps count, for every RAM and I/O address, which instruction read or wrote it,
  and log every sound command written to `FA00`.
- Inputs come from scripted scenarios (`--list`). DIP switches come from a generated MAME
  cfg, so the user's own MAME settings never reach a run. `play` records a real game at
  full speed (`-record`) and traces its replay (`-playback`): use it to reach late rounds,
  bosses and endings.
- `--snap N` saves a screenshot and the main CPU's `C000–FFFF` every N seconds.
- `tools/coverage.py` merges the executed code into the classification maps as
  `source = "trace"` ranges, which add up over runs. `tools/rammap.py` writes
  `notes\ram_map.md` and `tools/soundcmds.py` writes `notes\sound_commands.md`.

Traps found on the way: the debugger's `noloop` option means *do not* collapse loops (leave
it off, or the idle loop floods the trace); `focus` makes the debugger ignore the other CPUs;
Lua notifier and tap handles must stay referenced or the garbage collector cancels them; a
soft reset leaves the headless debugger stopped. Tracing runs at about 15–100% of full speed,
limited by MAME flushing the trace file on every line, so run scenarios side by side.

Findings so far:
- After start-up the main CPU sits in `jr $` at `01ED`. All game work runs in the IM 2
  interrupt. The main CPU writes `2E` to `FC00` at `0130`, with I = `0B`, so the vector
  entry is `0B2E`, which holds `044D`, the handler. The tamper check at `333F` and a second
  check at `bank0:950A` both verify this vector.
- `dead copy` is `334A–3352`. The `:` after it is the first byte of the routine at `3353`.
- First runs (attract 150 s, a 1P game 600 s, a 2P game 400 s, both test modes) executed
  `0x3E07` bytes of the fixed ROM, `0xF5E` of bank 0, `0xD70` of bank 2, `0x42` of bank 3,
  none of bank 1, `0x833` of the sub CPU and `0x1954` of the sound CPU. Bank 1 and most of
  bank 3 need later rounds, the endings or the secret mode: record those with `play`.
- The main CPU sent 20 different sound commands, most of them through one routine at `1374`.
- Evidence on the MCU questions is in `notes\open_questions.md`.
- Still to do in this phase: one frame's order of shared-RAM accesses across the CPUs
  (PLAN §3.3), and runs that reach late rounds.

---

## 6. Phase 2 — Graphics

### 6.1 Tiles
From `bublbobl.cpp` `charlayout`: 8×8, 4bpp, region is **bit-inverted**
(`ROMREGION_INVERT`), planes `{0, 4, half, half+4}`, x bits `3,2,1,0,11,10,9,8`,
16 bytes per row-pair stride (`y*16`), 128 bits per tile. Region layout:
`a78-09..14` at `0x00000–0x2FFFF`, gap `0x30000–0x3FFFF`, `a78-15..20` at
`0x40000–0x6FFFF`, gap `0x70000–0x7FFFF`.

`gfx.py`: decode all tiles → PNG sheets (greyscale, and per-palette using dumped palettes).
Validate against MAME's F4 tile viewer.

Done: `tools/gfx.py` writes `build\gfx\tiles_bank00..11.png` (banks 12–15 are the empty
sockets) as indexed greyscale, raw colour index per pixel. The font and the wall tiles decode
cleanly. The sprite tiles look broken up in the sheets, because objects are built from tile
columns (§6.3); the offline renderer will put them back together.

### 6.2 Palettes
RGBx_444 big-endian, 16 palettes × 16 colours. Extract the tables the game copies into
`F800` (found in Phase 1) so palettes come from ROM, not just snapshots. Colour 15 is
transparent for objects.

Done: `tools/palette.py` writes `build\gfx\palettes.json` and a swatch sheet
`palettes.png`. Every colour comes from ROM:
- `bank1:8000` (`PALETTES`) is the whole `0x200`-byte palette RAM image. `LOAD_PALETTES`
  (`0B30`) copies it with `BANK_SELECT` page 1. Palettes 14 and 15 are zero there.
- `bank1:8200` (`ROUND_PALETTES`) holds 8 round palettes. `LOAD_ROUND_PAL` (`0B43`) copies
  one into palette 14 or 15, depending on bit 0 of the round number `ROUND_MAIN` (`E64B`).
  So the old round and the new round each have a palette while the screen scrolls between
  them. The index is byte 0 of the round's record.
- The round records are `0x2B` bytes per round at `bank1:A73A` (`ROUND_RECORDS`), and
  `LOAD_ROUND_REC` (`1775`) copies the current one to `E598`. This is the lead for Phase 4.
- Animated colours: palette 1 colour 14 cycles through 6 colours at `1BAE`, palette 1
  colour 1 ramps from black to red through `2895`, palettes 7–8 come from `3CC2`, and
  palette 11 is changed by `bank0:B764–B7FE` (not decoded yet).
- Checked against palette RAM in 30 MAME snapshots: palettes 0–13 equal `PALETTES` apart
  from the animated entries, and palettes 14–15 equal the round palette named by the
  round's record.
- `BANK_PAGES` (`0293`) has two sets of `FB40` values. DSW-B:8 (ROM type) picks one: pages
  0–3 all in IC52, or pages 2–3 in IC53.

### 6.3 Objects / screen composition
There is **no tilemap**. `bublbobl_v.cpp` renders everything from object RAM:
- each 4-byte object: `Y`, `gfx_num`, `X`, `attr` (attr low nibble = tile bank × 1024,
  bit 6 = X high);
- `gfx_num` selects a 0x80-byte block of `C000` RAM holding tile/attribute pairs
  (tile low 8 bits; byte 2: tile bits 8–9, colour b2–5, flipX b6, flipY b7);
- the `a71-25` PROM (offset `0x80 + (gfx_num & 0xE0)/2`) defines the column shape of each
  object (skip / new column / row select).

`objects.py`: re-implement this renderer offline so RAM snapshots render to PNG
identically to MAME. That renderer is then reused to preview levels and sprite frames
straight from ROM data.

Done: `tools/objects.py` renders a `C000–FFFF` RAM image to PNG, following
`screen_update_bublbobl`. Video enable and flip come from `FB40_COPY` (`E1CB`), the
main CPU's copy of `FB40`. `--check` renders every RAM image in a `trace.py --snap`
folder and compares it with MAME's screenshot of the same frame. All 30 frames (title,
attract demo, a 1P game across rounds 1–2) are pixel-identical.

### 6.4 Sprite/animation tables
Use object-RAM watchpoints to find the routines that write tile lists into `C000`; follow them
back to ROM frame tables. Extract each character's frames (Bub, Bob, the 10+ enemies,
items, bubbles, fonts) into named sheets with JSON metadata.

Started (2026-10-17). Every 16 × 16 sprite goes through `SPRITE` (`147D`) or `SPRITE_FLIPX`
(`149C`): A = gfx_num, B = the first of four consecutive tiles, C = the tile attribute. So
a frame is (tile bank, B, C), and the bank comes from the attribute of the object that
shows the block. The objects are built in `OBJ_SHADOW` (`E1CD`) and copied to `DD00` by
`OBJ_COPY` (`04AD`) at the next IRQ.
- Few frames come from ROM tables. Most callers step `ANIM_STEP` (`15CA`, E = frame
  count, D = delay) and compute B inline (e.g. `26E8`: frame × 4 + `D4`, colour `1C`).
  The player is the exception: `PLAYER_SPRITE` (`450D`) reads 12 animation records at
  `PLAYER_ANIMS` (`4584`) and first tiles at `PLAYER_FRAMES` (`45E4`).
- So the frames are captured, not decoded: `trace.lua` logs every sprite draw with its
  caller in `sprites.csv`, and `tools/sprites.py` writes one sheet per caller plus
  `build\gfx\sprites\sprites.json`. Four runs of scripted play (attract, 1P twice, 2P)
  gave 523 frames from 60 callers: Bub and Bob, bubbles, Zen-chan, items, scores, round
  banners, HURRY UP, INSERT COIN. A caller is the CALL whose return address is on the
  stack, so a routine that ends in `JP SPRITE` is listed under its own caller.
- A recorded game to round 10 added Mighta and Monsta: 622 frames from 72 callers. Each
  draw also logs IX, which ties it to a slot table. The enemies are six groups, each with
  its own count (`ENEMY_COUNTS`, from round-record bytes 4–6), slot table and code.
  `ENEMY_SWAP` (record byte 12) swaps groups 0 and 2 for a second kind, so there are eight
  kinds. Seen so far: group 0 Zen-chan, group 1 Banebou, group 2 Mighta, group 3 Hidegons,
  group 4 Pulpul, group 5 Monsta, swapped group 0 Invader, swapped group 2 Drunk, and
  Skel-Monsta (`GHOST_SLOTS`). All eight kinds are traced, and the round 100 boss,
  Super Drunk (`BOSS_SLOT`), 16 pieces from `BOSS_POSES`. `trace.py --round N` starts a game on round N. Catalogue:
  `notes\sprites.md`.
- The 1P ending is traced (`trace.py --boss-hits 80` traps the boss at once): text screens,
  then "YOU ZAPPED TO" round 50.
- The 2-player (true) ending is traced too: HAPPY END, the staff credits and the game's
  own character list, which confirms every enemy name.
- Per-character sheets: `sprites.py` writes `build\gfx\sprites\characters\`, one sheet
  per character (19), picked by slot table or caller, with Super Drunk drawn whole. §6.4
  is done, apart from frames no recording reached.

Deliverables: `build\gfx\tiles_*.png`, `palettes.json`, `objects.py`, per-character sheets.

---

## 7. Phase 3 — Text

1. `text.py`: scan main ROM images for length-prefixed ASCII (`len, chars…`), plus raw runs,
   keyed by CPU address (fixed or `bank:addr`). Output `build\text\strings.csv`.
   Done: `tools/text.py` finds 201 prefixed strings and 56 raw runs. Of the raw runs, 41 are
   marked `ascending`: they are mostly lists of tile numbers that happen to be printable.
2. Find the print routine(s) by breaking on writes of a known string to video/object RAM;
   determine the full record format (position, colour, terminator/control codes such as
   the `:`-separated sequences seen in credits).
3. Decode special tables: default high scores (`0x37DF` name table + scores), staff roll,
   ending texts (two variants: "MIGHTA" vs "MAITA"), secret-game hints, test-mode labels.
4. Map the custom font: which tile numbers correspond to each character (the
   `ABCDEFGHIJKLMNOPQRSTUVWXYZ .!~` table at `0x38D4` in `a78-06-1` is the name-entry
   alphabet).

Deliverable: complete string catalogue with addresses and the routine that prints each.

---

## 8. Phase 4 — Level (round) data

100 normal rounds plus the secret/“super” variants.

1. Find the round counter in RAM (Phase 1) and the round-start routine (watch `C000` writes
   when the round number changes).
2. Trace back to the ROM tables. Expect, per round:
   - wall/platform layout (likely a compact bitmap or row-encoded format),
   - the two-tile wall pattern / colour palette for that round,
   - enemy list: type, start position, direction, timing,
   - bubble air-current (wind) data,
   - possibly special-item / trigger data.
3. Identify which bank holds them (bank breakpoint during round start).
4. `levels.py`: decode all rounds → JSON + PNG previews (using the offline renderer).
   Cross-check against gameplay screenshots for rounds 1, 2, 50 and 100.
5. Document the "super" mode differences (enemy changes, secret rounds, the
   `WELCOME TO SECRET ROUND` / `YOU ZAPPED TO` warp logic).

Deliverable: `build\levels\round_XXX.json/.png`, `notes\data_formats.md#levels`.

Started (2026-10-17). Steps 1–4 are done for the walls:
- A round is `ROUND_GRID` (`E398`): 32 × 32 cells of 8 × 8, 0 = wall and 1–4 = open,
  probably the bubbles' air current. It is also the collision map (`GRID_CELL`, `174B`).
  So walls and wind are one format, not two.
- Most of it comes from the **sub CPU**, which answers part of Phase 5's question about its
  role. `GRID_UNPACK` (sub `00A9`) unpacks 0x120 bytes per round from `ROUND_LAYOUTS` (sub
  `0CFC–7D7B`), 3 bits a cell, into rows 5–28. The main CPU copies the ceiling and the
  floor (rows 0–4, 29–31) from `bank1:GRID_EDGES`, picked by `ROUND_RECORD` byte 3.
- Each round has its own five tiles: 0x204 + 5 × round for the 2 × 2 side-wall block and
  +4 for the walls, colour 14 or 15. `SHADE_GRID_ROW` adds shadow tiles F0–F5.
- `tools/levels.py` writes `build\levels\round_NNN.json/.png` and `rounds.png`. `--check`
  rebuilds the grid and wall tiles from the ROMs and compares them with RAM snapshots.
  Every grid matched (rounds 1, 2, 50, 100), and so did every fully drawn set of tile
  columns. Notes: `notes\levels.md`.
- The open values are the air current: 1 up, 2 right, 3 left, 4 down (`BUBBLE_DRIFT`,
  `6175`).
- The whole round record is decoded (`notes\levels.md`): item positions, the trap, HURRY UP
  and Skel-Monsta times, enemy and bubble speeds, seven enemy entries (delay, X, Y, facing),
  and the mix of special bubbles. `LOAD_ROUND_REC` shifts four of the fields by a
  difficulty value (`E5DC`) and swaps enemy groups in the super mode. `--check` replays it
  and matches the record in every RAM snapshot.
- Step 5 is done. The super mode comes from the title code S J B L R J S R and the SELECT
  GAME MODE screen; `trace.py super1p` enters it, and `--check`, which now also compares
  the round palette, matches super rounds 1 and 77. Bubble type 4 never appears: only
  round 100 lists it, and round 100 has no gaps to spawn bubbles from. The two items are
  chosen from the last round's time and flags (points) and from counters of what the
  players have done, against thresholds by difficulty (special); `items.json` holds the
  tables.
- Still to do: what most item counters count and what each special item does. These belong
  to Phase 5's item system.

---

## 9. Phase 5 — Game logic disassembly (main + sub)

1. Generate first-pass listings with `unidasm` using the classification maps so only code
   regions are disassembled; data regions get labels and stay as `.incbin` (see the
   ROM-free rule at the top).
   (Alternatively import into Ghidra: base `0000` + four overlay blocks at `8000`, Z80.)
2. Work outward from entry points: reset (`0000`), IM2 vector table (vector byte comes from
   MCU shared RAM `FC00`), `RST` handlers (`0008`, `0010`, `0018`, `0020`, `0028`, `0030`,
   `0038`), main loop, bank-switch trampolines.
3. Identify and name subsystems: attract/demo, coin/credit, game-mode select, player
   control, bubble physics, enemy AI per type, item/bonus system (EXTEND, special items,
   "mystery" bonuses), round transition, death, continue, high-score, endings, test mode.
4. **Sub CPU** (`a78-08`): determine its role — likely handled from shared RAM `E000–F7FF`.
   Map every shared variable it reads/writes; correlate with main-CPU writes.
5. Known items to document: the `dead copy` tamper trap (`0x333F`) and any other
   self-checks (`PS4 SUM ERROR`, `ROM OK`, RAM tests), the SWB#7 `F7FE/F7FF` score output
   mystery noted in the driver (routines `0F26`, `0F74`).
6. Write the result as assembler source in `src\main\` and `src\sub\` from the start, and
   keep it assembling byte-exact at every commit (Phase 8). Do not let a listing-only
   form drift away from buildable source.

Deliverable: `src\main\*.s`, `src\sub\*.s`, `notes\routines.md`, byte-exact rebuild.

Started (2026-10-17) with the sub CPU, which is now done:
- `tools/dasmz80.py` is the Z80 counterpart of `dasm6801.py`. It traces from the vectors,
  the named routines, the traced ranges in the classification map, `--entry` addresses and
  `--table` jump tables, and writes GNU `as` source with `.incbin` for the rest. An
  encoding `as` would not reproduce (ED duplicates, undocumented DDCB forms) stays
  `.incbin` with the reading in a comment. It runs on `sub`, `sound` and `main_fixed`.
- `src\sub\sub.s` assembles byte-exact. All 0xC85 bytes of code in `0000–0CFB` are
  instructions, with each routine named and commented; only the RST/NMI gaps, one byte at
  `018F`, the jump table and the round layouts are `.incbin`. `tools/symbols.py` now
  writes `sub.inc` (the `[main.mem]` names in `E000–F7FF`).
- Step 4 is answered. The sub CPU unpacks the round walls and does every hit test (players,
  enemies, enemy shots, bubbles, effects, the boss) and the bubble pushing and chain pops.
  It writes flags that the main CPU acts on. It also has a ROM sum that hangs it, and a
  watchdog that wrecks the work RAM if the main CPU's frame counter stops. Notes:
  `notes\sub.md`.
- The sub ROM holds two more layouts after the 100 rounds: the attract screen's
  (`ROUND_MAIN` 0x64) and one never seen in use.
- Main fixed ROM, first pass (2026-10-17): `dasmz80.py main_fixed` traces 0x638E code bytes
  (11728 instructions, 1273 labels) and `src\mainixed.s` is that output; it builds
  byte-exact. The tool now stops a path at text, fill and hand-marked data ranges of the
  classification map (a routine whose end the tracer can't see ran into the strings at
  `2D73`) and at the end of the image. Labels are still `L_xxxx`, and the jump tables that
  `0DA7` reads (callers such as `50EE`) are only followed where MAME executed them.
- Next: name the routines and annotate `src\mainixed.s` by hand, list the jump tables so
  the untraced targets are reached, then do the four banks.

---

## 10. Phase 6 — MCU (6801U4)

Smallest and most self-contained — a good early win.

1. Disassemble `F000–FFFF` with `unidasm a78-01.17 -arch m6801 -basepc 0xf000`.
2. Annotate the IRQ1 handler at `F046` (≈25 `JSR`s, one subsystem each). Known:
   `F1BF`/`F1DB` shared-RAM read/write, `F8F1` EXTEND counter, `F092` checks shared `FF98`
   for `'G'` (0x47).
3. Name each job: coin handling + lockout + counters, input/DSW reading and publishing to
   shared RAM, main-CPU IRQ generation + vector, collision/position checks, timers,
   test-mode code at `FEBB` (reset path) and the `FFD3` halt loop.
4. Produce a shared-RAM contract table (`FC00–FFFF`): offset, direction (MCU→Z80 / Z80→MCU),
   meaning.
5. Byte-exact rebuild check (Phase 8).

Deliverable: `src\mcu\mcu.s`, `notes\mcu_shared_ram.md`.

**Done (2026-10-15).** `tools/dasm6801.py` traced every routine from the vectors and wrote
the first `src\mcu\mcu.s`. That file was then annotated by hand. It assembles byte-exact,
and every byte is classified in `notes\classmap\mcu.toml`: `0x944` code and the rest data.
Only the data ranges are still `.incbin`. Findings that change this plan:
- There are 19 jobs, not ≈25. The handler at `F092` is the coin job. It is also the OCF
  vector, but it ends in `RTS` and is never entered by an interrupt.
- `FEBB` is a check for the factory test jig. It drives patterns on the ports and tests
  RAM, timers and the ROM sum. Without the jig it jumps to the normal start at `F003`.
  `FFD3`/`FFDD` are the jig's pass and fail loops.
- The MCU raises the main CPU's IRQ (port 1 b6) but never writes the vector at `FC00`.
- Lives and the round counter live in the MCU's shared RAM. The main CPU changes them by
  command bytes. With `FF95` = `'B'`, a direct write crashes the MCU (tamper trap).
- `notes\symbols.toml` is now the single source of names. `tools/symbols.py` writes it
  as `build\include\<cpu>.inc` for every build.
- Questions left open: `notes\open_questions.md`.

---

## 11. Phase 7 — Sound

1. Disassemble `a78-07.46` (entry points: `0000`, `0038` IRQ from YM chips, `0066` NMI from
   command latch).
2. Build the command catalogue: map each command byte (from the `FA00` log in Phase 1) to
   its handler and data pointer. The pointer tables seen around `0x28DA`–`0x2B00` are the
   likely song/channel lists.
3. Decode the sequence format (notes, durations, instrument changes, loops) for both chips.
   Extract YM2203 and YM3526 instrument/patch tables.
4. Outputs:
   - `sound_commands.csv` (id → name → type → data addr),
   - per-song decoded event lists (JSON),
   - optional MIDI conversion,
   - reference audio/VGM captured from MAME for validation.

Deliverable: `src\sound\*.s`, `build\sound\`, `notes\data_formats.md#sound`.

---

## 12. Phase 8 — Reassembly to a byte-exact set that runs in MAME

### 12.1 Toolchain
**GNU Binutils** (`as`, `ld`, `objcopy`), built from `C:\code\sourceware\binutils-gdb` in
WSL Ubuntu into `~/bublbobl-tools` for two targets:

| Target | Prefix | CPUs | Notes |
|---|---|---|---|
| `z80-elf` | `~/bublbobl-tools/z80/bin/z80-elf-` | main, sub, sound | `-march=z80+xyhl+sli+xdcb` enables the undocumented opcodes |
| `m68hc11-elf` | `~/bublbobl-tools/m6801/bin/m68hc11-elf-` | MCU | The 68HC11 is a superset of the 6801 with the same encodings |

Each image is assembled to an object, linked at its base (`ld -Ttext=0x0000`, `0x8000` or
`0xF000`), then written out with `objcopy -O binary`. One syntax (GNU `as`) and one build
script cover the whole set. Proved on 2026-10-15: the main fixed ROM rebuilt from a
reset-code split plus `.incbin`, and the MCU image from `.incbin`, both byte-identical.

To rebuild the tools (needs `bison` and `flex` in WSL):
`configure --target=<target> --prefix=$HOME/bublbobl-tools/<name> --disable-gdb
--disable-gdbserver --disable-sim --disable-gprofng --disable-gold --disable-nls
--disable-werror MAKEINFO=true`, then `make all-gas all-ld all-binutils` and the matching
`install-*` targets.

### 12.2 Source layout and images
| Source | Link base | Output | Size |
|---|---|---|---|
| `src\main\fixed.s` | `0x0000` | `a78-06-1.51` | 32K |
| `src\main\bank0..3.s` | `0x8000` each | joined in order → `a78-05-1.52` | 4 × 16K |
| `src\sub\sub.s` | `0x0000` | `a78-08.37` | 32K |
| `src\sound\sound.s` | `0x0000` | `a78-07.46` | 32K |
| `src\mcu\mcu.s` | `0xF000` | `a78-01.17` | 4K |

- Shared symbols (I/O ports, shared RAM `E000–F7FF`, MCU RAM `FC00–FFFF`) live in include
  files that every CPU's source uses. Each address then has one name across all four CPUs.
- The four banks share `0x8000`, so each bank keeps its own labels. A call into a bank uses
  the bank-switch helpers in the fixed ROM. Name each helper and its bank argument.
- **No ROM bytes in source.** Each source file starts as one `.incbin` of its image from
  `build\images\` (`.incbin "file", offset, length`). As regions are
  disassembled, the `.incbin` is split around them. Data regions get a label and keep a
  `.incbin` of just their range, so the label is in the source but the bytes are not.
  `build.py` runs `romset.py` first so the images exist and are verified.
- Pad free space to the original length with `0xFF`, and place fixed strings (the version
  stamp at `0xFF4C` of `a78-05-1`) at their original addresses with `.org` (which stops the build if code has run past it).
- Graphics ROMs and `a71-25.41` are data only. `build.py` copies them from the ROM directory
  so that the output folder is a complete set.

### 12.3 Encoding traps
- **6801 extended addressing below `$0100`.** The MCU uses three-byte extended forms for
  direct-page addresses (e.g. `F6 00 54` = `LDAB $0054`, `7C 00 48` = `INC $0048`). GNU `as`
  for the 68HC11 already uses the extended form for any address, constant or symbol, and
  uses the two-byte direct form only with a `*` prefix (`ldab *0x54` = `D6 54`). So write
  `*` exactly where the original has the direct form.
- **Z80 undocumented opcodes** (`SLL`, `IXH`/`IXL`, etc.) must assemble as in the original.
  Keep each `JR`/`JP` and each `RST` exactly as found.
- **Code that is also data.** The `dead copy` bytes at `0x334A` run as opcodes. Keep them as
  a labelled `.incbin` with a comment that gives both readings.
- **Ambiguous bytes.** Until a region is proved to be code, keep it as a `.incbin`. Wrong
  code is worse than honest data.

### 12.4 Build and verify
`python tools\build.py` does these steps:
1. Assemble every source.
2. Split or join the output into the original file names.
3. Compare CRC32 and SHA1 with the MAME list (`romset.py`). Stop with a byte-offset diff on
   the first mismatch.
4. Write the complete set to `build\roms\bublbobl\`.

Then confirm in MAME:
```bash
mame bublbobl -rompath build/roms
```
A byte-exact set gives no checksum warning. Play attract mode, one round and test mode.

### 12.5 Two levels of done
1. **Byte-exact.** The CRC matches. Numeric addresses are allowed where meaning is unknown.
2. **Relocatable.** Every pointer is a label: jump and call targets, address tables, and
   immediate values that are addresses. Test: put padding in each source near its start,
   then rebuild and play. The game must still run in MAME (the CRC will change). For this
   test only, make the tamper check at `0x333F` and the ROM checksum tests pass.

Stage 3 needs level 1. Level 2 is required only for changes to the arcade code itself.

Deliverable: `tools\build.py`, a byte-exact `build\roms\bublbobl\`, a passing relocation test.

---

## 13. Phase 9 — Consolidation

- `notes\data_formats.md`: every format (text, objects, levels, enemies, sound) with byte
  diagrams and worked examples.
- `notes\open_questions.md`: things not yet understood (e.g. SWB#7, unused data,
  unreferenced strings, the bootleg-vs-original MCU differences).
- A one-command pipeline (`python tools\extract_all.py --roms <dir>`) that regenerates all of
  `build\` from the ROMs and validates CRCs first.
- Optional: compare against Ver 0.0 (`a78-06.51`/`a78-05.52`) and the US sets to document
  version differences (the "SELECT GAME MODE" mode-select path, bug fixes).

---

## 14. Validation strategy

| Area | Check |
|---|---|
| ROM loading | CRC/SHA1 match before every run |
| Disassembly | Byte-exact reassembly of every CPU image |
| Graphics | Tile sheets match MAME F4 viewer; offline renderer matches MAME screenshots from the same RAM snapshot |
| Palettes | ROM-extracted palettes equal palette RAM snapshots |
| Levels | Rendered round previews match in-game screenshots |
| Text | Every string located and attributed to a print call |
| Sound | Decoded sequences replay to match MAME audio / VGM register logs |
| MCU | Shared-RAM contract consistent with main-CPU usage |

---

## 15. Suggested order & milestones

1. Phase 0 foundations (ROM loader, images, symbols) and the Phase 8 build skeleton: every
   ROM starts as one `.incbin` of its image, so `build.py` is byte-exact from day one.
2. Phase 2.1 tile sheets + Phase 3 text dump — quick, visible results.
3. Phase 6 MCU — small, complete, byte-exact.
4. Phase 1 traces + RAM map — unlocks everything else.
5. Phase 2.2–2.4 palettes, offline renderer and sprite frames (all done).
6. Phase 4 levels (done; the item counters' meanings move to Phase 5).
7. Phase 5 main/sub disassembly (sub done). Replace `.incbin` ranges with code region by region, and keep
   the build byte-exact at each step.
8. Phase 7 sound.
9. Phase 8 relocation test.
10. Phase 9 consolidation.

Before starting each phase, check for existing community documentation or disassemblies of
Bubble Bobble to cross-reference findings (treat as hints, verify against the ROMs).
