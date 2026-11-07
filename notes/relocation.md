# The relocation test

The test for the second level of done (`EXTRACTION_PLAN.md` §6): every pointer is a label, so
the code can move and the game still runs. What is left to do is in `EXTRACTION_PLAN.md` §7.

`python tools\reloc.py IMAGE...` adds N bytes after the image's fixed vectors, takes N out of its
free space, and balances the ROM's own sum with the padding, so no code is patched. MAME then
plays the same inputs on the byte-exact set and the moved set. Every sampled screen must match
(attract mode and random play), and for sound every YM register write must match in value and
time. Two broken sub ROMs and a broken sound ROM were tried, and each was caught.

The test only proves what the run reaches. `--round` (below) starts the game on any round, so all
100 have been played, by one player and by two, and `--scenario` and `--special` reach test mode,
the super mode, the Japanese notice, every special item and the secret rooms. All of that is random
play, which loses its lives soon. For the sub CPU and the MCU the reading of the code covers the
rest, as they hold few pointers.

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

Passes exactly, within what the runs reach. `python tools\reloc.py main` moves the fixed ROM and
banks 0-3 together, with pads at both ends of each half so that every label changes. No missed
pointer is left in what the runs reach. Both sets are built with the game's carry-dependent address
sums made constant in time (below), and with that, every sample must match. This replaces the
allowance of 60 frames decided on 2026-11-06 (the project owner's decision, 2026-11-07).

`python tools\reloc.py main --round 1-100` plays the same game from each round, side by side. It maps
the PCs in `tools\cheats.lua` through the link symbols, and fails a run that never held its round.

Checks of 2026-11-07:

| Check | Result |
|---|---|
| `--round 1-100`, pad 8, seed 1, 180 seconds, with `ld a,i` but not the constant sites | 16 rounds differ for over 60 frames, the first such stretch starting between frames 3915 and 10005, and 13 more have only short differences |
| The same, with the constant sites and `ld a,i` | Same on every sample, all 100 rounds |
| The same, pad 3, seed 2 | Same on every sample, all 100 rounds |
| The same, pad 8, seed 1, with the real `ld a,r` | Same on every sample, all 100 rounds |
| Pads 2 and 16 seed 1, pad 8 seed 3, 300 seconds: the runs that had short differences | Same on all 1200 samples |
| `--round 100 --boss-hits 80 --boss-pop`, 300 seconds | Same on all 1200 samples |
| All four moved at once, pad 8, seed 2, 120 seconds | Same 480 samples; same 523,524 register writes |
| Sub, MCU, sound alone, pad 8, 120 seconds | Still pass |
| One pointer broken on purpose (`B0_SPRITES_9231`, one enemy's sprites), `--round 1-100` | Caught on 11 rounds, none before round 46. Under the 60 frame rule 4 of those passed |

Checks of 2026-11-06, before the constant sites, all at 300 seconds unless noted. They allowed short
differences, and used `ld a,i`:

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

Checks of 2026-11-07 of the paths the random game does not reach, main moved, all passing unless noted:

| Check | Result |
|---|---|
| `--scenario testgrid`, pad 8 | Same on all 120 samples |
| `--scenario testsound`, pads 8 and 3: the sound picker stepped up 0x36 times and down 4, each number played | Same on all 432 samples |
| `--scenario testram`, pad 8, 6 runs | Same on all 240 samples in 5. MAME crashed in the sixth (below) |
| `--scenario japanese`, pad 8 | Same on all 600 samples |
| `--scenario super1p`, pad 8, 180 seconds | Same on all 720 samples |
| `--scenario game2p`, pad 8 seed 1 and pad 3 seed 2, 300 seconds | Same on all 1200 samples |
| `--scenario game2p --round 1-100`, pad 8, 180 seconds | Same on every sample, all 100 rounds |
| `--scenario game2p --round 100 --boss-hits 80 --boss-pop`, 300 seconds | Same on all 1200 samples; went on to `ROUND_MAIN` 0x64 |
| `--special 1-0x35`, pad 8, seed 1, 120 seconds | 53 of 53 |
| `--special 1-0x35`, pad 8, seed 2, 240 seconds | 53 of 53; in 52 the item is taken at frame 4740, so about 200 seconds of play follow |
| `--special 0x1E-0x28 --clear`, pad 8, 120 seconds | 11 of 11 |
| Kinds 31, 32, 33 in that 240 second run | Each entered the secret room three times and left it each time |
| `--scenario game2p --special 1-0x35 --special-player 2`, pad 8, seed 2, 240 seconds | 53 of 53, on all 960 samples each. Player 2 took 354 items and player 1 none; 3 went untaken (one of kind 05, two of 1A). Kinds 31, 32 and 33 each entered the secret room four times |

A special run fails if its item never showed and went, if the player asked for never took one, and
a door's if it never reached the room. The taker comes from the game's own write: `F460` in
`SPECIAL_TAKE`, or `IX+9` as `INVINCIBLE_ITEM_TAKE` writes `F518`, as kind 0E's item does not use `F460`.
The item is on screen for one frame, as the cheat puts the player on it. In the first special run the
item came at frame 6649 of 7200, so that run leaves only 9 seconds for its effect: hence the second.

Negative controls, each a label put back as its number, so right at pad 0 and wrong once moved:

| Broken | Run | Result |
|---|---|---|
| `B2_DATA_830C`, the test screen's input table | `--scenario testgrid` | Caught: 68 of 120 samples, frames 795-1800 |
| The same | The one-player game, 120 seconds | Not caught: same on all 480 samples |
| `SPECIAL_EFFECTS` | `--special 2` | Caught: 37 of 480 samples, and the rounds played differ |
| `DATA_55BB`, the secret room's colours | `--special 0x31` | Caught: 31 of 480 samples |
| `SPECIAL_EFFECTS` | `--scenario game2p --special 2 --special-player 2`, seed 2 | Caught: 308 of 480 samples, and the rounds played differ |
| `TEXT_35D8`, read only for player 2's name entry (`fixed:34D7`) | `--scenario game2p --special 1-0x35 --special-player 2`, seed 2, 240 seconds | Caught on 9 of the 53 kinds (15, 18, 1C, 20, 22, 24, 25, 26, 28), 14 to 203 of 960 samples. So those 9 games reached the entry, and with the label in place they matched |

## The RAM test and MAME's renderer

In `testram` the same set gave different pictures from run to run, at frames 150 and 300 on the
reference set (2598 and 342 pixels, in one column of objects), with every byte of RAM the same. The
byte-exact set did not vary in 3 runs. Some runs also ended early, and one that was caught exited
with `0xC0000005`, an access violation in MAME. So the machine was not what varied.

The RAM test fills object RAM with its patterns, such as `FF FF FF FF`. In `bublbobl_v.cpp`
`gfx_offs` plus the tile offset reaches `0x1FFF`, and `m_videoram` is `0x1D00` bytes, so `gfx_num`
BA-BF and FA-FF read past its end, into MAME's heap. These values were found from the PROM with the
driver's loop. Not every frame with such an object varied, so this explains the crash and the
variation but it was not shown pixel by pixel; the evidence is what happened when it was taken out.
`reloc.lua` now writes video, object and palette RAM (`C000-DFFF`, `F800-F9FF`) in place of any
sample with such an object on screen. These compare the same in every run; they hold no pointers.
In `testram` that is 231 of 240 samples, and no other scenario has one.

The crash stays. In 60 boots of each set in this DIP mode, 320 frames each, it came 2 times on the
moved set, once on the reference set, whose code has not moved, and never on the byte-exact set. So
moving code is not needed for it, but these counts are too small to say more, and why the byte-exact
set showed neither the crash nor the variation is not known: the constant sites change the test's
timing, which may be why. That the read past the buffer is what crashes is inferred from the exit
code, not seen in a debugger. `reloc.py` reports MAME's exit code as a failure, so run `testram`
again if the code is `0xC0000005`. This has not been reported to MAME.

What the work found:

- `IRQ_VECTOR_ENTRY` was read as code, so it kept `044D` and the machine reset every 151 frames.
  It is now `.word IRQ_HANDLER`. `reloc.lua` reports a reset as a failure: MAME reruns the autoboot
  script on each reset, so the frame count would never end. MAME runs have a 600 second limit.
- `ld hl,BANK_WINDOW` (the palettes) and `ld de,BANK_WINDOW` (bank 3 tiles) were data addresses.
- **Moving the main CPU's code does change its timing**, unlike the images above: `ADD_HL_A` and
  its like run an extra `inc h` when a table crosses a page. That changes `R`, which the game's 15
  `ld a,r` random reads see, and it decides the race below. So `reloc.py` sends the 7 such sites
  (`ADD_BC_A`, `ADD_DE_A`, `ADD_HL_A` and 4 inline copies; `CARRY_SITE`) to routines in the cut that
  take the same time either way, in both sets, and compares with a reference set built the same way
  with a pad of 0. That is why the sound baseline is that set too when main moves. These routines
  do not leave the flags as the originals do, so the two sets are not quite the real game, but they
  are the same as each other, and the random reads are real. Removing these 7 sites' differences
  removed every difference seen, so nothing else that moves has been seen to change the timing.
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

The test no longer sees this race, as both sets now run it alike. The race is still in the game:
on the real code, moving a table can decide it the other way. Over a whole game a pixel can matter:
without the constant sites, 16 of the 100 rounds parted for over 100 frames, some to the end of the
run. In RAM dumps of those rounds many of the first differences are a bubble's position or push byte,
but others (`E69F`, `F070`) were not explained, and rounds 37 and 99 start with many bytes at once.
They were not followed further, as all 16 matched exactly once the sites were constant.

## Hidden 8-bit pointers

Read 2026-11-07, for `fixed`, `bank0` and `bank2` (banks 1 and 3 hold no code). No `ld h,`, `ld d,` or
`ld b,` loads the high byte of a ROM address for use as one. The search also took constants that reach
a high register through `A`, `cp` of a high register, pairs of immediates, and pairs stored into
neighbouring cells. Of 293 hits, the ones that looked like addresses are:

| Site | Value | What it is |
|---|---|---|
| `bank2:A006` and the two after it | `1CE1`, `5CE1`, `9CE0` in `+8`, `+9` | A tile and its attribute, written to tile RAM. Only the flip bits change |
| `bank2`, after `L_A32E` | `1DC9`, `1DC8` | A tile and attribute at `CD00` and up |
| `bank0:A1FB` | `1578` | An object's X and attribute |
| `fixed:3FC1` | `0314` in `+46`, `+47` | Two fields, read one byte at a time |

The rest are positions, sprite coordinates, direction pairs and counters. This was a search of forms
in the code, not a proof: a pointer half read from a data table would not show. The data reads below
cover that case for everything the runs read.

## Data reads

`reloc.py main --reads` logs each ROM address the main CPU reads as data and the instruction reading
it, on both sets. Each becomes a label and a distance past it, through that set's link symbols, and
the two lists must be the same. A pointer left as a number, whole or in halves, reads other bytes
once moved, so it shows here even if no sampled screen does. The 23 ROM sums' `ld a,(de)` are left
out, as they walk the ROM by number. This sees only what the runs reach, as the screens do.

Checks of 2026-11-07, pad 8 unless noted, every scenario from the tables above:

| Check | Result |
|---|---|
| `--round 1-100`, one player and `game2p`, 180 seconds | 200 of 200: same screens, same reads (4639 to 7727 a run) |
| `--special 1-0x35`, seed 2, 240 seconds, player 1, and `game2p` with player 2 | 106 of 106 (5227 to 12695 a run) |
| `--special 0x1E-0x28 --clear`, 120 seconds | 11 of 11 |
| `--round 100 --boss-hits 80 --boss-pop`, 300 seconds: one player, `game2p`, `super1p` | 3 of 3 |
| `attract`, `japanese`, `super1p`, `testgrid`, `testsound`, `testram` | 6 of 6 |
| One player and `game2p`, pad 3, seed 2, 300 seconds | 2 of 2 (8291 and 6289 reads) |

Negative controls, through `--break LABEL`:

| Broken | Run | Screens | Reads |
|---|---|---|---|
| `B0_SPRITES_9231` | `--round 1-100`, 120 seconds | 10 rounds differ, one of them on 1 sample of 480 | The same 10, and they name the instruction: `L_9148+2` |
| `DATA_46B8`, the chain pop's sound commands | `--round 1-24`, 120 seconds | 9 rounds differ | All 24: `L_4617+0x12` reads `DATA_46AA+7` |

So reads caught 15 rounds that every sample of the screen missed. Why a wrong sound command changed
the screen on the other 9 was not followed.

### What no run read

`python tools\unread.py DIR...` counts the `.incbin` bytes no run read, leaving out the ROM sums. Over
414 logs (the 86 replays in `build\romreads\` and the 328 runs above):

| Image | `.incbin` bytes | Read | Unread | Unread 00 or FF |
|---|---|---|---|---|
| `fixed` | 4806 | 3901 | 782 | 123 |
| `bank0` | 2420 | 2174 | 225 | 21 |
| `bank1` | 16292 | 12076 | 1936 | 2280 |
| `bank2` | 3751 | 2574 | 249 | 928 |
| `bank3` | 16318 | 5590 | 41 | 10687 |

A pointer in these bytes would pass every run, so they were searched two ways. 107 unread pairs equal
a label's address. Those looked at are chance: text, and the unread end of `DEMO_INPUT_LISTS`, which
is most of `bank1`'s, are input and characters and not addresses. Not every one was read by hand.

The second search found a real one. Every run of `.word` lines that stops at an `.incbin` was checked
for going on with labels, and `L_61F4`, `BUBBLE_DRIFT`'s table, did: 7 entries were declared, and 9 more
`L_61B4` were left as bytes at `6202`. The index is a 4-bit cell, so the table has 16 entries. Every
round's grid, the attract and secret layouts and all 16 edge patterns hold only cells 0-4, so these
entries are never reached, which is why no run could show them. They are `.word` now
(`--table 61F4:16`). No other table in the five images went on like this. With that change the build
is still byte-exact, all 16 entries move in the moved set, and `--round 1-100 --reads`, 180 seconds,
passes 100 of 100. The other runs above were made just before it and were not repeated.

## The rule

Every sample must match, for every image. The 60 frame allowance has gone: with the race out of the
test it could only hide faults, as the broken pointer above showed. A sample with an object that
MAME draws from outside video RAM is compared as RAM, not as a picture.
