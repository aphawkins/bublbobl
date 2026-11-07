# Main CPU

The main Z80 runs the game: `src/main/fixed.s` (`a78-06-1.51`, `0000–7FFF`) and `bank0/1/2/3.s`
(`a78-05-1.52`, four 16K pages at `8000`). Each routine's own note is in `notes/symbols.toml`; this
file is the overview. Rounds, items and difficulty are in `notes/levels.md`, sprites and endings'
screens in `notes/sprites.md`, the sub CPU's hit tests in `notes/sub.md`.

Some of this was seen in MAME and some only read from the code. [Read from the code, not seen in
MAME](#read-from-the-code-not-seen-in-mame) lists what has not been watched.

## Start-up, interrupt and tasks

- Reset is `DI / IM 2 / JP 00B9`. After start-up the CPU sits in `jr $` at `01ED`, and all game
  work runs in the IM 2 interrupt. It writes `2E` to `FC00` at `0130`, with I = `0B`, so the vector
  entry is `0B2E`, which holds `044D`, `IRQ_HANDLER`.
- `IRQ_HANDLER`: `SCHED_FREE` decides between the full path and `FRAME_TICK` alone on a side stack.
  The full path also reaches `FRAME_TICK`, because `OBJ_COPY` runs on into it, so it runs every
  frame. `notes/frame_order.md` has the timing of a frame on all three CPUs.
  `TEST_IRQ` runs in test mode. `TIME ERROR` shows if the interrupted PC is in RAM.
- `SCHEDULER` is a six-task coroutine scheduler, with RSTs `TASK_KILL`, `TASK_START`, `TASK_SLEEP`,
  `TASK_YIELD`, `TASKS_CLEAR`, `TASK_SPAWN` and `TASK_SWITCH`. `TASK_ENTRIES` (`0B22`) holds the
  entries: `ATTRACT_TASK`, `TITLE_TASK`, `ROUND_TASK`, `OBJECTS_TASK`, bank 0 `85A9`, `BUBBLES_TASK`.
- `OBJECTS_TASK` calls the page-2 entries that clear and run one state record each in `F46B–F65F`.
- `TABLE_WORD` (`0DA7`) reads the word tables that most state dispatch goes through.
- Sprites: objects are built in `OBJ_SHADOW` (`E1CD`) and copied to `DD00` by `OBJ_COPY` (`04AD`)
  at the next IRQ.
- Input: `READ_INPUTS`. In the attract loop `DEMO_INPUTS` plays (count, input) byte pairs from
  bank 1. `DEMO_RECORD`, which would record them, can't be reached.
- Sound commands go through a 15-entry queue (`SOUND_PUSH`, `SOUND_QUEUE_POP`).
- `--poke` holds from frame 240, because holding a byte sooner hangs the start-up RAM test at `0216`.

## Palettes

`LOAD_PALETTES` (`0B30`) copies `PALETTES` (`bank1:8000`, the whole `0x200`-byte palette RAM image;
palettes 14 and 15 are zero there). `LOAD_ROUND_PAL` (`0B43`) copies one of the 8 `ROUND_PALETTES`
(`bank1:8200`) into palette 14 or 15 by bit 0 of `ROUND_MAIN`; the index is byte 0 of the round's
record. Animated colours: palette 1 colour 14 cycles through 6 colours at `1BAE`, palette 1 colour 1
ramps from black to red through `2895`, palettes 7–8 come from `3CC2`, and palette 11 is changed by
`bank0:B764–B7FE` (`notes/open_questions.md`).

## Banks

- `BANK_PAGES` (`0293`) has two sets of `FB40` values. DSW-B:8 (ROM type) picks one: pages 0–3 all
  in IC52, or pages 2–3 in IC53.
- Bank 1 has no code. It holds the graphics and level data. Bank 3 has a few routines
  (`TAITO_CREDIT`, `BE00`), coin tables and secret room pictures.
- `STEP_TO_8_DOWN` (`7FF8`) runs off the end of the fixed ROM: its last instruction's operand and
  the rest of the routine are bank 0's first bytes (`07 C8 DD CB 00 66 C8 35 C9`), so it only works
  with bank 0 in.

## Tamper checks

Beside the MCU's and the sub CPU's, the main CPU checks itself all through play. Stage 3 leaves
all of these out (`PLAN.md` §3.3).

- `dead copy` (`334A–3352`): the check at `333F` reads `0B2E` and expects `4D`. On failure it falls
  into the ASCII, which runs as opcodes and derails the CPU. `bank0:950A` checks the same vector.
- The word at `0B2E` must be `IRQ_HANDLER` in `CAPTIVES_STEP` and `EXTEND_SCENE`.
- `0847`: (0004) compared with `START`. `ROUND_WIPE` (`BEA9`) checks `0004` too.
- `FILL_CHECKED` (`5C11`): bytes `0000–0002` must sum to `3E`. `ENDING_SCROLL_STEP` and
  `ENDING_START` each check byte `0002`.
- `BANK2_CHECK`: see `notes/levels.md`.
- 30 `ROM_SUM_STEP_*` routines, called in play from the enemy and player code, add one byte a call
  over ranges that overlap. For example A: every 4th byte of `0004–0C07`; B: every 2nd of
  `2642–731B`; S: bank 0 `8150–94FD`; T: all of bank 0; U: bank 0 `A103–BFFF`; V: every 8th from
  `598A`. The sum at `B4CB` runs into `SPECIAL_RULES` on a mismatch.

## Rounds

- Drawing: `GRID_DRAW_START`/`GRID_DRAW_NEXT` draw the grid a row at a time, `TILES_SAVE`/
  `TILES_RESTORE` move 4 tile columns, `ROUND_NUMBER_DRAW` draws the number.
- `ROUND_ENTRY_INIT`/`_RUN`: at a round's start each player's bubble floats from where the player
  was to the start corner (Y 28, X 10 or D0, `ROUND_ENTRY_MOVE`) and bursts. Then the round's tasks
  start.
- At each round's end `DIFFICULTY_BY_MINUTES` raises the difficulty to at least 0F, 14, 19, 1E after
  10, 15, 20 and 25 minutes of play. `ROUND_MILESTONE_FLAGS` sets the door flags (`notes/levels.md`).
- The HELP!! scene (`HELP_SCENE_RUN`): the captives at rounds 16, 32 .. 96.
- `JAPAN_NOTICE`: the "for use in Japan only" screen, 12 seconds, only with DSW0 b0 set (MAME's Mode
  "Game, Japanese"; `trace.py japanese` runs it).
- Coins: the main CPU counts coins itself, from `COIN_TABLE` (bank 3 `COIN_TABLES` by `COIN_REGION`),
  and writes `CREDITS`. The coinage DIP order is MAME's.

## Score and lives

`SCORE_ADD` (`30A5`, BCD) saturates at 999999. `BONUS_TABLE_PTR` (`3170`) is the bonus life table
picked by DSW1 b2-3, 8 entries of 3 BCD bytes. Entry 0 is the start value of `HIGH_SCORE` (`31E1`):
with DSW1 = FF every game snapshot has `HIGH_SCORE` = 003000. A continuing player's score goes in
the table as `CNT` (`HIGH_ENTRY_CONTINUE`).

`EXTEND_CHECK` (`6EF8`): with all six letters the letters flash and `EXTEND_SCENE` (`7007`) shows
NICE 1UP! (seen with `--poke E742=3F`). The player's dragon jumps under each big letter in turn, each
letter stops wobbling and flashes, the letter bubbles rise, one bubble drops into the lives column
and the life is added.

## Players

`PLAYER_PLAY_STEP` (`419F`) is a player's frame in play.

- `PLAYER_WALK` walks on the input until a wall, and starts `PLAYER_FALL` when there is no floor.
  `PLAYER_FALL_DRIFT` steers a fall or jump every third frame. `PLAYER_FACE_INPUT` sets the facing
  byte `IX+8` from the joystick.
- `PLAYER_JUMP_INPUT` starts a jump on the button or on a bounce off a bubble. `PLAYER_JUMP_MOVE`
  moves it a pixel at a time. `PLAYER_PUSHED` moves a player pushed by `(IX+34)`.
- `PLAYER_BLOW` writes the blow request (`E75E`/`E764`) with the bubble's range and speed.
- `PLAYER_POP_CHAIN` scores enemies popped at once: 2 = 2000, doubling up to 7 = 64000.
- `PLAYER_DEATH_STEP` is the hit player's spin.
- Boosts live in the player record: `IX+49` bubble range 40 to 80, `IX+47` bubble speed 3 to 6
  pixels a frame, `IX+46` wait between bubbles 14 to 5, `IX+48` walk speed row 0C to 13.

## Bubbles

- `BLOW_REQUEST_TAKE` gives a free bubble slot the request. `BUBBLE_BLOWN_FLY` flies it until a wall.
  `BUBBLE_FLOAT_SPRITE` and `TRAPPED_BUBBLE_SPRITE` draw an empty bubble and one holding an enemy.
- With 0x14 or more floating, `BUBBLE_CROWD_CHECK` and `BUBBLE_CROWD_POP` pop two empty ones.
- `BUBBLE_NO_CHECK` is `XOR A, RET`, so the jumps after its calls never run.
- A bubble's `IX+24` is 4 − the list value (`6E50`): `BUBBLE_FIRE_DROP` is `IX+24` 1 and
  `BUBBLE_LIGHTNING_POP` is 3.
- `SECRET_ROOM` (`E723`) survives a game over in the room, so the demo and the next game go into it.

## Enemies

Six groups, with the two swapped kinds (`notes/sprites.md`). Each has mode tables named by direction.

- **Shared by the walkers.** `ENEMY_WALK_L/R`, `ENEMY_JUMP_L/R`, `ENEMY_FALL`. After each walk step
  `ENEMY_WALK_THINK` alternates on a timer between `ENEMY_WALK_SEEK` (turn toward the target, read
  from the MCU proximity record) and `ENEMY_CLIMB_SEEK` (jump up toward it when the cells above are
  open). `94DB`, `97EC` and `A7B9` are per-group copies of `ENEMY_WALK_THINK` that nothing calls.
- **Group 2.** Lifts a rock over its head (`ENEMY2_ATTACK_LIFT`, called off by
  `ENEMY2_ATTACK_CANCEL` near a wall). On the last frame `ENEMY2_SHOT_LOOP` takes the rock over and
  `ENEMY2_SHOT_FLY` throws it.
- **Group 2B.** Winds up (`ENEMY2B_THROW_ANIM`), and `ENEMY2B_SHOT_LOOP`/`_FLY` throw a bottle, which
  ends when its owner is trapped or beaten.
- **Group 3.** A walking or falling enemy may throw (`ENEMY_ATTACK_CHECK`, `ENEMY3_ATTACK_START`)
  while `ENEMY3_SHOTS_FREE` (`F05E`) is nonzero. It starts at 2 when the group enters, a throw takes
  one and `ENEMY3_SHOT_END` gives it back, so at most two fireballs are out. `ENEMY3_SHOT_LOOP`
  launches from the owner in the owner's facing, and `ENEMY3_SHOT_FLY` moves it until a wall.
- **Group 4.** No attack. `ENEMY4_MOVE` flies it on a diagonal; each fly probes a side wall and a
  ceiling or floor (`ENEMY4_CELL_*`). A hit (`ENEMY4_LU_WALL` .. `ENEMY4_RD_FLOOR`) starts one of
  eight 21-step scripts in `ENEMY4_TURNS` (moves 0-7 by direction, 8 none, 9 end), so the enemy
  curves away. `ENEMY4_TURN` plays it a step a frame and `ENEMY4_TURN_BACK` reverses it early if it
  meets a wall. At the end the mode becomes the one the hit chose.
- **Group 5.** No attack. `ENEMY5_MOVE` flies it on a diagonal, with `ENEMY5_FALL` as mode 2, and it
  bounces straight off a wall into the next diagonal. `ENEMY5_STUCK_CHECK` compares its position over
  three bounces and steps the mode on if it has not moved, so it cannot stick in a corner.
- **Skel-Monsta.** `GHOST_UPDATE` (bank 0 `A150`) runs two ghosts, one for each player (`IX+9`).
  `GHOST_APPEAR` starts each at one of four `GHOST_CORNERS` picked from the players' positions (the
  middle of the room in the secret round) and fades it in (`GHOST_FADE`). `GHOST_CHASE` moves it by a
  speed pattern that `GHOST_STEER` points at its player, one axis at a time, switching axis every
  0x3A pixels and getting faster as `F1E6` runs down. It leaves (`GHOST_LEAVE`, `GHOST_REMOVE`) when
  its player is hit or the round is cleared. `GHOST_OFF_CHECK` clears `GHOST_ON` once both are gone.
  A ghost that kills the other player swaps targets with the other ghost first.
- **The boss.** After `BOSS_ENTER_END`, `BOSS_FIGHT` throws a volley every 0x78 frames
  (`BOSS_VOLLEY_TIMER`, `BOSS_VOLLEY`). `BOSS_SHOT_LOOP` launches all 8 bottles, each on its own path
  (`BOSS_SHOT_PATHS`, `BOSS_SHOT_STEP`, 3 pixels a step or 4 when the boss is angry), until it leaves
  the playfield; the next volley waits for all 8. At 0x50 hits the boss can be trapped
  (`BOSS_TRAPPED`). Popped, it flies off (`BOSS_BEATEN`) and the round ends, or in super mode with two
  players `BOSS_SUPER_END` plays the parents' scene. Left alone for 6 seconds it escapes angry.

## Special items

Kinds, items and counters are in `notes/levels.md`. What the effects do, from `trace.py --special K`
sweeps (`--clear` to end the round):

- **Kill all.** 05 and 1C: every enemy becomes a gem. 19 (`KILL_ALL_SHAKE_INIT`/`_RUN`): every enemy
  is beaten, the screen shakes for 0x30 frames, and each scores 3000.
- **Pickup rushes.** 09–0D and 2F: the playfield fills with pickups, with a timer and a P1 vs P2
  count (`RUSH_COUNT_INIT`/`_RUN`). When every pickup is taken each player scores 50000 and the one
  with more another 50000.
- **Big items.** 1E–28: when the round is cleared a 32 × 32 copy of the item falls to the floor in
  the middle (28 an ice lolly, 23 a cake, 1E a diamond). Touching it scores 10000 to 80000
  (`BIG_ITEM_POINTS`, by `F46D` = 28 − kind). It appears only from round 2.
- **Stars.** Kind 1A; 31 and 33 through `E724`. 8 stars fly about, 2500 an enemy.
- **Food rain.** Kind 1D; 2D and 35 change the picture by `F4CD`. Food falls from the top, 10000 an
  enemy.
- **Lightning.** Kind 13; 32 through `E724`. The screen flashes and a bolt strikes down and
  to the left, 5000 an enemy.
- **Water and fire bubbles.** Water (`WATER_CARRY` carries a player who is not pressing jump;
  `WATER_ENEMY_HITS`, `WATER_ROCK_HITS` sweep enemies and rocks away). Fire (`FIRE_PLAYER_CHECK`,
  `FIRE_ENEMY_HIT`). Seen on round 13 with `SPECIAL_LIST` held at 2 and at 3.
- **`ITEM_HINT`.** After kind 29 has been taken in a game, a round whose special item is an effect
  item starts with sound 28 and a flash.
- **`INVINCIBLE_ITEM`.** Kind 0E's own path (`F513` = FF): an item that, when touched, makes both
  players invincible for 900 frames. Enemies they touch are beaten for 1000 each (the sub CPU's
  `PLAYER_ENEMY_HITS`, through player byte +19, which `sub.s` calls +13 hex).
- **Potions.** Round 100's two potions set `POTION_P1`/`P2` and turn that player's bubbles into
  lightning bubbles (`POTION_BUBBLE`).
- **Others.** 04 freezes the enemies (`TIMER_RUN`). 06-08 skip 3, 5 or 7 rounds (`E350`). 34 skips to
  round 70 at top difficulty. 2A-2C choose the end-of-round item. 0F, 10 and 11 score for walking,
  each jump (500) and each bubble (100). 14 gives fire breath for 16 blows; `PLAYER_FIRE_RENEW` is
  the fireball bubble's 5 rounds of it (`FIREBALL_BUBBLE_POP`). 15, 16 and 18 combine boosts. 17 is
  `BOMB_RUN`. 30 is `HURRY_HAND_RUN`, a hand with a star that brings on HURRY UP. 1B is
  `TAKE_FREE_LETTERS`: `FREE_LETTERS` (`F676`) makes the bubbles from the gaps EXTEND letters, and
  the sub CPU's `POP_CHAIN_HIT` adds to it for chained pops. 12 is `TAKE_FLOOD`.

## The secret room

`BUBBLES_TASK` calls `SECRET_ROUND_START` (`5046`). Kinds 31-33 (`SECRET_ROUND_A`-`C`) set `E723` = 29,
and the next frame takes the player to the room, round record 65 (`SECRET_ROUND_INIT`/`FRAME`). `E724`
picks stars or lightning. `SECRET_ROOM_DRAW` puts up one of three pictures from bank 3 by `E724`, and
`SECRET_GEMS_INIT` sets up 0x24 gems, 10000 each. After 0x18 gems `SECRET_DROP_GAP` opens a gap that
drops a player from Y 58 to Y 18. After all of them `SECRET_EXIT_GAP` opens the way out, and a player
at Y 18, X 77-79 (`539F`) leaves by `SECRET_ROUND_EXIT` (`53CF`), which sends the game on to the round
after the one the player left. When the Skel-Monsta kills a player in the room the sub CPU sets
`SECRET_DEATH` (`E730`), and `SECRET_DEATH_SLEEP` (`4195`) sets its b7 after the lost life and puts the
task to sleep. `SECRET_EXIT_CHECK` (`5416`) then runs the exit.

## Endings

`ENDING_START` (`B34F`) jumps to `ENDING_SCROLL` (`563F`), which scrolls up one of bank 1's three texts
(`ENDING_TEXT_1P`, `_2P`, `_SUPER`, `8D42–95A9`). `trace.py --boss-pop` reaches them.

- **One player.** `ENDING_TEXT_1P` (TRY AGAIN !!) and `ZAP_ROUND`.
- **Two players.** The captives turn into the players' girlfriends, `CAPTIVE_PLAYER_WALK` walks each
  player to their captive (X 40 or B0), `CAPTIVE_HEART` is the small heart over each,
  `HEART_DRAW` puts a big heart between two HAPPY END!! (`HEART_CYCLE` turns it yellow, orange,
  pink), `ROUND_WIPE` clears the walls, the stars come in (`STARFIELD_DRAW_2P`), and `ENDING_TEXT_2P`
  scrolls up into the staff list. Then `ENDING_HINT_SCREEN`: 8 coded words and the hint, no miss in
  rounds 1-20, then the silver door.
- **Two players in super mode** (`--poke E5DB=1`). They free their parents, get `ENDING_TEXT_SUPER`
  (THE END !) and go straight to the high score table.

`STARFIELD_DRAW` and `STARFIELD_TWINKLE` are the intro's backdrop; the same stars twinkle under the
ending. `ENDING_HAND_WAIT` and `ENDING_HAND_RUN` are 600 frames of `HURRY_HAND_RUN`'s sweep in the
two-player ending; which sprites `BFF1` gives is not yet seen.

## Test mode

`TEST_MODE` (`8000` in bank 2). `TEST_INPUTS_SHOW` shows 14 input bits as ON/OFF, `TEST_DSW_SHOW`
both DIP switch banks as bits. `TEST_SOUND_SELECT` steps the sound number, up and down on the
joystick, played on P1 start.

## Code that never ran

With every trace merged, `--probe` takes 16 regions that MAME never ran: 7 in the fixed ROM, 8 in
bank 0, 1 in bank 2. Each reads as code, not data: unused siblings of named routines
(`OBJ_STATE_11`, `_14`, `_16`, `_18`-`_1B`, `HEX_BYTE`, `GRID_PROBE_ABOVE3`, marked "never run"),
enemy mode exits and turn steps in bank 0 (`8CC9`, `8D7D`, `9465`, `948C`, `94AD`, `94DB`, `97EC`,
`A7B9`), and a player record copy in bank 2 (`AFD8`). `VIDEO_RAM_TEST` (`bank2:8024`) was found from
its strings instead, and has no caller (`notes/text.md`).

## Read from the code, not seen in MAME

- A Skel-Monsta death in the secret room, and the room's exit.
- `BIG_ITEM_TAKE`: the cheat does not walk the player onto the big item.
- A potion being taken, and a lightning bubble popping.
- `P1_BURN`/`P2_BURN` with `PLAYER_BURN_STEP`: fire slows a player for 30 frames.
- `CAPTIVES_SIDE_TILES` and `_MID_TILES` draw two-player tiles not yet matched to the screen.
- The Players section, the EXTEND scene, `ROUND_ENTRY_INIT`, `KILL_ALL_SHAKE_INIT`, the rushes'
  scoring, `BLOW_REQUEST_TAKE` and the bubbles' crowd check, and the secret room's gems and gaps.
- The boss's one-hit shortcut (`notes/open_questions.md`).
