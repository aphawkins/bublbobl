# Bubble Bobble Arcade — Project Plan

Three stages take Taito's 1986 arcade Bubble Bobble from ROMs to a C# game in
[The Sharp Kind](https://github.com/aphawkins/the-sharp-kind):

| Stage | Result | Plan |
|---|---|---|
| 1. Disassemble | Documented assembler source for all four CPUs, plus extracted data | [EXTRACTION_PLAN.md](EXTRACTION_PLAN.md) Phases 0–7 |
| 2. Reassemble | A set built from that source that is byte-exact and runs in MAME | [EXTRACTION_PLAN.md](EXTRACTION_PLAN.md) Phase 8 |
| 3. Reimplement | The Sharp Kind's Bubble Bobble plays the arcade game, in both renditions | This file, §3 |

---

## 1. Decisions

| Date | Decision |
|---|---|
| 2026-10-14 | The game logic follows the **arcade** code. Where the arcade and the C64 differ, the arcade wins. This supersedes the rule "Faithful to the C64, not the arcade" in `docs/bb-port-plan.md`. |
| 2026-10-14 | Two renditions play the same game. **8-bit** is the C64 look and sound (the existing assets). **16-bit** is the arcade look and sound. |
| 2026-10-14 | The golden source is this repo's `src\`, proved byte-exact against the `bublbobl` set (Japan, Ver 0.1). |

These decisions need entries in the repo's `docs/decisions.md`, with the old rule marked
as superseded (see §3.1).

---

## 2. Stages 1 and 2 — summary and exit criteria

The detail is in [EXTRACTION_PLAN.md](EXTRACTION_PLAN.md). Stage 3 can start when:

- `python tools\build.py` makes a byte-exact set, and MAME runs it with no checksum warning.
- The main CPU and sub CPU source names every routine that stage 3 translates.
- `notes\ram_map.md` names the work RAM, shared RAM (`E000–F7FF`) and MCU RAM (`FC00–FFFF`).
- The MCU's jobs and its shared-RAM contract are documented (`notes\mcu_shared_ram.md`).
- The level, enemy, item and text formats are documented, and `build\` holds their decoded
  JSON.
- The sound command catalogue lists every command the main CPU sends.

Stage 3 can start on a subsystem before all of Stage 1 is complete. That subsystem's routines
must be translated, named and in a byte-exact build.

---

## 3. Stage 3 — C# reimplementation in The Sharp Kind

### 3.1 Repo documents to change first
- `docs/decisions.md`: add the three decisions in §1. Mark the C64-first rule as superseded.
- `docs/bb-port-plan.md`: change the scope and rules. The golden source becomes
  the `bublbobl` repo's `src\`. The oracle and capture tools change (§3.6). The C64 reference
  (`rebb64`) becomes the reference for the 8-bit rendition's art and sound only.
- `docs/bb-readme.md`: change the description and credits ("converted from the arcade
  original", with the C64 rendition credited to Software Creations and Peter Clarke).
- These are architectural changes, so use the repo's tiered pipeline (`AGENTS.md`). Andy
  commits.

### 3.2 Shape

```
src/bb/libs/BubbleBobbleSharp.Abstractions/            contracts and view models (arcade terms)
src/bb/libs/BubbleBobbleSharpLib/                      the game: translated from the Z80 source
src/bb/libs/BubbleBobbleSharp.Renditions.EightBit/     C64 look and sound (existing)
src/bb/libs/BubbleBobbleSharp.Renditions.SixteenBit/   arcade look and sound (new)
src/bb/apps/BubbleBobbleSharp/
src/bb/test/BubbleBobbleSharpLib.Tests/
```

Keep the repo's standing rules, with the reference changed to the arcade source:
- One assembler routine becomes one C# method. Its comment gives the CPU and address:
  `main:$1A2B`, `bank2:$9C40`, `sub:$0F10` or `mcu:$F8F1`.
- Bytes wrap on purpose. Keep the Z80's parallel tables until the game is verified.
- Never tune a constant. Never invent behaviour. If a routine is unclear, stop and ask.
- Name things from what the code does, not from a guess in the notes.

### 3.3 Four CPUs become one game loop
The arcade divides the game between four processors. The C# game has one loop per frame.

| Arcade | C# |
|---|---|
| Main Z80 (game logic, IM 2 interrupt from the MCU) | The core of `BubbleBobbleSharpLib` |
| Sub Z80 (role found in Stage 1, through shared RAM `E000–F7FF`) | Translated into the same loop, at the place in the frame where its results are read |
| MCU (inputs, coins, IRQ, EXTEND counter, other jobs from Stage 1) | Small services: input, credits, the EXTEND counter, and any other job that affects the game |
| Sound Z80 | Not translated. The game sends **sound command IDs**. Each rendition decides what they sound like |

- **Order in the frame.** At vblank the main CPU, the sub CPU and the MCU all start work.
  The order in which they read and write shared RAM decides what the game does. Stage 1
  must record this order (MAME traces of one frame on all three CPUs). The C# loop must
  keep it.
- **Randomness.** Find the arcade random routine and put it behind `IRandomSource`. The
  EXTEND letter is not random: the MCU increments `FC7C` modulo 6 at each vblank
  (`mcu:$F8F1`). Use a frame counter, not an RNG.
- **Things that stay out:** the watchdog, the ROM/RAM self-tests, the "dead copy" tamper
  trap, coin lockout, and the hardware handshake between processors. Each one is a short
  note in the translation, not code.

### 3.4 Models in arcade terms
The game builds models and each rendition draws them (`IView<TModel>`, `IViewSurface`). With
arcade logic, the models carry arcade values:
- positions on the arcade playfield (256 pixels wide);
- arcade level numbers and arcade layout data;
- arcade entity, item and animation identifiers;
- arcade sound command IDs.

Each rendition maps these values to its own art. No rendition holds game state.

**8-bit rendition (C64).**
- The playfield is 32 columns wide on both machines. Find out in Stage 1 if the row counts
  also agree. If they differ, the rendition maps rows. The game does not change.
- Each arcade entity, item and animation needs a C64 sheet frame. Make a mapping table, and
  list the arcade items that have no C64 art.
- Sound: map each arcade sound command to a C64 SID song or effect. A command with no
  mapping is a startup-checked gap, in the same way that `ViewRegistry` checks views. The
  existing `Song` enum becomes this mapping.

**16-bit rendition (arcade).**
- The screen is 256×224. The rendition declares it, and window scaling magnifies it.
- The palette is RGBx_444, which is exactly the 16-bit tier's colour budget
  (`AssetColourBudget.ChannelBits` = 4). Widen each channel by replication.
- Sprite and tile sheets come from the extracted graphics (EXTRACTION_PLAN Phase 2). The
  rendition draws frames from sheets. It does not copy the arcade's video RAM and object
  hardware. The offline object renderer from Phase 2.3 is only a tool to prove the sheets.
- The font comes from the arcade tiles, as a bitmap font sheet.

### 3.5 Arcade sound for the 16-bit rendition
The arcade uses a YM2203 and a YM3526 (FM synthesis). `SharpKind.Audio` has SID, MIDI with
SoundFont, and WAV. Options:

| Option | Fidelity | Work | Notes |
|---|---|---|---|
| A. WAV per sound command, recorded from MAME (`-wavwrite`, with each command written to `FA00`) | Exact | Small | Fits the 16-bit tier's WAV support. Loops need loop points |
| B. MIDI from the decoded sequences (EXTRACTION_PLAN Phase 7) | Notes are exact, the FM voices are not | Medium | Can be edited. Plays through the existing SoundFont path |
| C. FM chip emulation in `SharpKind.Emulation`, which plays the sound CPU's data | Exact | Large | Needs a Z80 (§3.6) and two FM chip models |

Recommendation: A first, so the rendition has sound early. Choose B or C later, if they
are needed.

### 3.6 Proof: the oracle and golden captures
The existing port proves each routine against `Rebb64Machine`, which runs the real C64 game
on `SharpKind.Emulation`'s 6502. The arcade needs its own oracle.

| Option | How | For | Against |
|---|---|---|---|
| A. MAME and Lua | `mame bublbobl -autoboot_script capture.lua` sets breakpoints at a routine's entry and exit, and saves RAM before and after into capture files | Exact hardware, available now, no new emulator | Slower. It is outside the test process. Interventions must be written in Lua |
| B. In-process machine | Add `CpuZ80` (and `Cpu6801`, or a high-level MCU) to `SharpKind.Emulation`. Write a `BublboblMachine` that runs the reassembled ROMs from `build\roms\` | The same shape as `Rebb64Machine`: `Bracket(entry, exit)`, fast, steady. The Z80 can be used for other games | A Z80 core with tests (ZEXALL), plus three CPUs to keep in step |

Recommendation: start with A to make the first captures. Move to B before the subsystem
work in §3.8 step 4, where many brackets need interventions.

The capture rules do not change. A capture records the bytes a routine can touch, before
and after. The port replays each capture byte for byte. Each write into the machine is an
intervention and is stated in the test header. Captures go in the repo. Tests that need ROMs
skip when the ROMs are absent, so CI still runs the captures.

Golden frames: one set for each rendition. They prove that the port does not change. They do
not prove that the port matches the arcade.

### 3.7 Assets and licence
- `tools/bb/export-arcade-assets.py` in the repo reads a ROM directory and writes the 16-bit
  rendition's assets (sheets, `palette.json`, `levels.json`, text, WAVs). If it runs again on
  the same ROMs, it must make the same bytes. ROMs are never committed.
- The game logic needs the arcade data (levels, enemy tables, item tables). It is not art,
  so it belongs to the game and not to a rendition. Both renditions use it.
- **Open question (Andy):** the repo already ships assets taken from `rebb64`, by Andy's
  decision. Should the repo ship assets taken from the arcade ROMs too? The alternative is to
  extract them on first run from a ROM zip that the player supplies.

### 3.8 Order of work
The game stays playable at each step.

1. **Documents** (§3.1). Record the decisions. Change the port plan.
2. **Oracle bootstrap** (§3.6 A). Capture one routine and prove that the replay works.
3. **Arcade data.** Export the arcade `levels.json` and enemy tables. Make a diff report
   against the C64 `levels.json`, because the differences are the first list of behaviour
   changes. Change the game to use the arcade data.
4. **Subsystems.** Replace them one at a time, in the existing plan's order: players,
   bubbles, enemies, items and scoring, specials, then the screens and the front end. Prove
   each translated routine with arcade captures. When an arcade routine replaces a C64
   class, delete that class and its C64 captures.
5. **16-bit rendition.** First the static playfield, then sprites, the HUD, text and screens,
   then sound (§3.5 A).
6. **8-bit rendition.** Change the views to the arcade models. Complete the sprite and sound
   mapping tables. Close the gaps that the startup check reports.
7. **Done.** The game plays from the title to the true ending in both renditions. Every
   translated routine has captures. Both renditions have golden frames.

---

## 4. Risks and open questions

- **Licence and distribution of arcade-derived assets** (§3.7).
- **The sub CPU's role** is not known yet. If it does a large share of the game logic, it
  changes the size of stages 1 and 3.
- **The C64 art may not cover the arcade.** The arcade has items, enemy behaviour and screens
  that the C64 conversion left out or changed. The 8-bit rendition needs a policy for these:
  new art in C64 style, the nearest existing frame, or nothing drawn.
- **Screen geometry.** The arcade is 256×224 with the score at the top. The C64 is 320×200
  with a sidebar. The 8-bit views need the arcade rows mapped to the C64 layout.
- **Timing.** The arcade runs at about 59.19 Hz. The repo's game speed is independent of the
  frame rate. Decide whether the game tick is 59.19 Hz, or 60 Hz with a note of the
  difference.
- **Version.** The target is Japan Ver 0.1. The US sets add a mode select and other changes.
  Supporting them is a separate decision.
