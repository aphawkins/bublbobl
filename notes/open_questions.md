# Open questions

Things seen in the code but not yet understood. Each one has the address where it
was seen. Close an entry by moving what was found into the notes it belongs to.

## MCU

"Traces so far" means the runs in `notes/ram_map.md`: attract mode, two games of scripted
random play (how far they got is not recorded), and both test modes. Later rounds may
still differ.

- **`CREDITS_42_JOB` (`mcu:$F8D5`).** If the main CPU writes `0x0D` to `FC71` while the
  MCU's round copy is 12, the MCU sets `CREDITS` to 42. Does the main CPU ever write
  `FC71`? Is this a test or operator feature, or a leftover?
  Traces so far: the main CPU writes `FC71` only in its start-up RAM test.
- **Coinage order (`mcu:$F187`).** The MCU table gives DSW coin field 0 = 2 coins 1
  credit and field 1 = 2 coins 3 credits. MAME's DIP list for `bublbobl` has 0x00 =
  2C_3C and 0x10 = 2C_1C. Check in MAME by setting the DIP and inserting coins. If the
  MCU is right, report it to MAME.
- **`FETCH_BLOCKS` (`mcu:$F9B1`).** 5 × 256 bytes that the main CPU can read one byte at
  a time through `FF88–FF93`. Parts are equal to sound ROM bytes (`a78-07` at `23B0`,
  `2450`, `2532`), and the rest reads as Z80 code. Which blocks, indexes and offsets
  does the main CPU ask for, and does it check the values (protection) or use them?
  Traces so far: the main CPU never touches `FF88–FF93` or the result areas.
- **The proximity check (`mcu:$F48F`)** can report a hit when one object matches in X
  and a different object matches in Y. Does the main CPU rely on `P1_PROX_HIT`, or only
  on the per-object records? If on the hit flag, is the cross-object match visible in
  play?
  Traces so far: the main CPU writes `P1_PROX_ON` (`3F04`) and reads the per-object
  records (`bank0`), but never reads `P1_PROX_HIT`, `P1_PROX_INDEX` or the P2 set.
- **`MCU_WATCHDOG` (`mcu:$F217`)** is complete but never called. Does the main CPU still
  update `ALIVE_COUNTER` (`FC7F`)?
  Traces so far: the main CPU writes `FC7F` only in its start-up RAM test.
- **`FFDF` stamp** `BR1O 29.JUN,1986 `: the date matches the MCU date in
  EXTRACTION_PLAN §1. Do these 17 bytes also balance the ROM word sum to 0?

## Main CPU

- SWB#7 `F7FE/F7FF` score output, routines `0F26` and `0F74` (from the MAME driver notes).
- **Palette 11 (`bank0:B764–B7FE`)** is rewritten colour by colour, and read back, in
  attract mode and in play. What is the effect, and where are its colours?
