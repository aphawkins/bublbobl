# MCU shared RAM contract

The main Z80 sees this RAM at `FC00–FFFF`; the MCU reaches it over the board bus at
`0C00–0FFF` (`SHARED_READ` / `SHARED_WRITE`, `mcu:$F1BF` / `mcu:$F1DB`). Names are in
`notes/symbols.toml` `[shared.mcu]`. Everything here comes from the MCU code
(`src/mcu/mcu.s`). The main CPU's side is still to be traced (Phase 1 and Phase 5).

Direction: **M** = the MCU writes it, **Z** = the main CPU writes it (the MCU only reads).
"Every frame" means once per vblank, from `IRQ1`.

## Order of the jobs in a frame

`IRQ1` (`mcu:$F046`) runs these in order, then busy-waits about 2.6 ms unless
`NO_DELAY_KEY` = `'G'`:

| # | Job | Address | Does |
|---|---|---|---|
| 1 | `MAIN_IRQ` | `F1F8` | Raises the main CPU's IRQ (when `RUN_KEY` = `'G'`) |
| 2 | `READ_INPUTS` | `F236` | Publishes IN0, DSW0, DSW1, IN1, IN2 |
| 3 | `OCF` | `F092` | Coins and credits, coin lockout |
| 4 | `LOCKOUT_REQUEST` | `F1B0` | Lockout on request |
| 5 | `P1_LIVES_JOB` | `F2A7` | Player 1 lives command, tamper trap |
| 6 | `P2_LIVES_JOB` | `F347` | Player 2 lives command, tamper trap |
| 7 | `ROUND_JOB` | `F3E3` | Round command, tamper trap |
| 8 | `P1_PROX_JOB` | `F48F` | Player 1 proximity check |
| 9 | `P2_PROX_JOB` | `F585` | Player 2 proximity check |
| 10 | `SPEED01_JOB` | `F67F` | Speed channels 0 and 1 |
| 11 | `SPEED2_JOB` | `F6CB` | Speed channel 2 |
| 12 | `SPEED3_JOB` | `F6F1` | Speed channel 3 |
| 13 | `TIMER_JOB` | `F899` | 16-bit countdown |
| 14 | `CREDITS_42_JOB` | `F8D5` | Sets 42 credits on a key (see open questions) |
| 15 | `EXTEND_TICK` | `F8F1` | EXTEND letter |
| 16 | `FETCH0_JOB` | `F903` | Table fetch 0 |
| 17 | `FETCH1_JOB` | `F93D` | Table fetch 1 |
| 18 | `FETCH2_JOB` | `F977` | Table fetch 2 |
| 19 | `RESET_REQUEST` | `F299` | MCU restart on request |

The main CPU's interrupt is raised first, so the main CPU's handler runs while the MCU
works through the rest of the list. Which values a main-CPU frame sees (this frame's or
the last) depends on that timing. It must be measured in Phase 1 (PLAN.md §3.3).

## The map

| Main | Name | Dir | Meaning |
|---|---|---|---|
| `FC00` | `IRQ_VECTOR` | — | IM 2 vector byte. The MCU code never touches it, so the main CPU must set it |
| `FC01` | `MCU_OBJECTS` | Z | 7 × 4 bytes: flags (b0 = active), X, Y, unused |
| `FC1E` | `CREDITS` | M/Z | Credits. Coins and service add (max 9 from service); the main CPU subtracts |
| `FC1F` | `IN0_COPY` | M | Port 1: b0 tilt, b1 service, b2 coin 1, b3 coin 2, b4–7 the MCU's outputs |
| `FC20` | `DSW0_COPY` | M | DIP switch A |
| `FC21` | `DSW1_COPY` | M | DIP switch B |
| `FC22` | `IN1_COPY` | M | Player 1 controls |
| `FC23` | `IN2_COPY` | M | Player 2 controls |
| `FC24` | `P1_LIVES` | M | Player 1 spare lives, changed only through `P1_LIVES_CMD` |
| `FC25` | `P2_LIVES` | M | Player 2 spare lives, through `P2_LIVES_CMD` |
| `FC26` | `ROUND` | M | Round counter from 0, through `ROUND_CMD` |
| `FC27` | `MCU_PROXIMITY` | M | 7 × 8 bytes, one record per object (below) |
| `FC5F` | `P1_PROX_ON` | Z | b0 = run the player 1 check |
| `FC60` | `P1_PROX_X` | Z | Player 1 X |
| `FC61` | `P1_PROX_Y` | Z | Player 1 Y |
| `FC62` | `P1_PROX_HIT` | M | 1 = hit (the MCU never clears it) |
| `FC63` | `P1_PROX_INDEX` | M | Object number 0–6 at the hit |
| `FC67`–`FC6B` | `P2_PROX_*` | | As `FC5F`–`FC63`, player 2 |
| `FC6F` | `P1_LIVES_CMD` | Z | 1 = set from DSW1, 2 = +1 (not above 10), 4 = −1, 8 = set 10. The MCU clears it |
| `FC70` | `P2_LIVES_CMD` | Z | As `P1_LIVES_CMD` |
| `FC71` | `CREDITS_42_KEY` | Z | `0x0D` while the round copy is 12 sets `CREDITS` = 42 |
| `FC72` / `FC73` | `SPEED0_SEL` / `_STEP` | Z / M | Speed channel 0: select 0–40, step this frame |
| `FC74` / `FC75` | `SPEED1_SEL` / `_STEP` | Z / M | Channel 1 |
| `FC76` / `FC77` | `SPEED2_SEL` / `_STEP` | Z / M | Channel 2 |
| `FC78` / `FC79` | `TIMER_LO` / `_HI` | Z/M | 16-bit countdown, −1 every frame while running |
| `FC7A` | `TIMER_RUN` | Z/M | Nonzero = run. The MCU clears it at zero |
| `FC7B` | `TIMER_DONE` | M | Set to 1 at zero (the MCU never clears it) |
| `FC7C` | `EXTEND_LETTER` | M | 0–5, +1 every frame |
| `FC7D` | `COIN_STUCK` | M | 1 = a coin input was active at power-on |
| `FC7E` | `ROUND_CMD` | Z | 1 = 0, 2 = +1, 4 = 49, 8 = 98, 10 = 99, 20 = 100, 40 = 101 (decimal). The MCU clears it |
| `FC7F` | `ALIVE_COUNTER` | Z | Read only by `MCU_WATCHDOG`, which is never called |
| `FC80` / `FC81` | `SPEED3_SEL` / `_STEP` | Z / M | Channel 3 |
| `FC82` / `FC83` | `ROM_SUM_HI` / `_LO` | M | Word sum of the MCU ROM, at start-up. `0000` when intact |
| `FC85` | `MCU_READY` | M | `0x37` when the MCU's start-up is done |
| `FC88` | `FETCH0_DEST` | M | 256 bytes; fetch 0 writes one byte at `FETCH0_OFFSET` |
| `FD88` | `FETCH1_DEST` | M | Fetch 1 |
| `FE88` | `FETCH2_DEST` | M | Fetch 2 |
| `FF88` | `FETCH0_REQ` | Z/M | 1 = fetch a byte. The MCU sets `0xFF` when done |
| `FF89` | `FETCH0_INDEX` | Z | Byte in the block |
| `FF8A` | `FETCH0_BLOCK` | Z | Block 0–4 of `FETCH_BLOCKS` (`mcu:$F9B1`) |
| `FF8B` | `FETCH0_OFFSET` | Z | Where in `FETCH0_DEST` |
| `FF8C`–`FF8F` | `FETCH1_*` | | As `FF88`–`FF8B`, into `FETCH1_DEST` |
| `FF90`–`FF93` | `FETCH2_*` | | As `FF88`–`FF8B`, into `FETCH2_DEST` |
| `FF94` | `LOCKOUT_REQ` | Z | 1 = lock the coin slots, `0xFF` = unlock |
| `FF95` | `TRAP_KEY` | Z | `'B'` arms the tamper traps on lives and round |
| `FF96` | `NO_DELAY_KEY` | Z | `'G'` skips the busy wait at the end of `IRQ1` |
| `FF97` | `MCU_RESET_KEY` | Z | `'J'` restarts the MCU |
| `FF98` | `RUN_KEY` | Z | `'G'` turns on coin handling and the main CPU's IRQ |
| `FF99` | `COIN_EVENT` | M | Set to 1 when credits are added (the MCU never clears it) |

### Proximity records (`FC27 + 8 × object`)

| Byte | Player | Meaning |
|---|---|---|
| +0 / +1 | 1 / 2 | X side: `0x80` equal, `0` player ≥ object, `1` player < object |
| +2 / +3 | 1 / 2 | Y side, the same way |
| +4 / +5 | 1 / 2 | \|dX\| |
| +6 / +7 | 1 / 2 | \|dY\| |

Only active objects are updated. The scan stops at the first object with |dY| < 8. It
reports a hit if any object scanned so far had |dX| < 8. That need not be the same
object (`mcu:$F563`).

### Speed patterns

`SPEED_PATTERNS` (`mcu:$F717`) holds 41 lists. List *n* gives a step of 0–4 pixels per
frame that averages *n*/10. For example, list 1 is one `1` in ten frames, list 15 is
`1 2` alternating, and list 40 is all `4`. A channel keeps its position when its
select changes. It wraps when it reaches the `0xFF` at the end of a list.

## Things the main CPU must do

- Write `'G'` to `RUN_KEY`, or it gets no IRQ and coins are ignored.
- Set `IRQ_VECTOR`.
- Change lives and the round only through the command bytes when `TRAP_KEY` = `'B'`.
  Otherwise the MCU crashes, and coins and the IRQ stop.
