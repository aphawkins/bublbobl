# Sound CPU

The sound Z80 (`a78-07.46`, 3 MHz) plays the commands the main CPU writes to `FA00`. It
drives a YM2203 (3 FM channels and the 3-channel SSG) and a YM3526 (9 FM channels).

The source is `src/sound/sound.s`, made by `tools/redo_sound.sh` from `tools/dasmz80.py` and
the names in `notes/symbols.toml`. It assembles byte-exact. `0x26D8` bytes are instructions.
The rest is data kept as `.incbin`, and one unreached 4-byte tail at `1AD0`.

## Commands

The NMI puts each command in `CMD_QUEUE`, and `MAIN_LOOP` plays them (`QUEUE_RUN`):

| Command | Action |
|---|---|
| 00–34 | `COMMAND_TABLE` entry |
| 35–DF | ignored |
| EE, EF | sound off, sound on (`SOUND_ON`) |
| F0 | echo mode on/off |
| F2, F4, F6, F8 | `COMMAND_F_TABLE` entry |

A `COMMAND_TABLE` entry is one block, or a count byte and that many words. A word with
high byte 0 queues its low byte as another command; any other word is a block.

## Blocks and records

A block starts a **record**, one of 26 that play at once:

| Ids | Record | Chip |
|---|---|---|
| 84, 86 | `SSG_REC_A`, `SSG_REC_B` | YM2203 SSG |
| 8C–96 | `OPN_RECS`, 2 for each channel | YM2203 FM channels 1–3 |
| 98–BA | `OPL_RECS`, 2 for each channel | YM3526 channels 1–9 |

Each channel has an A record and a B record. The B record is silent while the A record plays,
and when the A record ends, the B record rewrites the channel's voice and goes on.

Block layout:

| Offset | Meaning |
|---|---|
| +0 | record id; b0 set: reply the command number when the record ends (`SEQ_END_NOTIFY`) |
| +1 | b4–7 priority, b0–3 passes (0 = 16) |
| +2 | phrase count |
| +3 | command queued when the record ends (FF: none) |
| +4 | phrases, 3 bytes each: b4–7 priority and b0–3 repeats (0 = for ever), then a word pointer to the phrase's events |

On a record that is playing, `BLOCK_START` starts the new block only when the block's
priority (+1 b4–7) is not above the playing phrase's priority (record +5). Ids F0 and F1 are not records: `BLOCK_NOW` applies the events after the
next byte to the record that byte names, at once.

A record plays each phrase for its repeats, then the next phrase. After the last phrase it
starts the next pass. After the last pass it stops (`OPL_PHRASE_END`).

## Steps and events

The YM2203's timers drive the players. Timer A runs `OPL_TICK_A` and `_B`, and timer B runs
`OPN_FM_TICK` and `OPN_SSG_TICK`. In each tick, each record counts down its duration. At 0,
`OPL_STEP` (or `OPN_STEP`, `SSG_STEP`) reads one step:

```
duration  event  event ...      next duration ...
```

The duration is one byte with b7 clear, and 00 ends the phrase. The events after it all have
b7 set, and the first byte with b7 clear is the next duration. The gate is
duration × gate / 256, and when it runs out the note keys off.

### FM events (`OPL_EVENTS`, `OPN_EVENTS`)

A byte whose low nibble is 0–B is a note: the low nibble picks the semitone from `OPL_NOTES`
or `OPN_NOTES`, and b4–6 give the octave (the block). A byte with a low nibble of C–F is a
command. Its handler is in `OPL_EVENT_JUMPS` or `OPN_EVENT_JUMPS`, at (b4–6) × 4 + (low
nibble − C), and it takes the next byte as its argument.

| Byte | YM3526 | YM2203 |
|---|---|---|
| 8C–8E | none | a note for operator 1, 2 or 3 alone (channel 3's special mode) |
| 8F | a note, with a signed F-number offset after it if its b7 is set | the same |
| 9C–9F | MULT op 1 / op 2, AM-VIB-EG op 1 / op 2 | detune and MULT, ops 1–4 |
| AC–AF | TL op 1 / op 2, KSR and KSL op 1 / op 2 | TL, ops 1–4 |
| BC–BF | attack and decay op 1 / op 2, sustain and release op 1 / op 2 | registers 90, 50, 60, 70, 80 for ops 1–4 (5 bytes; 90 is always written as 0) |
| CC | below 80: feedback and connection; 80 and up: `OPL_CC_JUMPS` (below) | below 80: feedback and algorithm; A0/A1, B0–B6 as YM3526 |
| CD | both TLs (2 bytes) | all 4 TLs (4 bytes) |
| CE | length of a second note in one step | the same |
| CF | voice from `OPL_VOICES` (13 bytes) | voice from `OPN_VOICES` (33 bytes) |
| DC, DD | LFO: rate, depth, shape (`OPL_LFO_SHAPES`); its settings (0 = off) | the same |
| DE, DF | stepped envelope from the table at `3A71`; its settings (0 = off) | the same, table `3A79` |
| EC | envelope depth | the same |
| ED | gate | the same |
| EE | key off (no argument) | the same |
| EF | key on again (no argument) | the same |
| FC | volume: scales the carrier's TL | the same |
| FD–FF | none | none |

`CC` with an argument of 80 and up, on the YM3526:

| Argument | Action |
|---|---|
| 80–9F | rhythm key bits (register BD b0–4) |
| A0 / A1 | each note keys on (the default) / notes only change the pitch |
| B0–B3 | YM2203 timer A, from b0–1 and the next byte; B4–B6 one more byte each |
| C0 / C1 | rhythm mode on / off |
| D0–DF | AM and vibrato depth (BD b6–7) |
| E0 / E1 | NOTE-SEL (register 08 b6) on / off |

A handler returns D and E: D is the bits to set in the record's dirty byte +15 + E. After
the step, `OPL_DIRTY_WRITE` writes only the flagged registers. A new voice (+15 b7) makes
`OPL_VOICE_WRITE` write all of them.

### SSG events (`SSG_EVENTS`)

These are picked by the high nibble, through `SSG_EVENT_JUMPS`:

| Byte | Action |
|---|---|
| 4x, 5x, 6x | tone period of channel A, B or C: coarse from the low nibble, fine from the next byte |
| 7x | low nibble and the next byte into +31, +32 (not yet read) |
| 8x, 9x, Ax | volume of channel A, B or C |
| Bx–Ex | none (no argument) |
| Fx | `SSG_F_JUMPS` by the low nibble: F1 noise period, F3 mixer, F2 and F4–FA stepped envelopes (`SSG_ENV_START`, tables `3B3D` and `3B60`) |

## Not yet done

- What `OPL_MOD_TICK` and its YM2203 and SSG twins do with the LFO and envelope values, and
  which registers they change. This includes `10AF` and the fields +41–+77.
- The SSG `7x` event, and F0, F7 and FF.
- The command catalogue (`notes/sound_commands.md` lists the commands the main CPU sends):
  which block each command starts, checked against MAME recordings.
- A decoder that writes each command's phrases as JSON (`build/sound/`).
