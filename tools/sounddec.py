"""Decode the sound CPU's command catalogue: which blocks each command starts.

Usage: python tools/sounddec.py

Reads build/images/sound.bin (see notes/sound.md for the formats) and writes
build/sound/commands.json and notes/sound_blocks.md. A command is an entry in
COMMAND_TABLE (00-34) or COMMAND_F_TABLE (F2, F4, F6, F8): one block, or a count of
words, each a block or (high byte 0) another command to queue. A block is a record
id, priority and passes, a phrase count, a next command and 3-byte phrases
(priority and repeats, a pointer to the phrase's events).

Each phrase is decoded into steps (a duration and its events). The argument lengths
come from reading the handlers in src/sound/sound.s: see decode_fm and decode_ssg.
"""

import json
import sys

import romset

ROOT = romset.ROOT
IMAGE = ROOT / "build" / "images" / "sound.bin"
OUT_JSON = ROOT / "build" / "sound" / "commands.json"
OUT_MD = ROOT / "notes" / "sound_blocks.md"

COMMAND_TABLE = 0x329C
COMMAND_COUNT = 0x35
COMMAND_F_TABLE = 0x3306
BLOCK_MIN = 0x1B  # a first byte below this is a word count, not a record id


def record_name(rid: int) -> str:
    rid &= 0xFE
    if rid in (0x84, 0x86):
        return f"SSG {'AB'[(rid - 0x84) // 2]}"
    if 0x8C <= rid <= 0x96:
        return f"OPN ch{(rid - 0x8C) // 4 + 1} {'AB'[(rid - 0x8C) // 2 % 2]}"
    if 0x98 <= rid <= 0xBA:
        return f"OPL ch{(rid - 0x98) // 4 + 1} {'AB'[(rid - 0x98) // 2 % 2]}"
    if rid in (0xF0, 0xF1):
        return "now"
    return f"?{rid:02X}"


def popcount(v: int) -> int:
    return bin(v).count("1")


def note_args(d: bytes, i: int) -> int:
    """Bytes after the event byte of a note that is given in a byte of its own.

    The note byte is the argument; with its b7 set (the usual case) an offset byte
    follows (OPL_NOTE_FNUM, OPN_NOTE_FNUM).
    """
    return 2 if d[i + 1] & 0x80 else 1


def fm_event_length(d: bytes, i: int, chip: str, channel: int) -> int:
    """Length in bytes of the FM event that starts at d[i] (b7 set).

    Notes with a low nibble below C are one byte. Otherwise the handler is picked by
    the high nibble (OPL_EVENT_JUMPS / OPN_EVENT_JUMPS) and takes the byte after.
    """
    b = d[i]
    lo, hi = b & 15, (b >> 4) & 7
    if lo < 0xC:
        return 1
    idx = hi * 4 + lo - 0xC
    arg = d[i + 1]
    if idx == 3 or (chip == "opn" and idx < 3):  # 8C-8F: a note in the next byte
        return 1 + note_args(d, i)
    if idx == 16:  # CC
        if chip == "opl":
            if arg & 0x80 and 0xB0 <= arg <= 0xB6:
                return 3
            return 2
        if not arg & 0x80 or arg & 0x40:
            return 2
        if arg & 0x20:
            if arg in (0xA0, 0xA1) or arg >= 0xB7:
                return 2
            return 3  # A2-B6: a timer byte follows
        return 2
    if idx == 17:  # CD: all total levels
        return 5 if chip == "opn" else 3
    if idx == 20:  # DC: LFO
        return 4
    if idx == 21:  # DD: one byte for each bit of the mask
        return 2 + popcount(arg)
    if idx == 22:  # DE: envelope entry, interval
        return 3
    if idx == 23:  # DF: one byte for each bit of the mask that has a depth
        if chip == "opl":
            return 2 + popcount(arg & 7)
        n = popcount(arg & 0x0F) + (arg >> 7 & 1)
        if channel == 2:
            n += popcount(arg & 0x70)
        return 2 + n
    if idx in (26, 27):  # EE, EF: no argument
        return 1
    if chip == "opn" and 12 <= idx <= 15:  # BC-BF: 5 bytes of registers
        return 6
    return 2


def decode_fm(d: bytes, a: int, chip: str, channel: int) -> dict:
    """Decode a YM3526 or YM2203 FM phrase: steps of a duration and events."""
    steps = []
    i = a
    length = None  # the CE length of a second note
    while True:
        dur = d[i]
        if dur == 0:
            return {"addr": a, "end": i + 1, "steps": steps}
        if dur & 0x80:
            raise ValueError(f"duration {dur:02X} at {i:04X}")
        step = {"dur": dur, "events": []}
        steps.append(step)
        i += 1
        sounded = False
        while d[i] & 0x80:
            n = fm_event_length(d, i, chip, channel)
            b = d[i]
            plain = b & 15 < 0xC
            idx = ((b >> 4) & 7) * 4 + (b & 15) - 0xC
            sounds = plain or (b & 15) >= 0xC and (idx == 3 or idx in (26, 27))
            if sounds and sounded:
                # the player ends the step here and starts another with the CE length
                step = {"dur": length, "events": [], "split": True}
                steps.append(step)
            if sounds:
                sounded = True
            if idx == 18 and not plain:
                length = d[i + 1]
            step["events"].append(fm_event(d, i, n, chip, plain, idx))
            i += n


def fm_event(d: bytes, i: int, n: int, chip: str, plain: bool, idx: int) -> dict:
    b = d[i]
    if plain:
        return {"note": b & 15, "octave": b >> 4 & 7}
    ev = {"byte": f"{b:02X}", "args": [f"{x:02X}" for x in d[i + 1 : i + n]]}
    names = {
        18: "length",
        19: "voice",
        20: "lfo",
        21: "lfo_set",
        22: "env",
        23: "env_set",
        24: "env_depth",
        25: "gate",
        26: "key_off",
        27: "key_on",
        28: "volume",
        16: "ctrl",
        17: "tl_all" if chip == "opn" else "tl_both",
    }
    if idx in names:
        ev["name"] = names[idx]
    return ev


def decode_ssg(d: bytes, a: int) -> dict:
    """Decode an SSG phrase. A step is a duration (below 40, or any byte after F0)."""
    steps = []
    i = a
    while True:
        if d[i] == 0xF0:
            i += 1
        dur = d[i]
        if dur == 0:
            return {"addr": a, "end": i + 1, "steps": steps}
        step = {"dur": dur, "events": []}
        steps.append(step)
        i += 1
        while d[i] & 0xC0:
            b = d[i]
            hi, lo = b >> 4, b & 15
            if hi in (4, 5, 6, 7):
                n, ev = 2, {"byte": f"{b:02X}", "args": [f"{d[i + 1]:02X}"]}
                ev["name"] = ("tone_a", "tone_b", "tone_c", "env_period")[hi - 4]
            elif hi == 0xF:
                if lo == 0:
                    break  # ends the step: F0, then the next duration
                n = 3 if lo in (2, 4, 5, 6, 8, 9, 10) else 2
                ev = {"byte": f"{b:02X}", "args": [f"{x:02X}" for x in d[i + 1 : i + n]]}
                ev["name"] = SSG_F_NAMES.get(lo, "none")
            else:
                n, ev = 1, {"byte": f"{b:02X}"}
                ev["name"] = "volume_" + "abc"[hi - 8] if hi in (8, 9, 10) else "none"
            step["events"].append(ev)
            i += n


SSG_F_NAMES = {
    1: "noise",
    2: "noise_env",
    3: "hw_env",
    4: "tone_env_a",
    5: "tone_env_b",
    6: "tone_env_c",
    7: "mixer",
    8: "vol_env_a",
    9: "vol_env_b",
    10: "vol_env_c",
    15: "env_stop",
}


def decode_phrase(d: bytes, a: int, rid: int) -> dict:
    rid &= 0xFE
    if rid in (0x84, 0x86):
        return decode_ssg(d, a)
    if 0x8C <= rid <= 0x96:
        return decode_fm(d, a, "opn", (rid - 0x8C) // 4)
    return decode_fm(d, a, "opl", (rid - 0x98) // 4)


class Sound:
    def __init__(self, data: bytes) -> None:
        self.d = data
        self.cache: dict = {}

    def word(self, a: int) -> int:
        return self.d[a] | self.d[a + 1] << 8

    def block(self, a: int) -> dict:
        d = self.d
        rid = d[a]
        if rid & 0xFE in (0xF0, 0xF1):
            return {"addr": a, "id": rid, "record": record_name(rid), "now": True}
        n = d[a + 2]
        phrases = []
        # command 2E says 255 phrases but has one; the player would run on into the
        # next entry's bytes, so only the first is decoded
        for i in range(n if n < 0x80 else 1):
            p = a + 4 + 3 * i
            addr = self.word(p + 1)
            if (rid & 0xFE, addr) not in self.cache:
                self.cache[(rid & 0xFE, addr)] = decode_phrase(d, addr, rid)
            phrases.append(
                {
                    "priority": d[p] >> 4,
                    "repeats": d[p] & 15,
                    "addr": addr,
                    "end": self.cache[(rid & 0xFE, addr)]["end"],
                    "steps": self.cache[(rid & 0xFE, addr)]["steps"],
                }
            )
        return {
            "addr": a,
            "id": rid,
            "record": record_name(rid),
            "notify": bool(rid & 1),
            "priority": d[a + 1] >> 4,
            "passes": d[a + 1] & 15 or 16,
            "count": n,
            "next": None if d[a + 3] == 0xFF else d[a + 3],
            "phrases": phrases,
        }

    def entry(self, a: int) -> dict:
        d = self.d
        first = d[a]
        if first == 0:
            return {"addr": a, "items": []}
        if first >= BLOCK_MIN:
            return {"addr": a, "items": [self.block(a)]}
        items = []
        for i in range(first):
            w = self.word(a + 1 + 2 * i)
            if w >> 8 == 0:
                items.append({"queue": w & 0xFF})
            elif d[w] >= BLOCK_MIN:
                items.append(self.block(w))
            # a word whose first byte is below 1B starts nothing
        return {"addr": a, "items": items}


def describe(entry: dict) -> str:
    parts = []
    for it in entry["items"]:
        if "queue" in it:
            parts.append(f"queue {it['queue']:02X}")
    blocks = [it for it in entry["items"] if "queue" not in it]
    rec = sorted({it["record"] for it in blocks})
    if blocks:
        kinds = sorted({r.split()[0] for r in rec})
        plural = "s" if len(blocks) != 1 else ""
        parts.append(f"{len(blocks)} block{plural} ({', '.join(kinds)})")
    return "; ".join(parts) or "nothing"


def main() -> int:
    snd = Sound(IMAGE.read_bytes())
    commands = {}
    for c in range(COMMAND_COUNT):
        commands[f"{c:02X}"] = snd.entry(snd.word(COMMAND_TABLE + 2 * c))
    for i, c in enumerate((0xF2, 0xF4, 0xF6, 0xF8)):
        commands[f"{c:02X}"] = snd.entry(snd.word(COMMAND_F_TABLE + 4 * i))
    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(json.dumps(commands, indent=1) + "\n")

    sent = set()
    src = ROOT / "notes" / "sound_commands.md"
    if src.exists():
        for line in src.read_text().splitlines():
            if line.startswith("| ") and line[2:4].strip().isalnum() and len(line[2:4]) == 2:
                try:
                    sent.add(int(line[2:4], 16))
                except ValueError:
                    pass

    lines = [
        "# Sound blocks per command",
        "",
        "Generated by `tools/sounddec.py` from the sound ROM image. Do not edit.",
        "",
        "Each command's `COMMAND_TABLE` entry (or `COMMAND_F_TABLE` for F2-F8) is listed with the",
        "blocks it starts. A block names a record (`notes/sound.md`), a priority, the passes, the",
        "command it queues when it ends, and its phrases (the bytes they occupy, repeats, steps).",
        "The events of every phrase are in `build/sound/commands.json`.",
        "`*` marks commands the main CPU sent in the traced runs (`notes/sound_commands.md`).",
        "",
        "| Command | Entry | Starts |",
        "|---|---|---|",
    ]
    for name, e in commands.items():
        mark = "*" if int(name, 16) in sent else ""
        lines.append(f"| {name}{mark} | {e['addr']:04X} | {describe(e)} |")
    lines.append("")
    for name, e in commands.items():
        lines.append(f"## {name}")
        lines.append("")
        if not e["items"]:
            lines.append("Nothing.")
            lines.append("")
            continue
        for it in e["items"]:
            if "queue" in it:
                lines.append(f"- queues command {it['queue']:02X}")
            elif it.get("now"):
                lines.append(f"- `{it['addr']:04X}` applies events to a record at once (id {it['id']:02X})")
            else:
                ph = ", ".join(
                    f"{p['addr']:04X}-{p['end'] - 1:04X} x{p['repeats'] or 'inf'} ({len(p['steps'])} steps)"
                    for p in it["phrases"]
                )
                nxt = f", then {it['next']:02X}" if it["next"] is not None else ""
                note = ", replies" if it["notify"] else ""
                lines.append(
                    f"- `{it['addr']:04X}` {it['record']}: priority {it['priority']}, "
                    f"{it['passes']} pass(es){nxt}{note}; phrases {ph}"
                )
        lines.append("")
    OUT_MD.write_text("\n".join(lines))
    print(f"{len(commands)} commands -> {OUT_JSON.relative_to(ROOT)}, {OUT_MD.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
