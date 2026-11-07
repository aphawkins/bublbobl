# Bubble Bobble (Taito, 1986) — Code & Data Extraction Plan

Goal: turn the `bublbobl` arcade ROM set into a documented, rebuildable understanding of the
game — annotated disassemblies for all four CPUs plus extracted, viewable data (graphics,
palettes, text, levels, enemy tables, music) in open formats.

This file covers stages 1 and 2 of [PLAN.md](PLAN.md): disassembly to source, and
reassembly to a byte-exact set that runs in MAME. Stage 3, the C# reimplementation in
The Sharp Kind, consumes what these stages produce and is planned in `PLAN.md`.

Most of the work is done: §3 says where each result is and §7 lists what is left. Findings live
in `notes\`, not here.

Reference sources:
- ROMs: `roms\bublbobl\` (and `roms\bublbobl.zip`) — not in the repo; supply your own
- MAME driver: [mamedev/mame](https://github.com/mamedev/mame), cloned alongside this repo at
  `..\..\mamedev\mame` — `src\mame\taito\bublbobl.cpp`,
  `bublbobl_m.cpp` (MCU/IO glue), `bublbobl_v.cpp` (video), `bublbobl.h`
- MAME binaries: `C:\Games\Emulated\_Emulators\mame` (`mame.exe`, `unidasm.exe`) — not on PATH;
  scripts read `MAME_DIR` from `config.local.toml`
- Community documents are hints, to be verified against the ROMs. The ones used so far are named
  in the notes that use them.

> **The repo holds no ROM bytes.** Source in `src\` contains only what has been
> disassembled. Every other region is pulled in at build time from the verified images in
> `build\images\` with `.incbin`. So `src\` never builds without the user's ROMs, and
> nothing in the repo is a copy of a ROM. ROMs stay out of version control.

---

## 1. The ROM set

The set exactly matches MAME's parent **`bublbobl` — Bubble Bobble (Japan, Ver 0.1)**.

| File | Size | CRC32 | CPU / use | Notes |
|---|---|---|---|---|
| `a78-06-1.51` | 32K | 567934b6 | Main Z80, fixed `0000–7FFF` | Game logic, text, "dead copy" tamper trap |
| `a78-05-1.52` | 64K | 9f8ee242 | Main Z80, banked `8000–BFFF` (4 × 16K) | Enemies, items, test mode, endings, level data, version stamp |
| `a78-08.37` | 32K | ae11a07b | Sub Z80 `0000–7FFF` | Round walls and hit tests |
| `a78-07.46` | 32K | 4f9a26e8 | Sound Z80 `0000–7FFF` | Music/SFX driver + data (YM2203 + YM3526) |
| `a78-01.17` | 4K | b1bfb53d | MC6801U4 MCU `F000–FFFF` | Protection/IO MCU, dated "29.JUN,1986" |
| `a78-09`…`a78-14` | 6 × 32K | — | Graphics, planes 0–1 | |
| `a78-15`…`a78-20` | 6 × 32K | — | Graphics, planes 2–3 | |
| `a71-25.41` | 256B | 2d0f8545 | Video timing / object-layout PROM | Used by the renderer, see §2 |

Landmarks:
- `a78-05-1.52` @ `0xFF4C`: `VER 0.1 4.SEP,1986 SUMMER` (Ver 0.0 was `18.AUG,1986`).
- Strings are **length-prefixed ASCII** (e.g. `10 "SELECT GAME MODE"`, `13 "ALL RIGHTS RESERVED"`).
- The font is in tile bank 0 at the ASCII codes (`0x20–0x5F`, `@` drawn as ©), so a
  string's bytes are its tile numbers.
- Free space (`0xFF` runs) in `a78-05-1.52`: `0x785C`(+7A4), `0xBC9F`(+361), `0xD583`(+287D).
  `a78-06-1.51` has none.

---

## 2. Hardware model (what every tool must agree on)

### Main Z80 (6 MHz)
| Range | Use |
|---|---|
| `0000–7FFF` | `a78-06-1.51` |
| `8000–BFFF` | Bank window into `a78-05-1.52`. Write to `FB40`: entry = `(data ^ 4) & 7`. Entries 0–3 = file offsets `0x0000/0x4000/0x8000/0xC000`; entries 4–7 = empty socket IC53. So the game writes **4–7** to select file pages 0–3. |
| `C000–DCFF` | "Video RAM" — actually tile-column data for objects (see Video) |
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

### Video
There is **no tilemap**. `bublbobl_v.cpp` renders everything from object RAM:
- Tiles (`charlayout`): 8×8, 4bpp, region **bit-inverted** (`ROMREGION_INVERT`), planes
  `{0, 4, half, half+4}`, x bits `3,2,1,0,11,10,9,8`, 16 bytes per row-pair stride (`y*16`), 128
  bits per tile. `a78-09..14` at `0x00000–0x2FFFF`, gap `0x30000–0x3FFFF`, `a78-15..20` at
  `0x40000–0x6FFFF`, gap `0x70000–0x7FFFF`.
- Each 4-byte object: `Y`, `gfx_num`, `X`, `attr` (attr low nibble = tile bank × 1024,
  bit 6 = X high).
- `gfx_num` selects a 0x80-byte block of `C000` RAM holding tile/attribute pairs
  (tile low 8 bits; byte 2: tile bits 8–9, colour b2–5, flipX b6, flipY b7).
- The `a71-25` PROM (offset `0x80 + (gfx_num & 0xE0)/2`) defines the column shape of each
  object (skip / new column / row select).
- Palettes: RGBx_444 big-endian, 16 palettes × 16 colours, from `PALETTES` and `ROUND_PALETTES` in
  bank 1 (no colour PROM). Colour 15 is transparent for objects. Palettes 14 and 15 hold the old and
  new round's colours while the screen scrolls between them.

---

## 3. Status

| Phase | Work | Results | Checked by | State |
|---|---|---|---|---|
| 0 | Foundations | `tools\romset.py`, `notes\symbols.toml`, `notes\classmap\` | CRC/SHA1 before every run | Done |
| 1 | Traces in MAME | `tools\trace.py`, `coverage.py`, `rammap.py`, `soundcmds.py`, `frameorder.py`; `notes\ram_map.md`, `notes\sound_commands.md`, `notes\frame_order.md` | | Done |
| 2 | Graphics | `tools\gfx.py`, `palette.py`, `objects.py`, `sprites.py`; `notes\sprites.md` | `objects.py --check`: 30 frames pixel-identical to MAME. Palettes equal palette RAM in 30 snapshots, apart from animated entries | Done, apart from frames no recording reached |
| 3 | Text | `tools\text.py`, `build\text\strings.csv`, `prints.csv`; `notes\text.md` | `text.py --check`: prints found at their tiles in RAM snapshots | Done, apart from reading the runes (`notes\open_questions.md`) |
| 4 | Levels | `tools\levels.py`; `notes\levels.md` | `levels.py --check` against RAM snapshots: grids, tiles, records, round palettes | Done |
| 5 | Game logic | `src\main\`, `src\sub\`; `notes\main.md`, `notes\sub.md` | Byte-exact build | Done: every call goes to a named routine. What stays `L_xxxx` is branch targets inside routines |
| 6 | MCU | `src\mcu\mcu.s`; `notes\mcu_shared_ram.md` | Byte-exact build | Done |
| 7 | Sound | `src\sound\sound.s`; `tools\sounddec.py`, `soundtables.py`, `soundcmp.py`, `soundcheck.py`; `notes\sound.md`, `notes\sound_blocks.md`, `build\sound\` | `soundcheck.py` against MAME register writes, all commands from silence | Done. The synthesiser-side check belongs to stage 3 (`PLAN.md` §3.5 D) |
| 8 | Reassembly | `tools\build.py`, `tools\reloc.py`; `notes\relocation.md` | CRC match; relocation test | Byte-exact. Relocation passes exactly within what the runs reach: all 100 rounds with one and two players, test mode, every special item taken by either player, the secret rooms (§6) |
| 9 | Consolidation | `tools\extract_all.py` | Run from a copy of the repo with no `build\` | Pipeline done. The version comparison is optional (§7) |

---

## 4. Working on the source

Layout: `tools\` scripts (listed in `README.md`), `src\` the assembler source and golden source for
stage 3, `notes\` findings and names, `build\` generated and git-ignored (`images\`, `include\`,
`gfx\`, `text\`, `levels\`, `sound\`, `traces\`, `roms\bublbobl\`), `disasm\` raw first passes,
git-ignored.

**Do not edit `src\main\` or `src\sound\` by hand.** They are generated:
- A name or comment goes in `notes\symbols.toml` (`tools\addnames.py` appends `TABLE|ADDR|NAME|NOTE`
  lines). A label's note becomes its comment.
- A new jump table or entry goes in `tools\redo_fixed.sh`, `redo_banks.sh` or `redo_sound.sh`.
- A range that is data goes in `notes\classmap\<image>.toml`.
- Then run `sh tools/redo_main.sh` (all of `src\main\`) or `sh tools/redo_sound.sh`, and
  `python tools\build.py` must still report byte-exact.

`src\mcu\mcu.s` and `src\sub\sub.s` are edited by hand; `tools\dasm6801.py` and `tools\dasmz80.py`
only made their first passes.

After each new trace, run `tools\coverage.py` before the redo scripts. `rammap.py` reads every run
in `build\traces\`, so keep runs made only for snapshots elsewhere. To trace one round's enemies,
for example: `trace.py game1p --round 42 --seconds 120 --cpus main`. `trace.py --help` lists the
cheats (`--round`, `--boss-hits`, `--boss-pop`, `--special`, `--clear`, `--poke`) and
`--snap`/`--snap-from`. `play` records a real game and traces its replay.

Reading the tracer's output:
- A conditional `RET`, or a path that runs on into data, is the sign of data decoded as code. Look
  for decoded code after an unconditional end that is not a `RET`/`JP`.
- `--probe` regions are heuristic: code that MAME has not run. Check one against a trace before
  relying on it, and mark it data in the classification map if it is.
- An encoding `as` would not reproduce (ED duplicates, undocumented DDCB forms) stays `.incbin`
  with the reading in a comment.

Tool traps:
- MAME debugger: `noloop` means *do not* collapse loops (leave it off, or the idle loop floods the
  trace). `focus` makes the debugger ignore the other CPUs. A soft reset leaves the headless
  debugger stopped. Tracing runs at about 15–100% of full speed, limited by MAME flushing the trace
  file on every line, so run scenarios side by side.
- MAME Lua: notifier and tap handles must stay referenced or the garbage collector cancels them.
- `unidasm`: `-skip N` skips N file bytes, `-basepc` is the address of the *first disassembled
  byte* (so `-skip 0x333f -basepc 0x333f`), and `-count` is in bytes. Banked code needs the bank's
  file offset as `-skip` and `0x8000 + offset-within-bank` as `-basepc`.

---

## 5. Build

### Toolchain
**GNU Binutils** (`as`, `ld`, `objcopy`), built from `C:\code\sourceware\binutils-gdb` in
WSL Ubuntu into `~/bublbobl-tools` for two targets:

| Target | Prefix | CPUs | Notes |
|---|---|---|---|
| `z80-elf` | `~/bublbobl-tools/z80/bin/z80-elf-` | main, sub, sound | `-march=z80+xyhl+sli+xdcb` enables the undocumented opcodes |
| `m68hc11-elf` | `~/bublbobl-tools/m6801/bin/m68hc11-elf-` | MCU | The 68HC11 is a superset of the 6801 with the same encodings |

To rebuild the tools (needs `bison` and `flex` in WSL):
`configure --target=<target> --prefix=$HOME/bublbobl-tools/<name> --disable-gdb
--disable-gdbserver --disable-sim --disable-gprofng --disable-gold --disable-nls
--disable-werror MAKEINFO=true`, then `make all-gas all-ld all-binutils` and the matching
`install-*` targets.

### Source layout and images
| Source | Link base | Output | Size |
|---|---|---|---|
| `src\main\fixed.s` | `0x0000` | `a78-06-1.51` | 32K |
| `src\main\bank0..3.s` | `0x8000` each | joined in order → `a78-05-1.52` | 4 × 16K |
| `src\sub\sub.s` | `0x0000` | `a78-08.37` | 32K |
| `src\sound\sound.s` | `0x0000` | `a78-07.46` | 32K |
| `src\mcu\mcu.s` | `0xF000` | `a78-01.17` | 4K |

- Each image is assembled to an object, linked at its base, then written out with
  `objcopy -O binary`.
- Shared symbols live in include files that `tools\symbols.py` writes to `build\include\`, so
  each address has one name across all four CPUs.
- The four banks share `0x8000`, so each bank keeps its own labels.
- Data regions get a label and a `.incbin` of just their range, so the label is in the source but
  the bytes are not.
- Fixed strings (the version stamp at `0xFF4C` of `a78-05-1`) stay at their original addresses with
  `.org`, which stops the build if code has run past it.
- Graphics ROMs and `a71-25.41` are data only. `build.py` copies them from the ROM directory
  so that the output folder is a complete set.

### Encoding traps
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

### Build and verify
`python tools\build.py` assembles every source, splits or joins the output into the original file
names, compares CRC32 and SHA1 with the MAME list (stopping with a byte-offset diff on the first
mismatch), and writes the complete set to `build\roms\bublbobl\`. Then confirm in MAME:
```bash
mame bublbobl -rompath build/roms
```
A byte-exact set gives no checksum warning. Play attract mode, one round and test mode.

---

## 6. Two levels of done

1. **Byte-exact.** The CRC matches. Numeric addresses are allowed where meaning is unknown.
2. **Relocatable.** Every pointer is a label: jump and call targets, address tables, and
   immediate values that are addresses. Test: `python tools\reloc.py IMAGE...` moves the code, and
   MAME must play the same as the byte-exact set (the CRC will change).

Stage 3 needs level 1. Level 2 is required only for changes to the arcade code itself.

All four images pass exactly, within what the runs reach. The main CPU's sets are built with its
carry-dependent address sums made constant in time, which takes a race between the CPUs out of the
test. Method, results and the rule: `notes\relocation.md`.

---

## 7. What is left

1. **Relocation (Phase 8).**
   - The moved set has run everything `notes\relocation.md` lists, but by random play, and the
     true ending has been played only through the boss cheats.
   - Hidden 8-bit pointers: a search of the code found none, but a half read from a data table
     would not show (`notes\relocation.md`).
   - The blocks cut for room were never run or read in 86 runs and have no label pointing at them:
     that is evidence, not proof.
2. **Consolidation (Phase 9).**
   - Optional: compare against Ver 0.0 (`a78-06.51`/`a78-05.52`) and the US sets to document
     version differences (the "SELECT GAME MODE" mode-select path, bug fixes). This needs those
     sets: `roms\` holds only Ver 0.1.
3. **Open questions.** `notes\open_questions.md`, and the "Still open" or "Still to do" sections of
   `notes\levels.md`, `notes\sound.md`, `notes\sprites.md` and `notes\sub.md`. None blocks stage 3
   unless the subsystem it touches is being translated.
