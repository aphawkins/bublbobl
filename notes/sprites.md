# Sprites

What each sprite-drawing call site draws, from the sheets `tools/sprites.py` builds out of
the traced runs (`build/gfx/sprites/`). The descriptions say what the frames show. A
name in `symbols.toml` needs the code to agree, as for the enemy groups below.

Runs so far: attract, scripted 1P and 2P play, a recorded game from round 1 (`spr_play`,
25,452 frames, to at least round 10) and one from round 20 (`spr_r20`, 16,463 frames,
`trace.py play --round 20`), round 30 (`spr_r30`, 7,115 frames), round 40 (`spr_r40`,
4,558 frames), round 50 (`spr_r50`, 3,107 frames), round 60 (`spr_r60`, 3,969
frames) and round 100 (`spr_r100`, 3,284 frames, which did not reach an ending). 1,164
frames from 104 call sites.

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
| 0, swapped | `ENEMY0B_SLOTS` `F2AA` | `0x19` | 60 | Invader: `bank0:9155` (`974–990`), `bank0:B192` |
| 0, swapped | `ENEMY0B_SHOTS` `ECAA` | `0x11` | 60 | Invader's laser: `bank0:850B`, `8566`, `8580` (`EC4–ED0`) |
| 1 | `ENEMY1_SLOTS` `EDF8` | `0x19` | 30 | Banebou: `bank0:9155` (`B98–BB4`), `bank0:8F90` |
| 2 | `ENEMY2_SLOTS` `EEAC` | `0x23` | 6 | Mighta: walk `bank0:94C3` (`1008–101C`), throw `bank0:8237`/`8260` (`1054–1098`) |
| 2 | `ENEMY2_SHOTS` `EC29` | | 6 | Mighta's rock: roll `bank0:83BC` (`1004–1034`), break `bank0:83E7` (`10A4–10AC`) |
| 2, swapped | `ENEMY2B_SLOTS` `F1E7` | `0x19` | 50 | Drunk: `bank0:A7A1`/`A7A7` (`1F04–1F9C`) |
| 2, swapped | `ENEMY2B_SHOTS` `F3CE` | `0x11` | 50 | Drunk's bottle: `bank0:BE56`/`BE5B` (`1F14–1F94`), `BCB1` (`1F00`) |
| 3 | `ENEMY3_SLOTS` `EFA1` | `0x1B` | 40 | Hidegons: `bank0:9155` (`1E04–1E80`) |
| 3 | `ENEMY3_SHOTS` `EB99` | `0x12` | 40 | Hidegons' fireball: `7B55`/`7B5B` (`1E4C–1E78`), `7AB3` (`1F00`) |
| 4 | `ENEMY4_SLOTS` `F05F` | `0x19` | 20 | Pulpul: `bank0:9B9D` (`B68–B84`) |
| 5 | `ENEMY5_SLOTS` `F113` | `0x19` | 10 | Monsta: `bank0:A088` (`14CC–14D8`) |

Code shared by the groups:
- `ENEMY_ANIM_SPRITE` (`bank0:913C`, calls at `9155`/`9159`): walk frames for groups 0,
  1 and 3 and Invader. `bank0:915D–9171`: one frame, used by groups 0 (`964`) and 2 (`1038`).
- `7EBF`/`7EC4`: the enemy trapped in a bubble, then the food it turns into. The bubble
  frames are 4 tiles from `C04 + 0x10 × kind`: groups 0–5 are kinds 0–5, group 0's
  swapped kind (Invader) is kind 6 (`C64–C70`) and group 2's (Drunk) is kind 7 (`C74–C80`).
- `7F47`: the score for a popped enemy (`E48–E8C`). `7F75`: sparkle (`ABC–AC4`).
- `7CCB`, `bank0:8910`: tile `C00`, a blank frame.

Other enemy-like tables, with an init in `ROUND_ENEMIES` but no count:

| Slots | Init | Seen as |
|---|---|---|
| `F1C2` | `bank0:A108` | Skel-Monsta, the skull ghost (`bank0:A3F6`, `14E4–14E8`); `bank0:A4AE` drew cyan drops and an `ooo` frame (`CB0–14B0`) |

## The boss

`BOSS_INIT` (`bank0:A847`) and `BOSS_SHOTS_INIT` (`bank0:B939`) do nothing unless
`ROUND_MAIN` is `0x63`, round 100.

| Table | Caller | Shows |
|---|---|---|
| `BOSS_SLOT` `F296` | `bank0:A9EB`, `A9FA` (in `BOSS_UPDATE`) | Super Drunk, 64 × 64 in 16 pieces, colour 12, bank 8 tiles `2000–20FF` |
| `BOSS_SHOTS` `F367` (stride `0x0C`) | `bank0:BAD5` | the boss's bottles (`1F40–1F4C`) |
| IX `EB36`, `EB46` | `6864` | the captives in bubbles (`1B04–1B90`) |

`BOSS_UPDATE` draws the 16 pieces at `bank0:A99A–A9FD` through `SPRITE_LIST` into gfx
blocks `0C–0F`. ANIM_STEP picks pose 0 or 1, or 2 or 3 when (IX+8) b0 is set. The
first tiles come from `BOSS_POSES` (`bank0:AF4C`): four poses starting at tiles `00`,
`40`, `80` and `C0`, each also stored mirrored. Piece *i* goes at column *i* mod 4,
row *i* / 4. The 16 positions are in `BOSS_PIECE_XY` (`bank0:AF0C`).

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

- The endings.
- Per-character sheets: group the frames by slot table instead of by caller.
