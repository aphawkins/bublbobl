# Bubble Bobble — Arcade Decompilation

![Bubble Bobble arcade title screen](docs/images/bubble-bobble-arcade-title.png)

A disassembly and decompilation of Taito's 1986 arcade game **Bubble Bobble**
(MAME set `bublbobl`, Japan Ver 0.1).

## Goals

1. **Disassemble** — documented assembler source for all four CPUs (main Z80, sub Z80,
   sound Z80 and the 6801 MCU), plus extracted data (graphics, palettes, text, levels,
   enemy tables, music) in open formats.
2. **Reassemble** — rebuild a byte-exact ROM set from that source that runs in MAME.
3. **Reimplement** — a C# version of the game in
   [The Sharp Kind](https://github.com/aphawkins/the-sharp-kind).

See [PLAN.md](PLAN.md) for the overall plan and
[EXTRACTION_PLAN.md](EXTRACTION_PLAN.md) for the disassembly and reassembly detail.

## ROMs

No ROMs are included in this repository. You must supply your own legally obtained copy
of the `bublbobl` set and place it in `roms/` (`roms/bublbobl/` or `roms/bublbobl.zip`).
The `roms/` folder is git-ignored.

## Requirements

- Python 3 (with Pillow)
- [MAME](https://www.mamedev.org/) (including `unidasm`)

## Legal

Bubble Bobble is © Taito Corporation. This project is an unofficial, non-commercial
study and is not affiliated with or endorsed by Taito.
