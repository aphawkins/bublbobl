# One frame's order

The order in which the main CPU, the sub CPU and the MCU reach shared RAM in a frame, for
`PLAN.md` §3.3. The sound CPU shares no RAM with them and is left out.

The short answer: **the three CPUs overlap, so no order is exact, but MCU, then sub, then main is the
closest whole-frame order.** How far the sub CPU overlaps the main CPU depends on how much is on
screen.

Everything here was measured in MAME 0.289, not on a board. See [Limits](#limits).

## Method

`tools/frameorder.py` logs every access to shared RAM on the three CPUs, with the byte, the
instruction and that CPU's own local time, plus the entry to each routine in its `MARKS` list. MAME
runs the CPUs in turn, in slices of up to 1/6000 s (167 µs), so the log is sorted by time afterwards.
Two runs of a capture give identical logs.

| Capture | Command | Frames | Scene |
|---|---|---|---|
| `r1` | `--name r1 --frames 900 --from 20` | 900 | Round 1, one player, random play, many bubbles |
| `r30` | `--name r30 --round 30 --seed 3 --frames 900 --from 20` | 900 | Round 30, one player; 111 of the frames are not play |
| `p2r45` | `--name p2r45 --scenario game2p --round 45 --seed 2 --frames 900 --from 20` | 900 | Round 45, two players; 111 of the frames are not play |
| `attract` | `--name attract --scenario attract --frames 600 --from 60` | 600 | Attract mode |

Each writes `build/frameorder/<name>/report.txt`, which holds every figure below.

## Timeline

A frame is 16.896 ms (59.19 Hz). Times are from 20 µs before the MCU's first instruction, so that the
sub CPU's interrupt falls inside the frame.

| Time | Main CPU | Sub CPU | MCU |
|---|---|---|---|
| 0.01 ms | | `IRQ`, `VBLANK`; `GHOST_HITS`, `PLAYER_ENEMY_HITS` and the marks | `IRQ1`, `MAIN_IRQ` |
| 0.11 ms | | | Raises the main CPU's IRQ |
| 0.12 ms | | | `READ_INPUTS` |
| 0.11–0.28 ms | `IRQ_HANDLER` (see Limits) | | |
| 0.13–0.29 ms | `OBJ_COPY`, about 1.3 ms | `BUBBLE_HITS` starts, 0.1–0.7 ms | |
| 0.6–1.6 ms | | | `OCF`, lockout, lives and round jobs |
| 1.5 ms | `FRAME_TICK` | | |
| 1.6 ms | `SCHEDULER` starts | | `P1_PROX_JOB` |
| 1.7 ms | `ROUND_TASK` | | |
| 1.8–3.0 ms | `OBJECTS_TASK` | | `P2_PROX_JOB`, from 1.6 to 5.9 ms |
| 2.6–5.3 ms | `ROUND_ENEMIES` | | Speed, timer, EXTEND and fetch jobs, ending by 12 ms |
| 2.7–11.4 ms | `BUBBLES_TASK` | | |
| 5.8–14.5 ms | | | `RTI`, after the delay loop |
| 6–16.5 ms in `r1`, 0.04–13.6 ms in `p2r45` | | `VBLANK_END`, then idle | |
| 9–14 ms in `r1` | Idle, until the next IRQ | | |

- `OBJ_COPY` runs on through `SOUND_QUEUE_POP` and `RAND_INC` into `FRAME_TICK`, so `FRAME_TICK` runs
  every frame, not only on the busy path.
- The scheduler ran the tasks in slot order, 2 3 4 5, in nearly every frame of play. Slots 4 and 5
  did not run in 111 frames of `r30` and `p2r45`, which also had the sub CPU's checks off. Attract
  mode runs slots 0, 1 and 2.
- The sub CPU's frame lasts longest with many bubbles: `BUBBLE_HITS` takes 12.7 ms at the median in
  `r1` and up to 15.4 ms. It never overran. Its latest end in any capture is 16.46 ms.
- The main CPU overran rarely. `IRQ_BUSY_PATH` ran in 0 frames of `r1`, 1 of `r30`, 1 of `p2r45` and 5
  of `attract`. The long task is `ROUND_ENEMIES` in `r30` and `p2r45`, at up to 17.1 ms, and
  `ATTRACT_TASK` in `attract`, at up to 42.4 ms.

## What each CPU reads from the others

**MCU to main.** The main CPU reads inputs (`COPY_INPUTS`, `COIN_SCAN`, `TILT_RESET`) and proximity
results (`ENEMY_PROX_A`, `ENEMY_WALK_L`, `ENEMY_WALK_R`, the `_SEEK` routines) after the MCU has
written them. No read in any capture came before a later change by the MCU in the same frame.

**Main to MCU.** The proximity jobs read `MCU_OBJECTS` while `ENEMIES_FRAME` rewrites it. Most reads
get last frame's position. `P1_PROX_JOB`, which runs first, got this frame's in 0 of 8,737 reads in
`r1`, 661 of 11,399 in `r30` and 332 of 10,432 in `p2r45`. `P2_PROX_JOB`, which runs later, got it
in 1,603 of 10,642 in `p2r45`. Which enemies get which depends on how long the job before took.

**Main to sub.** The sub CPU's reads before the scheduler starts, at about 1.6 ms, are last frame's,
because no task has run. After that it depends on how long the sub CPU has been running:

| Sub CPU ends by | `r1`: frames with new data | `r1`: new reads a frame | `p2r45`: frames with new data | `p2r45`: new reads a frame |
|---|---|---|---|---|
| 4 ms | | | 0 of 398 | 0 |
| 6 ms | | | 107 of 230 | 1.0 |
| 8 ms | 53 of 163 | 1.1 | 132 of 161 | 4.2 |
| 10 ms | 87 of 101 | 4.5 | 40 of 50 | 5.9 |
| 12 ms | 94 of 95 | 5.0 | 54 of 54 | 11.8 |
| 14 ms | 172 of 172 | 22.8 | 7 of 7 | 19.0 |
| 16 ms | 347 of 347 | 38.0 | | |
| 18 ms | 21 of 22 | 48.3 | | |

A frame of play makes about 450 to 1,500 such reads. The new data is nearly all positions:
`OBJ_POS_LOAD` wrote 18,796 of the new reads in `r1`, and the next writer 118. Most are bubble +1 and
+2, read by `PUSH_UP`, `PUSH_RIGHT` and `PUSH_LEFT`. So when bubbles are pushed apart late in the sub
CPU's frame, some are compared at this frame's position and some at last frame's.

**Sub to main.** `BUBBLE_RISE` is the reader most affected: in `r1`, 652 of its 12,712 reads got a
different byte from the one a sub-first order would give. That fits the sub CPU not having reached
that bubble yet, but it was not checked bubble by bubble.

`CREDITS` (`FC1E`) is the only MCU byte both CPUs wrote in these captures. Others can be, such as
`FETCH0_REQ`, but these runs did not use them. The sub CPU and the MCU share no RAM.

## Which order fits

If two CPUs ran one after the other, a whole frame each, each read would get a known byte. The table
counts the reads where that byte differs from the one really read. It leaves out `MAIN_FRAME` and
`SUB_FRAMES`, which only prove that the other CPU is alive, and reads of bytes not yet written in the
capture. `attract` has no wrong reads in either order.

| Reads | Order | `r1` | `r30` | `p2r45` |
|---|---|---|---|---|
| Main's, of MCU data | **MCU first** | **0** of 10,757 | **0** of 8,227 | **0** of 8,370 |
| | Main first | 290 | 165 | 339 |
| MCU's, of main data | **MCU first** | **0** of 11,985 | **743** of 16,914 | **2,377** of 28,703 |
| | Main first | 2,295 | 3,164 | 2,723 |
| Sub's, of main data | **Sub first** | **20,123** of 631,631 | **714** of 544,477 | **2,065** of 427,154 |
| | Main first | 65,708 | 21,057 | 29,623 |
| Main's, of sub data | **Sub first** | **655** of 27,981 | **4** of 16,165 | **88** of 21,754 |
| | Main first | 7,405 | 3,012 | 3,579 |

So in every capture and for every pair, the MCU goes before the main CPU and the sub CPU goes before
the main CPU. The sub CPU and the MCU do not touch, so their order does not matter.

This gives one frame as:

1. MCU: all its jobs, against last frame's `MCU_OBJECTS`.
2. Sub CPU: all its hit tests, against last frame's positions.
3. Main CPU: `OBJ_COPY`, `FRAME_TICK`, then the tasks in slot order.

What that order cannot reproduce is the overlap: at worst 3.2% of the sub CPU's reads, 8.3% of the
MCU's and 2.3% of the main CPU's reads of sub data. A wrong read here is only a different byte. Many will not change what the game does, for example when a distance stays out of range. How
many do was not measured.

## Limits

- **MAME, not a board.** Nothing here was measured on hardware. MAME gives shared RAM no wait states,
  and a real board may arbitrate between the two Z80s, which would change how far they overlap.
- **The main CPU's start is late in MAME.** The MCU raises the IRQ at 0.106 ms, and the main CPU takes
  it at the next slice, at 0.11 to 0.28 ms. So all its times may be up to 0.17 ms later than a
  board's. This does not change which CPU comes first in the table above, but it does move the
  closest races.
- **Slices.** 641 of 682,354 reads in `r1`, 107 of 585,783 in `r30`, 134 of 485,981 in `p2r45` and
  none in `attract` got a byte that is not the last write by time. All of them are explained by a
  write within one slice, which MAME ran the other way round. Two accesses closer than 167 µs have
  no reliable order.
- **Four scenes.** The frames are random play on three rounds, and attract mode. Boss rounds, the
  specials and the endings were not captured.
