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

**The stepped envelope.** An entry in `OPL_ENVS` (one entry) or `OPN_ENVS` (20) is 5
bytes: the interval change, the loop count, the next entry, and a pointer to its points.
The points are bytes, and 00 ends them. Each step, the slope is the next point minus this
point, and each target's sum gains slope × depth (signed). A target gets the sum's high
byte, so it moves by (point − first point) × depth / 256. Steps come when a countdown from
the interval runs out. In add mode (DE's b7), the interval is added to a count instead, and a
step comes at each carry. The interval changes by the entry's first byte at each step. At
the end of the points the envelope starts again from the first point, but the sums are not
reset: each pass moves the targets by (last point − first point) × depth more, so a
two-point entry is a ramp for as long as it runs. When the loop count runs out, it chains
to the next entry, or stops. Every entry but one in `SSG_TONE_ENVS` loops for ever.

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
| 7x | the hardware envelope's period: the low nibble × 10 (register B), the next byte (register C); it restarts the envelope |
| 8x, 9x, Ax | volume of channel A, B or C (and that channel leaves the hardware envelope) |
| Bx–Ex | none (no argument) |
| Fx | `SSG_F_JUMPS` by the low nibble, below |

A byte below 40 is the next duration. F0 lets a duration of 40 and up follow.

| Byte | Action |
|---|---|
| F0 | (no argument) ends the step: the byte after is the next duration |
| F1 | noise period (register 6) |
| F2 | stepped envelope on the noise period (`SSG_VOL_ENVS`), held in 0–1F |
| F3 | the hardware envelope: b0–2 its shape (register D), b3–5 channels A–C play on it (volume 10), b6–7 the channel whose new tone restarts it (0 none, 1–3 A–C) |
| F4, F5, F6 | stepped envelope on channel A, B or C's tone period (`SSG_TONE_ENVS`) |
| F7 | the mixer (register 7), b0–5 |
| F8, F9, FA | stepped envelope on channel A, B or C's volume (`SSG_VOL_ENVS`), held in 0–F |
| FB–FE | none |
| FF | stops the envelope that F0 + the argument started |

### SSG modulation (`SSG_MOD_TICK`)

The SSG has no LFO. Its record has 7 envelope slots of 11 bytes, one for each target: the
tone periods (+34, +45, +56), the noise period (+67) and the volumes (+78, +89, +100). They
step as the FM envelope does, with three differences:

- A step adds the point difference straight to the register value, with no depth.
- Volume and noise points are 4 bits, two to a byte (high nibble first), and 0 ends them.
  The value is held in 0–F (0–1F for the noise).
- A new value from the step's events (a new tone, say) restarts the envelope, as a keyed
  note does on the FM channels. A volume envelope stops on its first tick if its channel
  plays on the hardware envelope.

Each tick also restarts the hardware envelope (register D) when F3's channel got a new tone.
The record's register copies: +20–+25 tones A–C, +26 noise, +27 mixer, +28–+30 volumes,
+31/+32 envelope period, +33 envelope shape. +17 and +18 flag the registers to write at the
next tick (`SSG_TONE_WRITE`, `SSG_HWENV_WRITE`).

## Event lengths

An event is its byte and its arguments. `tools/sounddec.py` uses these lengths (from the
handlers) to find where a phrase ends.

FM (YM3526 and YM2203), the length including the event byte:

| Event | Length |
|---|---|
| a note (low nibble 0–B) | 1 |
| 8F (and 8C–8E on the YM2203) | 2, or 3 if the note byte after has b7 set (an F-number offset follows) |
| 9C–9F, AC–AF, CE, CF, EC, ED, FC, FD–FF; YM3526 BC–BF | 2 |
| YM2203 BC–BF | 6 |
| CC | 2; 3 on the YM3526 for B0–B6, on the YM2203 for A2–B6 |
| CD | 3 on the YM3526, 5 on the YM2203 |
| DC | 4 |
| DD | 2 + the number of bits set in the mask |
| DE | 3 |
| DF | 2 + the bits set in b0–2 (YM3526); 2 + the bits set in b0–3 and b7, and b4–6 too on channel 3 (YM2203) |
| EE, EF | 1 |

A phrase's steps end at a duration of 00. A second note (or EE or EF) in a step ends it: the
player starts another step there, with the length set by CE as its duration.

SSG: 4x–7x are 2 bytes, 8x–Ex are 1. F0 is 1 byte and ends the step (the next duration
follows it, and can be 40 or more). F1, F3, F7, FB–FF are 2, F2, F4–F6 and F8–FA are 3.

## Voices

`CF` picks a voice from `OPL_VOICES` or `OPN_VOICES` (a word pointer each). `tools/soundtables.py`
decodes them into `build/sound/tables.json`. A voice is its chip's settings, then the setup of the
LFO and the envelope.

YM3526: byte 0 feedback (b4-6) and connection (b0); byte 1 the AM depth (b4) and vibrato depth (b0)
of register BD; then 4 bytes for each of the 2 operators: an attenuation (TL is the low 6 bits
inverted, b6-7 the KSL) and the registers 20, 60 and 80.

YM2203: byte 0 an LFO sensitivity the chip does not have, byte 1 the algorithm (b0-2) and feedback
(b4-6, written to B0), then 4 slots (registers +0, +4, +8, +C) of 7 bytes: TL (40), 30, 90, 50, 60,
70, 80. Checked against the writes MAME made for command 25.

Both end with variable setup that `CF` hands on: a mask byte for the LFO (0: no LFO; else 3 bytes of
`DC` follow, then a depth for each bit of the mask, as `DD`), a mask for the envelope (nonzero: 2
bytes of `DE`, then the depths `DF` reads) and the envelope's depth on the LFO rate (`EC`). The
voices are packed with no gaps, so a voice's length is what this parse reads.

## Not yet done

- The command catalogue is in `notes/sound_blocks.md` (made by `tools/sounddec.py`, JSON in
  `build/sound/commands.json`). It is not yet checked against MAME recordings.
- Check more commands against MAME (`tools/soundcmp.py`, `tools/soundcheck.py`): only command 08
  (YM3526) and 25 (YM2203) have been compared. The YM2203 and SSG phrases still need a checker.
