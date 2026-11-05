"""Check the decoded phrases against build/soundcmp/regs.csv (made by tools/soundcmp.py).

Usage: python tools/soundcheck.py CMD [CMD ...]
For each A record of a command: the key-on times (YM3526 B0-B8 bit 5, YM2203 register 28) are
fitted to one tick period and compared with the decoded steps' cumulative durations; the YM3526
and YM2203 also compare the block of each note. For SSG records every step that sets a tone is
looked up among the writes to that channel's tone registers (0-5) within two ticks.
"""
import csv
import json
import sys

import romset

R = romset.ROOT
C = json.load(open(R / "build" / "sound" / "commands.json"))
T = json.load(open(R / "build" / "sound" / "tables.json"))
ROWS = [(r[0], float(r[1]), r[2], int(r[3]) & 1, int(r[4], 16))
        for r in csv.reader(open(R / "build" / "soundcmp" / "regs.csv")) if r[0]]


def timeline(b):
    """(tick, step) for every step of a block's passes, phrases and repeats."""
    t = 0
    out = []
    for _ in range(b["passes"]):
        for ph in b["phrases"]:
            for _ in range(ph["repeats"] or 40):
                for s in ph["steps"]:
                    out.append((t, s))
                    t += s["dur"] or 0
    return out


def fit(xs, ys):
    n = len(xs)
    mx, my = sum(xs) / n, sum(ys) / n
    den = sum((a - mx) ** 2 for a in xs)
    k = sum((a - mx) * (b - my) for a, b in zip(xs, ys)) / den
    return k, my - k * mx


def observe(cmd, chip):
    """Key-on times by channel (and the YM3526 block of each)."""
    reg = None
    on = {}
    state = {}
    for c, t, ch_, p, v in ROWS:
        if c != cmd or ch_ != chip or t < 0.03:  # the first 30 ms: the sound-off before the command
            continue
        if p == 0:
            reg = v
        elif chip == "opl":
            if reg is not None and 0xB0 <= reg <= 0xB8:
                ch = reg - 0xB0
                if v & 0x20 and not state.get(ch):
                    on.setdefault(ch, []).append((t, (v >> 2) & 7))
                state[ch] = v & 0x20
        elif reg == 0x28 and v & 0xF0 and (v & 3) < 3:
            on.setdefault(v & 3, []).append((t, None))
    return on


def check_fm(cmd, blocks, chip):
    """Pool the command's records on one chip: one tick period for all channels."""
    on = observe(cmd, chip)
    xs, ys = [], []
    wrong = n = 0
    for b in blocks:
        ch = int(b["record"].split()[1][2:]) - 1
        onsets = [(t, e) for t, s in timeline(b) for e in s["events"] if "note" in e or e.get("byte") == "8F"]
        obs = on.get(ch, [])
        for o, (t, e) in zip(obs, onsets):
            xs.append(t)
            ys.append(o[0])
            n += 1
            if chip == "opl" and "octave" in e and o[1] != e["octave"]:
                wrong += 1
    name = f"{cmd} {chip.upper()} ch{','.join(b['record'].split()[1][2:] for b in blocks)}"
    if len({x for x in xs}) < 2:
        return f"{name}: {n} notes, too few ticks to fit"
    k, c0 = fit(xs, ys)
    res = [(y - c0) / k - x for x, y in zip(xs, ys)]
    extra = f", {wrong} wrong blocks" if chip == "opl" else ""
    return f"{name}: {n} notes, tick {k * 1000:.2f} ms, onset residual max {max(abs(r) for r in res):.2f} ticks{extra}"


def check_ssg(cmd, b):
    which = "ab".index(b["record"][-1].lower()) if False else 0
    tl = timeline(b)
    obs = {}
    reg = None
    for c, t, chip, p, v in ROWS:
        if c != cmd or chip != "opn":
            continue
        if p == 0:
            reg = v
        elif reg is not None and reg < 6:
            obs.setdefault(reg // 2, []).append(t)
    # tick: take it from the YM2203 timer B (16.5 ms) -- measured on the YM2203 checks
    tick = 0.0165
    allw = sorted(x for l in obs.values() for x in l)
    if not allw:
        return f"{cmd} SSG: no tone writes"
    t0 = allw[0]
    hit = tot = 0
    for t, s in tl[:200]:
        for e in s["events"]:
            if e.get("name", "").startswith("tone_"):
                tot += 1
                ch = "abc".index(e["name"][-1])
                if any(0 <= w - t0 - t * tick < 2 * tick for w in obs.get(ch, [])):
                    hit += 1
    return f"{cmd} {b['record']}: {hit} of {tot} tone events have a tone write within two ticks"


def main() -> int:
    for cmd in sys.argv[1:]:
        recs = [b for b in C[cmd]["items"] if "queue" not in b and not b.get("now") and b["record"].endswith("A")]
        for chip, pre in (("opl", "OPL"), ("opn", "OPN")):
            bl = [b for b in recs if b["record"].startswith(pre)]
            if bl:
                print(check_fm(cmd, bl, chip))
        for b in recs:
            if b["record"].startswith("SSG"):
                print(check_ssg(cmd, b))
    return 0


if __name__ == "__main__":
    sys.exit(main())
