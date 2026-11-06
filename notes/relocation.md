# The relocation test

The test for the second level of done (`EXTRACTION_PLAN.md` §6): every pointer is a label, so
the code can move and the game still runs. What is left to do is in `EXTRACTION_PLAN.md` §7.

`python tools\reloc.py IMAGE...` adds N bytes after the image's fixed vectors, takes N out of its
free space, and balances the ROM's own sum with the padding, so no code is patched. MAME then
plays the same inputs on the byte-exact set and the moved set. Every sampled screen must match
(attract mode and random play), and for sound every YM register write must match in value and
time. Two broken sub ROMs and a broken sound ROM were tried, and each was caught.

The test only proves what the run reaches: one round of random play, not all 100 rounds, and not
test mode. For the sub CPU and the MCU the reading of the code covers the rest, as they hold few
pointers.

## Sub CPU, MCU and sound

Done 2026-11-05, each at several pad sizes, odd ones included, and all three moved at once.
Moving these images' code does not change their timing, so they must match exactly.

| Image | Found | Result |
|---|---|---|
| Sub | Nothing: `ROUND_LAYOUTS` was the only ROM pointer | Same screens |
| MCU | `SPEED_PATTERNS` and `FETCH_BLOCKS` start with pointers, which were `.incbin` bytes. Moved, the speed lookups read the wrong lists, and an enemy moved differently | Same screens |
| Sound | 660 pointers in the data, 15 pushed or passed code addresses, and `TAMPER_CHECK`'s 6 fixed reads | Same screens; same writes for 55 of the 57 commands |

Sound command 2E is left out, because what it plays depends on the layout (`notes/sound.md`). 00 is
not tested on its own: it is the stop sent before each of the others. `tools\soundptrs.py` writes
the data pointers through `tools\dataptrs.py`, which any data format can use.

## Main CPU

Passes, within what the runs reach. `python tools\reloc.py main` moves the fixed ROM and banks 0-3
together, with pads at both ends of each half so that every label changes. No missed pointer is
left in what the runs reach. When main moves, a race between the CPUs can leave a bubble a pixel
off for a moment, so a difference of up to 60 frames is allowed (the project owner's decision,
2026-11-06).

Checks of 2026-11-06, all at 300 seconds unless noted:

| Check | Result |
|---|---|
| Pad 8, seeds 1, 2, 4, 5 | Same on all 1200 samples |
| Pads 1, 3, 7, 9, 10, seed 1 | Same on all 1200 samples |
| All four moved at once, pad 8, seed 2 | Same 1200 samples; same 523,524 register writes |
| Sub, MCU, sound alone, pad 8, 120 seconds | Still pass |
| One pointer broken on purpose (`DATA_60EF`), 120 seconds | Caught at frame 3750 |
| The old `IRQ_VECTOR_ENTRY` put back, 30 seconds | Reported as a reset |
| Pad 8, seed 3 | Passes, with 2 short differences: frames 7455 and 11985-12015. The race below |
| Pads 2 and 16, seed 1 | Pass, with 1 short difference: frames 8520-8550. The race below |
| `RELOC_CELL` taken out, pad 8, seed 1 | Fails: frames 15555-15735 and 15810-16710 |
| The same pointer broken, under the 60 frame rule, 120 seconds | Fails: frames 3750-5175 |

What the work found:

- `IRQ_VECTOR_ENTRY` was read as code, so it kept `044D` and the machine reset every 151 frames.
  It is now `.word IRQ_HANDLER`. `reloc.lua` reports a reset as a failure: MAME reruns the autoboot
  script on each reset, so the frame count would never end. MAME runs have a 600 second limit.
- `ld hl,BANK_WINDOW` (the palettes) and `ld de,BANK_WINDOW` (bank 3 tiles) were data addresses.
- **Moving the main CPU's code does change its timing**, unlike the images above: `ADD_HL_A` and
  its like run an extra `inc h` when a table crosses a page. This is the inferred reason `R` differs;
  the extra instructions were not counted directly. The game's 15 `ld a,r` random reads then differ.
  So `reloc.py` makes them `ld a,i` (same size, time and flags) in both sets, and compares with a
  reference set built the same way with a pad of 0. The random branches therefore always see one
  value in this test, which narrows what it covers.
- **The game's behaviour depends on where `DATA_622A` is.** `SPAWN_BUBBLE` calls `GRID_CELL` with
  the HL that `RAND_TIMER_SET` leaves, `DATA_622A + SPEED2_SEL`, and not the bubble's position
  (`notes/levels.md`). This was the whole of the difference in seeds 1 and 2 (71 and 58 samples),
  both in the attract demo after game over, where the runs really did part until the demo ended.
  It predicts the values seen: on round 22 (`ROUND_MAIN` 0x15) with `SPEED2_SEL` 5, the first such
  bubble's cell is 3 at `622F` and 0 at `6227`. `reloc.py` gives `GRID_CELL` the original value,
  through `RELOC_CELL` in the cut, in both sets; seeds 1 and 2 then match on every sample. As with
  sound command 2E, this is the game depending on its layout, and a real change to the code would
  change how those bubbles drift.
- **Room.** The fixed ROM has no free space and bank 0 has 1 byte, so the padding comes out of code
  that never runs. The IM 2 entry must stay at `0B2E`, or `I` and the MCU's vector must change.
- **The ROM sums.** There are 30 `ROM_SUM_STEP_*` routines, over ranges that overlap, and they
  cannot all be balanced with one byte, so these and `0x333F` are made to pass for the test.

## The race

Every remaining difference starts at a bubble's push byte, `+13` or `+14` of its slot: `E7F7` (seed
3, frame 7453), `E848` (seed 3, frame 11981), `E7A8` and `E910` (pads 2 and 16, frame 8508). The sub
CPU adds to `+14` (sub `06B0`), and the main CPU reads, applies and clears it (`62BD`-`62F6`), with
nothing to keep them apart, so a few microseconds decide how much lands in which frame. A bubble is
then a pixel off for up to about 40 frames. In each case the game RAM and object RAM (`DD00-DFFF`,
`E200-F7FF`) were compared frame by frame: only those bubbles' bytes differ, apart from pointers,
and then they match again. This comes from the traced bytes and the code; the race has not been
removed to prove that nothing is left behind it. `+13`'s code was not read: the sub CPU writes it
at `088A`, as traced on 2026-11-05.

## The rule

With main moved, `reloc.py` joins differing samples less than 60 frames apart into stretches and
prints each one. A stretch of up to 60 frames passes, unless it is still going when the run ends.
Sub, MCU and sound alone must still match exactly, as their timing does not change. The race has
lasted up to about 40 frames, and the two faults tried lasted 900 and more. A real fault with only
a brief effect would pass, so read the stretches a run prints: a new one is worth tracing.
