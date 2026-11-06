"""Measure the order of the main CPU's, sub CPU's and MCU's shared RAM accesses within a frame.

Usage: python tools/frameorder.py [--name NAME] [--scenario game1p] [--seed N] [--round N]
                                  [--from SECONDS] [--frames N] [--report-only]

Runs MAME without the debugger on a trace.py scenario, with tools/frameorder.lua logging every
access to shared RAM and the entry to the routines in MARKS, each stamped with the CPU's local
time, into build/frameorder/<name>/events.csv. Then writes report.txt beside it:

  marks   when each routine starts, in microseconds after the frame's start
  tasks   when the main CPU's scheduler runs each task
  overlap how many of the sub CPU's reads get data the main CPU wrote this frame, by when the
          sub CPU's frame ends
  mcu     which frame's value each MCU job and each main CPU reader gets from the other
  orders  whether running two CPUs one after the other, a whole frame at a time, gives each read
          the byte it really read: for each reading routine, how many reads would differ with
          the writer running first, and with the reader running first
  flows   for each (writer, reader) pair of instructions on different CPUs: how many frames old
          the value is when it is read, and how close the two came

A frame starts just before the MCU's IRQ1 (mcu:F046) and the sub CPU's IRQ, which the vblank
raises together. Times are each CPU's own, but MAME only runs one CPU at a time, in slices of up
to QUANTUM_US, so two accesses closer than that may really have happened the other way round.
"""

import argparse
import bisect
import collections
import csv
import re
import statistics
import subprocess
import sys

import romset
import trace

ROOT = romset.ROOT
OUT = ROOT / "build" / "frameorder"
QUANTUM_US = 1e6 / 6000  # MAME's maximum_quantum for this driver
LEAD_US = 20  # the sub CPU takes its IRQ up to 11 us before the MCU's first instruction
WATCH_COUNTERS = {0xE338, 0xF66E}  # MAIN_FRAME and SUB_FRAMES: each CPU only checks the other runs
MAIN_IDLE = 0x01ED
TASKS = {0: "ATTRACT_TASK", 1: "TITLE_TASK", 2: "ROUND_TASK", 3: "OBJECTS_TASK",
         4: "ROUND_ENEMIES", 5: "BUBBLES_TASK"}

MARKS = {
    "main": ("src/main/fixed.s", """IRQ_HANDLER OBJ_COPY SCHEDULER FRAME_TICK TASK_SLEEP TASK_YIELD
                                    READ_INPUTS"""),
    "sub": ("src/sub/sub.s", """IDLE IRQ VBLANK GRID_UNPACK GHOST_HITS PLAYER_ENEMY_HITS
                                PLAYER_ENEMY_MARKS BUBBLE_HITS POP_CHAIN STARS_HITS FOOD_RAIN_HITS
                                ENEMY2_SHOT_HITS ENEMY3_SHOT_HITS LIGHTNING_HITS EFFECT_D_HITS
                                ENEMY2B_SHOT_HITS BOSS_SHOT_HITS BOSS_HITS ENEMY0B_SHOT_HITS
                                MAIN_WATCHDOG VBLANK_END"""),
    "mcu": ("src/mcu/mcu.s", """IRQ1 MAIN_IRQ READ_INPUTS OCF LOCKOUT_REQUEST P1_LIVES_JOB
                                P2_LIVES_JOB ROUND_JOB P1_PROX_JOB P2_PROX_JOB SPEED01_JOB
                                SPEED2_JOB SPEED3_JOB TIMER_JOB CREDITS_42_JOB EXTEND_TICK
                                FETCH0_JOB FETCH1_JOB FETCH2_JOB RESET_REQUEST"""),
}
EXTRA_MARKS = {"main": {MAIN_IDLE: "IDLE", 0x0490: "IRQ_BUSY_PATH"},
               "mcu": {0xF08C: "DELAY", 0xF091: "RTI"}, "sub": {}}
LABEL = re.compile(r"^(\w+):\s*; ([0-9A-F]{4})\s*$", re.M)


def mark_names() -> dict:
    """{cpu: {address: name}} for the routines in MARKS."""
    names = {}
    for cpu, (source, wanted) in MARKS.items():
        labels = {m[1]: int(m[2], 16) for m in LABEL.finditer((ROOT / source).read_text())}
        names[cpu] = {labels[w]: w for w in wanted.split()}
        names[cpu].update(EXTRA_MARKS[cpu])
    return names


def capture(args, folder) -> None:
    folder.mkdir(parents=True, exist_ok=True)
    events, _, _, dips = trace.scenario(args.scenario, args.start + args.frames // 60 + 2, args.seed)
    events.sort(key=lambda e: e["f"])
    start = args.start * trace.FPS
    cfg = {"out": (folder / "events.csv").as_posix(), "start": start, "stop": start + args.frames,
           "events": events, "marks": {c: sorted(n) for c, n in mark_names().items()},
           "round": args.round, "boss_hits": 0, "boss_pop": False, "special": 0, "clear": False,
           "poke": []}
    script = folder / "run.lua"
    script.write_text("CFG = " + trace.lua_value(cfg) + "\n\n"
                      + (ROOT / "tools" / "cheats.lua").read_text() + "\n"
                      + (ROOT / "tools" / "frameorder.lua").read_text(), encoding="utf-8")
    trace.write_cfg(folder / "cfg", dips)
    exe = trace.mame_exe()
    argv = [str(exe), "bublbobl", "-rompath", str(ROOT / "build" / "roms"), "-skip_gameinfo",
            "-cfg_directory", str(folder / "cfg"), "-nvram_directory", str(folder / "nvram"),
            "-autoboot_script", str(script), "-video", "none", "-sound", "none", "-nothrottle"]
    result = subprocess.run(argv, cwd=exe.parent, capture_output=True, text=True)
    (folder / "mame.log").write_text(result.stdout + result.stderr)
    if result.returncode:
        raise SystemExit(f"MAME failed, see {folder / 'mame.log'}")


def load(path) -> list:
    """Events sorted by time: (t, cpu, kind, addr, data, pc)."""
    with path.open(newline="") as f:
        rows = [(float(r["t"]), r["cpu"], r["kind"], int(r["addr"], 16), int(r["data"], 16), r["pc"])
                for r in csv.DictReader(f)]
    rows.sort(key=lambda r: r[0])
    return rows


def frame_of(starts, t) -> int:
    return bisect.bisect_right(starts, t) - 1


def spread(values) -> str:
    return f"{min(values):9.1f} {statistics.median(values):9.1f} {max(values):9.1f}"


def report_marks(rows, starts, names, write) -> None:
    seen = collections.defaultdict(list)
    per_frame = collections.Counter()
    for t, cpu, kind, addr, data, pc in rows:
        if kind not in "XI":
            continue
        i = bisect.bisect_right(starts, t) - 1
        if i < 0 or i + 1 >= len(starts):
            continue
        name = "(main IRQ raised)" if kind == "I" else names[cpu].get(addr, f"{addr:04X}")
        seen[cpu, name].append(t - starts[i])
        per_frame[cpu, name, i] += 1
    total = len(starts) - 1
    write(f"{total} frames; length {spread([b - a for a, b in zip(starts, starts[1:])])} us\n")
    write(f"{'cpu':5}{'mark':24}{'frames':>7}{'per frame':>10}{'first':>10}{'median':>10}{'last':>10}")
    for (cpu, name), offsets in sorted(seen.items(), key=lambda kv: statistics.median(kv[1])):
        frames = sum(1 for k in per_frame if k[:2] == (cpu, name))
        write(f"{cpu:5}{name:24}{frames:7}{len(offsets) / frames:10.2f} {spread(offsets)}")


def routines() -> dict:
    """{cpu or bank: sorted [(address, name)]} of the named labels in the source."""
    files = {"main": "src/main/fixed.s", "sub": "src/sub/sub.s", "mcu": "src/mcu/mcu.s"}
    files.update({f"bank{i}": f"src/main/bank{i}.s" for i in range(4)})
    found = {}
    for key, source in files.items():
        labels = LABEL.finditer((ROOT / source).read_text())
        found[key] = sorted((int(m[2], 16), m[1]) for m in labels if not m[1].startswith("L_"))
    return found


def routine_of(table, cpu, pc) -> str:
    key, _, address = pc.rpartition(":")
    labels = table[key or cpu]
    i = bisect.bisect_right(labels, (int(address, 16), "~")) - 1
    return f"{cpu}:{labels[i][1]}" if i >= 0 else f"{cpu}:{pc}"


def report_orders(rows, starts, write) -> None:
    table = routines()
    writes = collections.defaultdict(lambda: collections.defaultdict(lambda: ([], [])))
    for t, cpu, kind, addr, data, pc in rows:
        if kind == "W":
            times, values = writes[addr][cpu]
            times.append(t)
            values.append(data)

    def last(addr, cpu, before):
        """(time, value) of cpu's last write to addr before a time, or None."""
        times, values = writes[addr][cpu]
        i = bisect.bisect_left(times, before) - 1
        return (times[i], values[i]) if i >= 0 else None

    def modelled(addr, reader, other, t, end, other_first):
        """The byte a read at t gets if, each frame, other runs wholly before or after reader."""
        mine = last(addr, reader, t)
        theirs = last(addr, other, end if other_first else starts[frame_of(starts, t)])
        if not mine or not theirs:
            return (mine or theirs or (0, None))[1]  # None: nothing in the capture says
        same_frame_order = (1, 0) if other_first else (0, 1)
        mine_key = (frame_of(starts, mine[0]), same_frame_order[0], mine[0])
        theirs_key = (frame_of(starts, theirs[0]), same_frame_order[1], theirs[0])
        return mine[1] if mine_key > theirs_key else theirs[1]

    def within_quantum(addr, t, data):
        """Could a write within one slice of t, happening the other way round, give this byte?"""
        for times, values in writes[addr].values():
            lo = bisect.bisect_left(times, t - QUANTUM_US)
            hi = bisect.bisect_right(times, t + QUANTUM_US)
            if data in values[max(lo - 1, 0):hi]:
                return True
        return False

    tally = collections.defaultdict(lambda: [0, 0, 0])
    stale = unexplained = total = 0
    for t, cpu, kind, addr, data, pc in rows:
        if kind != "R" or addr not in writes or addr in WATCH_COUNTERS:
            continue
        i = frame_of(starts, t)
        if i < 1 or i + 1 >= len(starts):
            continue
        for other in [c for c, (times, _) in writes[addr].items() if times]:
            if other == cpu or {cpu, other} == {"sub", "mcu"}:
                continue
            other_first = modelled(addr, cpu, other, t, starts[i + 1], True)
            reader_first = modelled(addr, cpu, other, t, starts[i + 1], False)
            if other_first is None or reader_first is None:
                continue
            entry = tally[other, routine_of(table, cpu, pc)]
            entry[0] += 1
            entry[1] += other_first != data
            entry[2] += reader_first != data
            mine, theirs = last(addr, cpu, t), last(addr, other, t)
            latest = max(x for x in (mine, theirs) if x) if mine or theirs else None
            total += 1
            if latest is not None and latest[1] != data:
                stale += 1
                unexplained += not within_quantum(addr, t, data)
    write(f"Reads whose byte is not the last write by timestamp: {stale} of {total};"
          f" not explained by a write within one slice: {unexplained}\n")
    write(f"{'writer':7}{'reader':34}{'reads':>8}{'wrong, writer first':>21}{'wrong, reader first':>21}")
    for (other, reader), (n, first, after) in sorted(
            tally.items(), key=lambda kv: (kv[0][0], kv[0][1].split(":")[0], -max(kv[1][1:3]))):
        if first or after:
            write(f"{other:7}{reader:34}{n:8}{first:21}{after:21}")
    write()
    for pair in sorted({(o, r.split(":")[0]) for o, r in tally}):
        sums = [sum(v[k] for (o, r), v in tally.items() if (o, r.split(":")[0]) == pair)
                for k in range(3)]
        write(f"{pair[0]:>5} -> {pair[1]:5} {sums[0]:9} reads, wrong with writer first {sums[1]:7},"
              f" with reader first {sums[2]:7}")


def report_tasks(rows, starts, write) -> None:
    """When the main CPU's scheduler runs each task. SCHEDULER stores the slot at 0068."""
    runs = collections.defaultdict(list)
    orders = collections.defaultdict(list)
    current = None

    def close(t):
        if current:
            slot, begun = current
            runs[slot].append((begun - starts[frame_of(starts, begun)], t - begun))

    for t, cpu, kind, addr, data, pc in rows:
        if cpu != "main":
            continue
        if kind == "W" and addr == 0xE192 and pc == "0068":
            close(t)
            current = (data, t)
            orders[frame_of(starts, t)].append(data)
        elif kind == "X" and addr == MAIN_IDLE:
            close(t)
            current = None
    write(f"{'task':16}{'runs':>6}{'first':>10}{'median':>10}{'last':>10}"
          f"{'shortest':>10}{'median':>10}{'longest':>10}")
    for slot, seen in sorted(runs.items()):
        begun, length = zip(*seen)
        write(f"{TASKS.get(slot, slot):16}{len(seen):6} {spread(begun)} {spread(length)}")
    counts = collections.Counter(tuple(v) for v in orders.values())
    write("Orders: " + ", ".join(f"{' '.join(map(str, k))} x {n}" for k, n in counts.most_common()))


def report_overlap(rows, starts, names, write) -> None:
    """How far the sub CPU's frame runs into the main CPU's: its reads of this frame's data."""
    written = collections.defaultdict(lambda: ([], [], []))
    finish = {}
    end = next(a for a, n in names["sub"].items() if n == "VBLANK_END")
    for t, cpu, kind, addr, data, pc in rows:
        if kind == "W" and cpu == "main":
            times, values, pcs = written[addr]
            times.append(t)
            values.append(data)
            pcs.append(pc)
        elif kind == "X" and cpu == "sub" and addr == end:
            finish[frame_of(starts, t)] = t - starts[frame_of(starts, t)]
    table = routines()
    newer = collections.Counter()
    reads = collections.Counter()
    writers = collections.Counter()
    readers = collections.Counter()
    for t, cpu, kind, addr, data, pc in rows:
        if cpu != "sub" or kind != "R" or addr not in written or addr in WATCH_COUNTERS:
            continue
        frame = frame_of(starts, t)
        if frame < 1 or frame + 1 >= len(starts):
            continue
        times, values, pcs = written[addr]
        at_start = bisect.bisect_left(times, starts[frame]) - 1
        at_read = bisect.bisect_left(times, t) - 1
        reads[frame] += 1
        if at_read > at_start >= 0 and values[at_start] != data:
            newer[frame] += 1
            writers[routine_of(table, "main", pcs[at_read])] += 1
            readers[routine_of(table, "sub", pc)] += 1
    buckets = collections.defaultdict(list)
    for frame, t in finish.items():
        buckets[int(t // 2000) * 2].append(frame)
    write(f"{'sub ends, ms':14}{'frames':>7}{'frames with new data':>22}{'reads each':>12}{'of them new':>13}")
    for ms, frames in sorted(buckets.items()):
        hit = sum(1 for f in frames if newer[f])
        write(f"{f'{ms}-{ms + 2}':14}{len(frames):7}{hit:22}"
              f"{sum(reads[f] for f in frames) / len(frames):12.0f}"
              f"{sum(newer[f] for f in frames) / len(frames):13.1f}")
    write(f"Written by: {writers.most_common(8)}")
    write(f"Read by: {readers.most_common(8)}")


def report_mcu(rows, starts, names, write) -> None:
    """Which MCU job meets which main CPU routine, and which frame's value each one gets."""
    table = routines()
    by_main = collections.defaultdict(lambda: ([], [], []))
    by_mcu = collections.defaultdict(lambda: ([], [], []))
    job = None
    for t, cpu, kind, addr, data, pc in rows:
        if cpu == "mcu" and kind == "X":
            job = names["mcu"].get(addr, f"{addr:04X}")
        elif kind == "W" and addr >= 0xFC00 and cpu in ("main", "mcu"):
            times, values, who = (by_main if cpu == "main" else by_mcu)[addr]
            times.append(t)
            values.append(data)
            who.append(pc if cpu == "main" else job)
    mcu_reads = collections.defaultdict(lambda: [0, 0, [], []])
    main_reads = collections.defaultdict(lambda: [0, 0, 0, [], []])
    job = None
    for t, cpu, kind, addr, data, pc in rows:
        if cpu == "mcu" and kind == "X":
            job = names["mcu"].get(addr, f"{addr:04X}")
        if kind != "R":
            continue
        frame = frame_of(starts, t)
        if frame < 1 or frame + 1 >= len(starts):
            continue
        offset = t - starts[frame]
        if cpu == "mcu" and addr in by_main:
            times, values, who = by_main[addr]
            at_start = bisect.bisect_left(times, starts[frame]) - 1
            at_read = bisect.bisect_left(times, t) - 1
            writer = routine_of(table, "main", who[at_read]) if at_read >= 0 else "(none yet)"
            entry = mcu_reads[job, writer]
            entry[0] += 1
            entry[1] += at_read > at_start >= 0 and values[at_start] != data
            entry[2].append(offset)
        elif cpu == "main" and addr in by_mcu:
            times, values, who = by_mcu[addr]
            at_start = bisect.bisect_left(times, starts[frame]) - 1
            at_read = bisect.bisect_left(times, t) - 1
            at_end = bisect.bisect_left(times, starts[frame + 1]) - 1
            if at_read < 0:
                continue
            entry = main_reads[who[at_read], routine_of(table, "main", pc)]
            entry[0] += 1
            entry[1] += at_read > at_start
            entry[2] += at_end > at_read and values[at_end] != data
            entry[3].append(offset)
    write(f"{'MCU job':18}{'last written by':28}{'reads':>7}{'new this frame':>16}{'first':>10}{'last':>10}")
    for (name, writer), e in sorted(mcu_reads.items(), key=lambda kv: min(kv[1][2])):
        write(f"{name:18}{writer:28}{e[0]:7}{e[1]:16}{min(e[2]):10.0f}{max(e[2]):10.0f}")
    write()
    write(f"{'Main reader':28}{'last written by':18}{'reads':>7}{'new this frame':>16}"
          f"{'changed later':>15}{'first':>10}{'last':>10}")
    for (name, reader), e in sorted(main_reads.items(), key=lambda kv: min(kv[1][3])):
        write(f"{reader:28}{name:18}{e[0]:7}{e[1]:16}{e[2]:15}{min(e[3]):10.0f}{max(e[3]):10.0f}")


def report_flows(rows, starts, write) -> None:
    last_write = {}  # addr -> (t, cpu, pc, frame)
    flows = {}
    for t, cpu, kind, addr, data, pc in rows:
        if kind == "W":
            last_write[addr] = (t, cpu, pc, bisect.bisect_right(starts, t) - 1)
        elif kind == "R":
            w = last_write.get(addr)
            if w is None or w[1] == cpu:
                continue
            key = (w[1], w[2], cpu, pc, addr)
            f = flows.setdefault(key, {"n": 0, "ages": collections.Counter(), "gap": 1e12})
            f["n"] += 1
            f["ages"][bisect.bisect_right(starts, t) - 1 - w[3]] += 1
            f["gap"] = min(f["gap"], t - w[0])
    write(f"{'addr':6}{'writer':16}{'reader':16}{'reads':>7}  {'smallest gap us':>15}  frames old")
    for (wc, wp, rc, rp, addr), f in sorted(flows.items(), key=lambda kv: (kv[0][4], kv[0][0], kv[0][2])):
        ages = " ".join(f"{a}:{n}" for a, n in sorted(f["ages"].items()))
        flag = "  <quantum" if f["gap"] < QUANTUM_US else ""
        write(f"{addr:04X}  {wc + ':' + wp:16}{rc + ':' + rp:16}{f['n']:7}  {f['gap']:15.1f}  {ages}{flag}")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--name", default="game1p")
    ap.add_argument("--scenario", default="game1p")
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--round", type=int, default=1)
    ap.add_argument("--from", dest="start", type=int, default=20, help="start logging at this second")
    ap.add_argument("--frames", type=int, default=300)
    ap.add_argument("--report-only", action="store_true")
    args = ap.parse_args()
    folder = OUT / args.name
    if not args.report_only:
        capture(args, folder)
    rows = load(folder / "events.csv")
    names = mark_names()
    irq1 = next(a for a, n in names["mcu"].items() if n == "IRQ1")
    starts = [r[0] - LEAD_US for r in rows if r[1] == "mcu" and r[2] == "X" and r[3] == irq1]
    with (folder / "report.txt").open("w") as f:
        def write(line=""):
            f.write(line + "\n")
        report_marks(rows, starts, names, write)
        write()
        report_tasks(rows, starts, write)
        write()
        report_overlap(rows, starts, names, write)
        write()
        report_mcu(rows, starts, names, write)
        write()
        report_orders(rows, starts, write)
        write()
        report_flows(rows, starts, write)
    print(f"{len(rows):,} events, {len(starts)} frames -> {folder / 'report.txt'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
