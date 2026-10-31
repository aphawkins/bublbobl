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

### Modulation (`OPL_MOD_TICK`, `OPN_MOD_TICK`)

After its step, each FM record runs its modulation every tick: one LFO and one stepped
envelope. Each moves up to 3 targets on the YM3526 and up to 8 on the YM2203, picked by a
mask. A keyed note first puts the total levels back to the voice's values.

| Mask bit | YM3526 | YM2203 |
|---|---|---|
| b0, b1 | operator 1, 2 total level | operator 1, 2 total level |
| b2 | the pitch | operator 3 total level |
| b3 | none | operator 4 total level |
| b4–6 | none | operator 1–3 pitch (channel 3 only) |
| b7 | none | the channel's pitch |

Record fields. YM2203 offsets are in brackets.

| Field | Meaning |
|---|---|
| +41 [+82] | LFO: b7 on, b6 restart on each keyed note |
| +42/+43, +44/+45 [+83–+86] | the phase step (DC), and the step in use |
| +46/+47 [+87/+88] | the phase |
| +48 [+89] | the shape, 0–7 |
| +49 [+90] | the LFO's mask (DD) |
| +50 [+91] | the LFO's value, −7F to 7F |
| +51–+53 [+92–+99] | a depth for each mask bit |
| +54 [+100] | envelope: b7 on, b6 restart on each keyed note, b5 add mode, b0 skip the first tick |
| +55, +56 [+101, +102] | the interval, and the count to the next step |
| +57 [+103] | added to the interval at each step |
| +58/+59, +60 [+104–+106] | the points, and the next one |
| +61, +62 [+107, +108] | loops left (0 = for ever), then the entry to chain to (b7: stop) |
| +63, +64 [+109, +110] | the entry and first interval, for a restart |
| +65 [+111] | the envelope's mask (DF) |
| +66 [+112] | the slope: this point to the next |
| +67, +68 [+113, +114] | envelope depth on the LFO rate (EC); nothing sets +67 b7, so it does nothing |
| +69–+78 [+115–+142] | for each mask bit, a depth and its sum (16 bits; 24 for a pitch) |

**The LFO.** The phase is a 16-bit count, and the phase step is added to it each tick. The
shape turns the phase into a value from −7F to 7F (`OPL_LFO_SHAPES`):

| Shape | Value over one cycle |
|---|---|
| 0 | triangle: 0 up to 7F, down to −7F, back to 0 |
| 1 | the same, falling first |
| 2 | sawtooth up |
| 3 | sawtooth down |
| 4 | square: 7F, then −7F |
| 5 | the same, low first |
| 6 | 0 up to 7F, then 0 down to −7F |
| 7 | 0 down to −7F, then 0 up to 7F |

A target gets LFO value × depth / 256 (signed).

**The stepped envelope.** An entry in the table at `3A71` (YM3526) or `3A79` (YM2203) is 5
bytes: the interval change, the loop count, the next entry, and a pointer to its points.
The points are bytes, and 00 ends them. Each step, the slope is the next point minus this
point, and each target's sum gains slope × depth (signed). A target gets the sum's high
byte, so it moves by (point − first point) × depth / 256. Steps come when a countdown from
the interval runs out. In add mode (DE's b7), the interval is added to a count instead, and a
step comes at each carry. The interval changes by the entry's first byte at each step. At
the end of the points the envelope starts again from the first point. When the loop count
runs out, it chains to the next entry, or stops.

**What is written.** A total level is the voice's level + LFO + envelope, and the register
is flagged only when it changes. On the YM3526 the pitch adds the F-number, the envelope
sum and the LFO. With the LFO on, only the F-number's low byte moves (register A0). At the
edge of the block and high bits it holds at 00 or FF. On the YM2203 the block is written
too. Without the LFO, the F-number is kept in 337–66C by moving the block an octave, and the
pitch is flagged for a write on every tick.

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

- The SSG's modulation (`265A`): 7 stepped envelopes, from the table at `3B60`, on the three
  tone periods and four more targets.
- The SSG `7x` event, and F0, F7 and FF.
- The command catalogue (`notes/sound_commands.md` lists the commands the main CPU sends):
  which block each command starts, checked against MAME recordings.
- A decoder that writes each command's phrases as JSON (`build/sound/`).
