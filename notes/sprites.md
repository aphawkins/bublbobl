# Sprites

What each sprite-drawing call site draws, from the sheets `tools/sprites.py` builds out of
the traced runs (`build/gfx/sprites/`). The descriptions say what the frames show. A
name in `symbols.toml` needs the code to agree, as for the enemy groups below.

Runs so far: attract, scripted 1P and 2P play, a recorded game from round 1 (`spr_play`,
25,452 frames, to at least round 10) and one from round 20 (`spr_r20`, 16,463 frames,
`trace.py play --round 20`), and one from round 30 (`spr_r30`, 7,115 frames). 774 frames
from 88 call sites.

## How a sprite is drawn

- `SPRITE` (`147D`) / `SPRITE_FLIPX` (`149C`): A = gfx_num, B = first of 4 tiles,
  C = tile attribute. The tile bank is in the attribute of the object showing the block
  (`OBJ_SHADOW`, `E1CD`).
- Almost every caller steps `ANIM_STEP` (`15CA`) and computes B inline, so the frame
  tables are mostly instruction operands. The player is the exception (`PLAYER_ANIMS`).
- "Caller" is the CALL whose return address is on the stack. A routine that ends in
  `JP SPRITE` is listed under its own caller (e.g. `41BA` calls `PLAYER_SPRITE`).
- IX is logged with each draw. Most callers point IX at the record of the thing they
  draw, which ties a frame to a slot table.

## Enemies

`ROUND_ENEMIES` (`bank0:85A9`) splits round-record bytes 4–6 into six counts,
`ENEMY_COUNTS` (`ED3E–ED43`), and runs one init per group. Each group has its own slot
table and update code. `ENEMY_SWAP` (`E5A4`, record byte 12) replaces group 0 (b0) or
group 2 (b4) with a second kind, which has its own tables. That gives eight kinds:

| Group | Slots | Stride | First round | Seen as |
|---|---|---|---|---|
| 0 | `ENEMY0_SLOTS` `ED49` | `0x19` | 1 | Zen-chan: walk `bank0:9155`, tiles `964–988` |
| 0, swapped | `ENEMY0B_SLOTS` `F2AA`, `ENEMY0B_AUX` `ECAA` | `0x19`, `0x11` | 60 | not yet traced |
| 1 | `ENEMY1_SLOTS` `EDF8` | `0x19` | 30 | Banebou: `bank0:9155` (`B98–BB4`), `bank0:8F90` |
| 2 | `ENEMY2_SLOTS` `EEAC` | `0x23` | 6 | Mighta: walk `bank0:94C3` (`1008–101C`), throw `bank0:8237`/`8260` (`1054–1098`) |
| 2 | `ENEMY2_SHOTS` `EC29` | | 6 | Mighta's rock: roll `bank0:83BC` (`1004–1034`), break `bank0:83E7` (`10A4–10AC`) |
| 2, swapped | `ENEMY2B_SLOTS` `F1E7` | `0x19` | 50 | not yet traced |
| 3 | `ENEMY3_SLOTS` `EFA1` | `0x1B` | 40 | not yet traced |
| 4 | `ENEMY4_SLOTS` `F05F` | `0x19` | 20 | Pulpul: `bank0:9B9D` (`B68–B84`) |
| 5 | `ENEMY5_SLOTS` `F113` | `0x19` | 10 | Monsta: `bank0:A088` (`14CC–14D8`) |

Code shared by the groups:
- `ENEMY_ANIM_SPRITE` (`bank0:913C`, calls at `9155`/`9159`): walk frames for groups 0
  and 1. `bank0:915D–9171`: one frame, used by groups 0 (`964`) and 2 (`1038`).
- `7EBF`/`7EC4`: the enemy trapped in a bubble, then the food it turns into. The bubble
  frames are 4 tiles from `C04 + 0x10 × group`: seen for groups 0, 1, 2, 4 and 5, so
  group 3's should be `C34–C40`.
- `7F47`: the score for a popped enemy (`E48–E8C`). `7F75`: sparkle (`ABC–AC4`).
- `7CCB`, `bank0:8910`: tile `C00`, a blank frame.

Other enemy-like tables, with an init in `ROUND_ENEMIES` but no count:

| Slots | Init | Seen as |
|---|---|---|
| `F1C2` | `bank0:A108` | Skel-Monsta, the skull ghost (`bank0:A3F6`, `14E4–14E8`); `bank0:A4AE` drew cyan drops and an `ooo` frame (`CB0–14B0`) |

## Players

| Caller | Frames | Shows |
|---|---|---|
| `41BA` | 46 | Bub (colour 7) and Bob (colour 8), through `PLAYER_SPRITE` (`450D`) |
| `4434`, `4442` / `443D`, `444B` | 22 / 10 | death: spinning player, then stars |
| `4671` | 11 | numbers over the player (`1600–16E0`) |
| `4D59`, `4D87`, `4DDE` | 48, 16, 18 | the bubble being blown (IX = `E700`) |
| `4075` | 12 | "PUSH 1P / 2P" with Bub and Bob |

## Bubbles and items

The bubble slots are 0x28 bytes from `E76C` (IX `E76C`, `E794`, `E7BC`, …).

| Caller | Shows |
|---|---|
| `5D73` | bubbles (`805–890`) |
| `5E41` | bubbles, tiles `1504–1690` |
| `5F50`, `5FB6` | bubble popping, "Pon" |
| `6408` | small bubbles (`804–850`) |
| `2700` | small rings growing (`8D4–8E8`), IX in the bubble slots |
| `2801` | bubble fragments (`1364–1388`) |
| `64E1` | food from bubbles (cherries, fries) |
| `65A0` | "700" |
| `6EAB` | EXTEND letter bubbles (tiles `104–118`, colour 13) |
| `664F` | fire bubble flames (`1494–149C`) |
| `66EB`, `6732` | lightning bolt, and its burst (`14A0–14A8`, `D04–D18`) |
| `bank2:84E0`, `bank2:86D4` | items: food, cake, candy (IX `E6F0`) |
| `bank2:8581`, `bank2:8771` | item scores |

## Screens

| Caller | Shows |
|---|---|
| `07C6` | HURRY UP!! |
| `3964–3C2D` | round start: "ROUND", the number, arrows, Bub (colour 7) and Bob (colour 8) |
| `bank2:B08E` | INSERT COIN / JOIN!! panels |
| `bank2:9CF2–9DFD` | on the round-20 board: the two captives in bubbles with HELP!!, and the cage machines (IX `F537`, `F541`) |
| `bank2:B0C2`, `B0D5` | Bub on the title screen |

## Still to do

- Rounds that use group 3 and the two swapped kinds (from rounds 40, 60 for group 0 and
  50 for group 2), the bosses and the endings.
- Per-character sheets: group the frames by slot table instead of by caller.
