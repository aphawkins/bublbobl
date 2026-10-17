# Sub CPU

The sub Z80 (`a78-08.37`) sees only its own ROM (`0000–7FFF`) and the work RAM it shares
with the main CPU (`E000–F7FF`, at the same addresses). It has two jobs:

- **Round walls.** `GRID_UNPACK` unpacks each round's layout into `ROUND_GRID` when the
  main CPU asks (`notes/levels.md`).
- **Hit tests.** Once a frame it compares the players, the enemies, the enemy shots, the
  bubbles and the special effects, and writes the results into the main CPU's records.
  It moves nothing itself. The main CPU reads the flags and does the dying, popping and
  scoring.

The source is `src/sub/sub.s`. It assembles byte-exact. All `0x0C85` bytes of code
(`0000–0CFB`) are written out as instructions, except the RST and NMI gaps (FF), one byte
at `018F`, and the jump table `PUSH_TABLE`. The rest of the ROM is layout data, kept as
`.incbin`. `tools/dasmz80.py sub --table 0785:16 --entry 05B3` made the first pass.

## Frame

`RESET` sets IM 1 and the stack (`F7CE`, down into `F7C4`), runs `ROM_SUM_CHECK`, and
idles. Each vblank interrupt runs `VBLANK`:

| Order | Routine | Address | Runs when |
|---|---|---|---|
| 1 | `GRID_UNPACK` | `00A9` | `GRID_REQUEST` = 1 |
| 2 | `GHOST_HITS` | `02E0` | `SUB_CHECKS` = `'I'`, or main state `E723` = 29 |
| 3–17 | the hit tests below, then `MAIN_WATCHDOG` | | `SUB_CHECKS` = `'I'` |

`SUB_CHECKS` (`F66B`) is `'I'` (49) during play. The main CPU sets it at `080D` and `4E47`
and clears it at `0660` and `078D`.

## Hit tests

Distances are boxes: `|dY|` and `|dX|` both under the limit. Y is larger higher up the screen
(`GRID_CELL` takes row = −Y / 8).

| Routine | Address | Tests | Result |
|---|---|---|---|
| `PLAYER_ENEMY_HITS` | `01B9` | each player against `ENEMY_HITS` b0, within 0x0A | the player is killed (`P1_KILL`), or with the player's +13 b0 the enemy is beaten (+0 = 2, `ENEMY_TOTAL` − 1) |
| `PLAYER_ENEMY_MARKS` | `0266` | each player against `ENEMY_HITS` b3, within 0x10 | the enemy's +3 = 1 or FF (which player) |
| `BUBBLE_HITS` | `03BB` | each bubble by state, against the players and effects | flags in the bubble (+1A, +26), pushes (`BUBBLE_PUSH`), pops (`POP_BY_PLAYER`) |
| `POP_CHAIN` | `08F0` | bubbles within 0x14 of last frame's pop | they pop too: the chain |
| `EFFECT_A_HITS` | `0A30` | records at `F47E` (8 × 9) against enemies, within 0x0F | enemy killed, +3 = 6 |
| `EFFECT_B_HITS` | `0A67` | records at `F4CE` (8 × 8) | as A |
| `EFFECT_C_HITS` | `0A9E` | the point at `F597`, within 0x18 | enemy killed, +3 = 8 |
| `EFFECT_D_HITS` | `0B4C` | the record at `F5AD` | as A |
| `ENEMY2_SHOT_HITS` | `0C46` | `ENEMY2_SHOTS` against the players, within 8 | player killed |
| `ENEMY3_SHOT_HITS` | `0BCF` | `ENEMY3_SHOTS` | player killed, +19 = 1 |
| `ENEMY2B_SHOT_HITS` | `0C79` | `ENEMY2B_SHOTS` | player killed |
| `ENEMY0B_SHOT_HITS` | `0B98` | `ENEMY0B_SHOTS` | player killed, +19 = 1 |
| `BOSS_SHOT_HITS` | `0CA6` | `BOSS_SHOTS` (the bottles) | player killed |
| `BOSS_HITS` | `0CCE` | `BOSS_SLOT`, within 0x24 | loose: the player is killed; trapped: +0D = the player |

A player can't be killed while `E690`, their +25 or their +13 is nonzero, or while their Y
is outside 08–F7 (08–EF for the shots). A kill writes 0x10 to the player's +0.

A bubble in state b5 kills an enemy it touches (+3 = 8) and adds 1 to `E5F4` (`0572`), one
of the `SPECIAL_RULES` counters. In round 100 it hits the boss instead (`BOSS_SLOT` b7,
`F2A1` + 1, at `05A8`).

### Bubbles

`BUBBLE_PUSH` (`0772`) moves the bubbles ahead of a bubble in its direction (+0F, the
same values as the air current: 0–1 up, 2 right, 3 left, 4 down, 5–6 none). It goes through
`PUSH_TABLE`. A pushed bubble steps +13 (Y) or +14 (X), two steps when its +1E b0 is set.
This keeps the bubbles apart as they gather under the ceiling.

`PLAYER_BUBBLE` (`0664`) is a player meeting a bubble. A bubble just ahead in the
player's facing is pushed. A nearer one is popped. A player coming down on one (+23 = 3)
pops it from close above, or bounces from a little higher (the player's +24 b0).

A pop is recorded in `POP_FLAG` (`F66F`) with the bubble's Y and X. The next frame,
`POP_CHAIN` pops every bubble within 0x14 that holds an enemy. Each enemy bubble in the
chain adds 1 to `POP_CHAIN_N` (`F673`), and its number in the chain goes into the bubble's
+22. It also adds 1 to the player's count in `POP_ENEMIES` (`F677` / `F679`). From the
second one on, `F676` goes up by 1, or by 2 when `E5D7` = 3.

## Protection and checks

- **`ROM_SUM_CHECK` (`017B`).** The byte sum of `0000–7FFF` must be 0. On any other sum the
  CPU hangs before it enables interrupts. `GRID_UNPACK` then never answers, and the main
  CPU waits at the first round for ever. The sum is 0. The byte at `018F` (96), after
  the hang loop, is never run and may be the byte that balances it.
- **`MAIN_WATCHDOG` (`0190`).** If `MAIN_FRAME` (`E338`, stepped by the main CPU's
  interrupt at `04D3`) has not changed for 0x3C sub frames, the sub CPU writes the
  complement of `E800–EFFF` over `E000–E7FF` and hangs. A main CPU that stops for about a
  second loses its work RAM.

## Unused

- `UNUSED_TOUCH` (`05B3`): `BUBBLE_PUSH` and then `PLAYER_BUBBLE` for both players. It is
  valid code that nothing calls or jumps to.
- `NMI` (`0066`) only returns.
- `LAYOUT_101` (`7E9C`): see `notes/levels.md`.

## Still open

- What the effect records A–D are (`F47E`, `F4CE`, `F595`, `F5AD`): probably the water,
  fire and lightning, and what +3 = 6 and 8 mean in `ENEMY_HITS`.
- What each bubble state bit (+0 b0–b7) is, from the main CPU's dispatch at `5C37`.
- The player fields the tests read: +13, +19, +1B/+1C, +20, +23, +24, +25, +2D; and
  `E690`, `E723`, `E730`, `E737`, `E5D7`, `F676`.
