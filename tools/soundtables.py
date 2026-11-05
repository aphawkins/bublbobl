"""Write build/sound/tables.json: the sound ROM's tables in a form a synthesiser can use.

Usage: python tools/soundtables.py

Reads build/images/sound.bin. Layouts are from notes/sound.md and the voice handlers
OPL_EV_VOICE and OPN_EV_VOICE in src/sound/sound.s:
- note tables: 12 F-numbers each (OPL_NOTES, OPN_NOTES);
- voices: the chip's register values, then the LFO and envelope setup that the voice
  event passes to the DC-DF and EC events;
- stepped envelopes (FM, SSG tone, SSG volume): entries of 5 bytes (interval change, loops,
  next entry, a pointer to the points).
"""

import json

import romset

ROOT = romset.ROOT
D = (ROOT / "build" / "images" / "sound.bin").read_bytes()


def word(a: int) -> int:
    return D[a] | D[a + 1] << 8


def pop(v: int) -> int:
    return bin(v).count("1")


def tail(a: int, chip: str) -> tuple[dict, int]:
    """The LFO and envelope setup that ends a voice, from a; returns it and the next address."""
    out = {}
    start = a
    mask = D[a]
    a += 1
    if mask:
        out["lfo"] = {"rate": [D[a], D[a + 1]], "shape": D[a + 2]}
        a += 3
    out["lfo_mask"] = mask
    out["lfo_depths"] = list(D[a : a + pop(mask)])
    a += pop(mask)
    emask = D[a]
    a += 1
    if emask:
        out["env"] = {"entry": D[a], "interval": D[a + 1]}
        a += 2
    n = pop(emask & 7) if chip == "opl" else pop(emask & 0x8F)
    out["env_mask"] = emask
    out["env_depths"] = list(D[a : a + n])
    if chip == "opn" and emask & 0x70:
        out["note"] = "b4-6 add depth bytes on channel 3 only; not counted here"
    a += n
    out["env_depth_on_rate"] = D[a]
    a += 1
    out["bytes"] = a - start
    return out, a


def opl_voice(a: int) -> dict:
    b0, b1 = D[a], D[a + 1]
    v = {
        "addr": a,
        "feedback": b0 >> 4 & 7,
        "connection": b0 & 1,
        "am_depth": b1 >> 4 & 1,
        "vib_depth": b1 & 1,
        "operators": [],
    }
    a += 2
    for _ in range(2):
        # the byte holds an attenuation (TL = ~byte & 3F) and the KSL bits (C0)
        v["operators"].append(
            {"tl": ~D[a] & 0x3F, "ksl": D[a] >> 6, "reg20": D[a + 1], "reg60": D[a + 2], "reg80": D[a + 3]}
        )
        a += 4
    t, a = tail(a, "opl")
    v.update(t)
    v["bytes"] = a - v["addr"]
    return v


def opn_voice(a: int) -> dict:
    b0, b1 = D[a], D[a + 1]
    v = {
        "addr": a,
        "reg_b0": (b1 & 7) | (b1 & 0x70) >> 1,  # algorithm and feedback
        "lfo_sens": (b0 & 0x1F) << 4 & 0xFF,
        "slots": [],
    }
    a += 2
    for slot in range(4):  # registers +0, +4, +8, +C from 30/40/50/60/70/80/90
        s = D[a : a + 7]
        v["slots"].append(
            {"reg40_tl": s[0], "reg30": s[1], "reg90": s[2], "reg50": s[3], "reg60": s[4], "reg70": s[5], "reg80": s[6]}
        )
        a += 7
    t, a = tail(a, "opn")
    v.update(t)
    v["bytes"] = a - v["addr"]
    return v


def envs(table: int, count: int) -> list:
    out = []
    for i in range(count):
        a = table + 5 * i
        out.append({"index": i, "interval_change": D[a], "loops": D[a + 1], "next": D[a + 2], "points_addr": word(a + 3)})
    return out


def points(addr: int, nibbles: bool) -> list:
    out = []
    while D[addr]:
        if nibbles:
            hi, lo = D[addr] >> 4, D[addr] & 15
            out.append(hi)
            if not lo:
                break
            out.append(lo)
        else:
            out.append(D[addr])
        addr += 1
    return out


def main() -> int:
    opl = [word(0x28D7 + 2 * i) for i in range(29)]
    opn = [word(0x2A8A + 2 * i) for i in range(59)]
    t = {
        "opl_notes": [word(0x0840 + 2 * i) for i in range(12)],
        "opn_notes": [word(0x1619 + 2 * i) for i in range(12)],
        "opl_voices": [opl_voice(a) for a in opl],
        "opn_voices": [opn_voice(a) for a in opn],
    }
    for name, table, count, nib in (
        ("opl_envs", 0x3A71, 1, False),
        ("opn_envs", 0x3A79, 20, False),
        ("ssg_vol_envs", 0x3B3D, 5, True),
        ("ssg_tone_envs", 0x3B60, 14, False),
    ):
        e = envs(table, count)
        for x in e:
            x["points"] = points(x["points_addr"], nib)
        t[name] = e
    out = ROOT / "build" / "sound" / "tables.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(t, indent=1) + "\n")
    print(f"{len(opl)} OPL voices, {len(opn)} OPN voices -> {out.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
