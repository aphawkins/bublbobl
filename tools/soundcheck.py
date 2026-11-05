"""Check the decoded phrases against build/soundcmp/regs.csv (made by tools/soundcmp.py).

Usage: python tools/soundcheck.py CMD [CMD ...]
CMD can be all, for every command in regs.csv. Each channel's A record is checked, or its B record
where the command starts no A record there. The key-on times (YM3526 B0-B8 bit 5, YM2203 register
28) are fitted to one tick period and compared with the decoded steps' cumulative durations; the
YM3526 also compares the block of each note. For SSG records the value of every event must turn
up, in order, among the writes to its register.

With --voices, the chip's registers at each key-on are compared with the decoded voice: every
register but the total levels, which the volume and modulation move. Key-ons whose voice an
operator event has changed are counted but not compared.
Usage: python tools/soundcheck.py --voices CMD [CMD ...]
"""
import csv
import json
import sys

import romset

R = romset.ROOT
C = json.load(open(R / "build" / "sound" / "commands.json"))
T = json.load(open(R / "build" / "sound" / "tables.json"))
ROWS = {}  # (command, chip): [(seconds, port, value)]
for r in csv.reader(open(R / "build" / "soundcmp" / "regs.csv")):
    if r and r[0]:
        ROWS.setdefault((r[0], r[2]), []).append((float(r[1]), int(r[3]) & 1, int(r[4], 16)))


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
    for t, p, v in ROWS.get((cmd, chip), []):
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
        onsets = [(t, e) for t, _, _, e in keyed_steps(b)]
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


OPL_SLOT = [0, 1, 2, 8, 9, 10, 16, 17, 18]


def keyed_steps(b):
    """(tick, voice, changed, note) for each key-on of a block, by the rules of OPL_EVENTS.

    A step's events all land before its register write, so a step's CF counts for its own note.
    CC A1 makes notes change the pitch only; EF keys on whatever the setting. changed: an
    operator event or CC has moved a compared register since the voice.
    """
    levels = ("AC", "AD") if b["record"].startswith("OPL") else ("AC", "AD", "AE", "AF")  # total levels
    keying = True
    voice = None
    changed = False
    out = []
    for t, s in timeline(b):
        hit = None
        for e in s["events"]:
            byte = e.get("byte")
            if "note" in e or byte == "8F":
                if keying:
                    hit = hit or e
            elif byte == "CF":
                voice = int(e["args"][0], 16)
                changed = False
            elif byte == "EF":
                hit = hit or e
            elif byte == "CC" and e["args"][0] in ("A0", "A1"):
                keying = e["args"][0] == "A0"
            elif byte == "CC" and int(e["args"][0], 16) < 0x80:
                changed = True
            elif byte and byte[0] in "9AB" and byte[1] in "CDEF" and byte not in levels:
                changed = True
        if hit:
            out.append((t, voice, changed, hit))
    return out


def snapshots(cmd, chip):
    """The chip's registers at each key-on, by channel: [(seconds, {register: value})]."""
    regs = {}
    reg = None
    on = {}
    keyed = {}
    for t, p, v in ROWS.get((cmd, chip), []):
        if p == 0:
            reg = v
            continue
        regs[reg] = v
        if chip == "opl" and 0xB0 <= reg <= 0xB8:
            ch = reg - 0xB0
            if v & 0x20 and not keyed.get(ch):
                on.setdefault(ch, []).append((t, dict(regs)))
            keyed[ch] = v & 0x20
        elif chip == "opn" and reg == 0x28 and (v & 3) < 3:
            ch = v & 3
            if v & 0xF0 and not keyed.get(ch):
                on.setdefault(ch, []).append((t, dict(regs)))
            keyed[ch] = v & 0xF0
    return on


def opl_expected(ch, voice):
    v = T["opl_voices"][voice]
    want = {0xC0 + ch: (v["feedback"] << 1) | v["connection"]}
    for i, op in enumerate(v["operators"]):
        base = OPL_SLOT[ch] + 3 * i
        want[0x20 + base] = op["reg20"]
        want[0x60 + base] = op["reg60"]
        want[0x80 + base] = op["reg80"]
    return want


def opn_expected(ch, voice):
    v = T["opn_voices"][voice]
    want = {0xB0 + ch: v["reg_b0"]}
    for i, s in enumerate(v["slots"]):
        for r, mask in ((0x30, 0xFF), (0x50, 0xDF), (0x60, 0x1F), (0x70, 0x1F), (0x80, 0xFF)):  # as L_1D67
            want[r + 4 * i + ch] = s[f"reg{r:x}"] & mask
    return want


def check_voices(cmd, blocks, chip):
    """The registers at each key-on against the voice: (compared, differ, skipped, voices, diffs)."""
    on = snapshots(cmd, chip)
    expected = opl_expected if chip == "opl" else opn_expected
    keys = bad = skipped = 0
    used = set()
    diffs = {}
    for b in blocks:
        ch = int(b["record"].split()[1][2:]) - 1
        for (_, voice, changed, _), (_, regs) in zip(keyed_steps(b), on.get(ch, [])):
            if voice is None or changed:
                skipped += 1
                continue
            keys += 1
            used.add(voice)
            wrong = [(r, x, regs.get(r)) for r, x in expected(ch, voice).items() if regs.get(r) != x]
            bad += bool(wrong)
            for r, x, got in wrong:
                diffs.setdefault((voice, r), (x, got, ch))
    return keys, bad, skipped, used, diffs


def ssg_writes(s):
    """The (register, value) pairs a step's events write."""
    out = []
    for e in s["events"]:
        name = e.get("name", "")
        if name.startswith("tone_"):
            reg = "abc".index(name[-1]) * 2
            out += [(reg, int(e["args"][0], 16)), (reg + 1, int(e["byte"][1], 16))]
        elif name.startswith("volume_"):
            out.append((8 + "abc".index(name[-1]), int(e["byte"][1], 16)))
        elif name == "mixer":
            out.append((7, int(e["args"][0], 16) & 0x3F))
    return out


def check_ssg(cmd, b):
    seen = {}
    reg = None
    last = 0.0
    for t, p, v in ROWS.get((cmd, "opn"), []):
        if p == 0:
            reg = v
        elif reg is not None and reg < 16:
            seen.setdefault(reg, []).append(v & 0x3F if reg == 7 else v)
            last = t
    tick = 0.0165  # the YM2203's timer B; no SSG block sets it
    at = {}
    hit = tot = 0
    missing = []
    for t, s in timeline(b):
        if t * tick > last:
            break
        for r, v in ssg_writes(s):
            tot += 1
            ws = seen.get(r, [])
            i = at.get(r, 0)
            while i < len(ws) and ws[i] != v:
                i += 1
            if i < len(ws):
                hit += 1
                at[r] = i + 1
            else:
                missing.append(f"{r:X}={v:02X}")
    more = f", missing {' '.join(missing[:6])}" if missing else ""
    return f"{cmd} {b['record']}: {hit} of {tot} register values written in order{more}"


def played(cmd):
    """The blocks a command plays: each channel's A record, or its B record if it has no A."""
    blocks = [b for b in C[cmd]["items"] if "queue" not in b and not b.get("now")]
    a = {b["record"][:-2] for b in blocks if b["record"].endswith(" A")}
    return [b for b in blocks if b["record"].endswith(" A") or b["record"][:-2] not in a]


def voices_main(cmds) -> int:
    seen = {"opl": set(), "opn": set()}
    total = bad_total = 0
    for cmd in cmds:
        recs = played(cmd)
        for chip, pre in (("opl", "OPL"), ("opn", "OPN")):
            bl = [b for b in recs if b["record"].startswith(pre)]
            if not bl:
                continue
            keys, bad, skipped, used, diffs = check_voices(cmd, bl, chip)
            seen[chip] |= used
            total += keys
            bad_total += bad
            print(f"{cmd} {chip.upper()}: {keys} key-ons, {bad} differ, {skipped} skipped, voices {sorted(used)}")
            for (v, r), (x, got, ch) in list(diffs.items())[:6]:
                print(f"    voice {v} ch{ch + 1} register {r:02X}: decoded {x:02X}, chip {got if got is None else format(got, '02X')}")
    print(f"{total} key-ons, {bad_total} differ")
    print(f"voices seen: YM3526 {len(seen['opl'])} of {len(T['opl_voices'])}, YM2203 {len(seen['opn'])} of {len(T['opn_voices'])}")
    return 0


def main() -> int:
    args = sys.argv[1:]
    voices = args[:1] == ["--voices"]
    if voices:
        args = args[1:]
    if args == ["all"]:
        args = sorted({c for c, _ in ROWS if c in C})
    if voices:
        return voices_main(args)
    for cmd in args:
        recs = played(cmd)
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
