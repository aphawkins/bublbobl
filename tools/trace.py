"""Run MAME on a scripted scenario and record what each CPU executes and touches.

Usage: python tools/trace.py SCENARIO [--seconds N] [--seed N] [--cpus main,sub,...]
       python tools/trace.py play [--inp FILE]
       python tools/trace.py --list

MAME runs headless with the debugger on (-debugger none) and tools/trace.lua as its
autoboot script. Tracing runs well below full speed, so separate scenarios are best run
side by side in separate shells. The MCU is not traced unless asked for (--cpus): its
code is already fully classified.

Cheats (tools/cheats.lua), in the recording and in its replay alike: --round N starts every
game on round N; --boss-hits N starts the round 100 boss with N of its 80 hits taken (80:
it is beaten as soon as it drifts to the middle). A recording keeps its cheats in
<name>.cheats beside the .inp.

"play" first opens a normal MAME window and records your inputs (-record) until you
close it, then traces a headless replay of that recording (-playback). --inp traces an
earlier recording again.

Output, in build/traces/<scenario>/ (or --name):
  coverage.json  every instruction address executed, per CPU image (bank0..3 for 8000-BFFF)
  access.csv     cpu, address, R/W, instruction address, count, for RAM and I/O
  sound.csv      every write to the sound latch FA00: frame, instruction address, value
  sprites.csv    every 16 x 16 sprite drawn through 147D / 149C: caller, gfx_num, tile bank,
                 first tile, attribute, count (read by tools/sprites.py)
  snap/          with --snap N: a screenshot every N seconds, and ram_<frame>.bin, the
                 main CPU's C000-FFFF at the same moment

MAME_DIR in config.local.toml gives the folder holding mame.exe. The ROMs come from the
same place as romset.py (ROM_DIR, else roms/).
"""

import argparse
import json
import random
import re
import shutil
import subprocess
import sys
import time
import tomllib
from pathlib import Path

import romset

ROOT = romset.ROOT
OUT_DIR = ROOT / "build" / "traces"
FPS = 60  # close enough to the 59.19 Hz refresh for scheduling inputs

# tag, short name, trace?, tapped ranges (inclusive)
CPUS = [
    ("maincpu", "main", True, [(0xC000, 0xFFFF)]),
    ("subcpu", "sub", True, [(0xE000, 0xF7FF)]),
    ("audiocpu", "sound", True, [(0x8000, 0xBFFF)]),
    ("mcu", "mcu", True, []),  # its shared RAM goes through ports, so taps would see nothing
]
DEFAULT_CPUS = "main,sub,sound"

LINE = re.compile(r"([0-9A-F]{4,}): ")
BANK = re.compile(r"B([0-9A-F]{2})$")


def press(events, frame, port, name, hold=4):
    events.append({"f": frame, "port": port, "field": name, "v": 1})
    events.append({"f": frame + hold, "port": port, "field": name, "v": 0})


def random_play(events, rng, start, end, player=1):
    """Wander left and right, blow bubbles and jump, at random."""
    port = ":IN1" if player == 1 else ":IN2"
    p = f"P{player} "
    f = start
    while f < end:
        hold = rng.randint(10, 60)
        side = rng.choice(["Left", "Right", None, None])
        if side:
            events.append({"f": f, "port": port, "field": p + side, "v": 1})
            events.append({"f": f + hold, "port": port, "field": p + side, "v": 0})
        for g in range(f, f + hold, 6):
            if rng.random() < 0.35:
                press(events, g, port, p + "Button 1", 3)
            if rng.random() < 0.15:
                press(events, g, port, p + "Button 2", 3)
        f += hold + 1


def coin_and_start(events, frame, players=1):
    for i in range(players):
        press(events, frame + 30 * i, ":IN0", "Coin 1", 6)
    if players == 1:
        press(events, frame + 120, ":IN1", "1 Player Start", 6)
    else:
        press(events, frame + 120, ":IN2", "2 Players Start", 6)


def write_cfg(folder: Path, dips: dict) -> None:
    """A MAME cfg holding only these DIP settings: {(port, mask): (default, value)}.
    MAME reads it at start, so the game boots with them, and the user's own cfg is not used."""
    folder.mkdir(parents=True, exist_ok=True)
    lines = ['<?xml version="1.0"?>', '<mameconfig version="10">',
             '    <system name="bublbobl">', "        <input>"]
    lines += [f'            <port tag="{port}" type="DIPSWITCH" mask="{mask}" '
              f'defvalue="{d}" value="{v}" />' for (port, mask), (d, v) in dips.items()]
    lines += ["        </input>", "    </system>", "</mameconfig>", ""]
    (folder / "bublbobl.cfg").write_text("\n".join(lines))


MODE_TEST_GRID = {(":DSW0", 0x05): (0x04, 0x01)}  # Mode: Game, English -> Test (Grid and Inputs)
MODE_TEST_RAM = {(":DSW0", 0x05): (0x04, 0x00)}   # -> Test (RAM and Sound)/Pause


def scenario(name, seconds, seed):
    """Return (events, default seconds, interactive, DIP settings)."""
    rng = random.Random(seed)
    ev = []
    if name == "attract":
        return ev, 150, False, {}
    if name in ("game1p", "game2p"):
        players = 1 if name == "game1p" else 2
        total = (seconds or 600) * FPS
        coin_and_start(ev, 5 * FPS, players)
        # Coin and start again every 20 s: continues after a death, a new game after game over.
        for f in range(30 * FPS, total, 20 * FPS):
            coin_and_start(ev, f, players)
        for p in range(1, players + 1):
            random_play(ev, rng, 8 * FPS, total, p)
        return ev, 600, False, {}
    if name == "super1p":
        # The title (from boot to about frame 450) takes 8 changes of P1's inputs, compared
        # at 1BF6 with the codes at 1CBE. This one is the super mode's: Start, Jump, Bubble,
        # Left, Right, Jump, Start, Right. Start on the title does not start a game.
        total = (seconds or 120) * FPS
        f = 2 * FPS
        for field in ["1 Player Start", "P1 Button 2", "P1 Button 1", "P1 Left",
                      "P1 Right", "P1 Button 2", "1 Player Start", "P1 Right"]:
            press(ev, f, ":IN1", field, 4)
            f += 10
        coin_and_start(ev, 10 * FPS)
        # SELECT GAME MODE (2931) waits up to 0x4B0 frames: Right picks the super mode and
        # either button starts.
        for g in range(13 * FPS, 22 * FPS, FPS):
            press(ev, g, ":IN1", "P1 Right", 4)
        press(ev, 24 * FPS, ":IN1", "P1 Button 1", 4)
        random_play(ev, rng, 26 * FPS, total)
        return ev, 120, False, {}
    if name == "testgrid":
        f = 5 * FPS
        for port, field in [(":IN0", "Coin 1"), (":IN0", "Coin 2"), (":IN0", "Service 1"),
                            (":IN0", "Tilt"), (":IN1", "P1 Left"), (":IN1", "P1 Right"),
                            (":IN1", "P1 Button 1"), (":IN1", "P1 Button 2"),
                            (":IN1", "1 Player Start"), (":IN2", "P2 Left"),
                            (":IN2", "P2 Right"), (":IN2", "P2 Button 1"),
                            (":IN2", "P2 Button 2"), (":IN2", "2 Players Start")]:
            press(ev, f, port, field, 30)
            f += FPS
        return ev, 30, False, MODE_TEST_GRID
    if name == "testram":
        return ev, 60, False, MODE_TEST_RAM
    if name == "play":
        return ev, 0, True, {}
    raise SystemExit(f"unknown scenario {name!r}; try --list")


SCENARIOS = {
    "attract": "attract mode, no inputs (150 s)",
    "game1p": "coin, 1P start, random play, re-coin every 20 s (600 s)",
    "game2p": "coins, 2P start, random play for both (600 s)",
    "super1p": "the super mode code on the title, coin, 1P start, super mode, random play (120 s)",
    "testgrid": "DSW mode 'Test (Grid and Inputs)', every input pressed in turn (30 s)",
    "testram": "DSW mode 'Test (RAM and Sound)/Pause' (60 s)",
    "play": "record your own play in a MAME window, then trace the replay",
}


def lua_value(v) -> str:
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return repr(v)
    if isinstance(v, str):
        return '"' + v.replace("\\", "/").replace('"', '\\"') + '"'
    if isinstance(v, dict):
        return "{" + ", ".join(f"{k}={lua_value(x)}" for k, x in v.items()) + "}"
    return "{" + ", ".join(lua_value(x) for x in v) + "}"


def mame_exe() -> Path:
    cfg = ROOT / "config.local.toml"
    mame_dir = tomllib.loads(cfg.read_text()).get("MAME_DIR") if cfg.exists() else None
    exe = Path(mame_dir) / "mame.exe" if mame_dir else None
    if exe and exe.exists():
        return exe
    found = shutil.which("mame")
    if not found:
        raise SystemExit("mame not found: set MAME_DIR in config.local.toml")
    return Path(found)


class Coverage:
    """Instruction addresses per image, read from the debugger trace files."""

    def __init__(self):
        self.pcs = {name: set() for _, name, _, _ in CPUS}
        self.banks = {f"bank{i}": set() for i in range(4)}
        self.page = None  # main CPU bank page, carried from file to file
        self.lines = 0

    def read(self, path: Path, cpu: str) -> None:
        main = cpu == "main"
        pcs = self.pcs[cpu]
        with path.open("r", errors="replace") as f:
            for line in f:
                m = LINE.match(line)
                if m:
                    pc = int(m.group(1), 16)
                    if main and 0x8000 <= pc < 0xC000:
                        if self.page is None or self.page > 3:
                            pcs.add(pc | 0x10000)  # bank unknown or empty socket
                        else:
                            self.banks[f"bank{self.page}"].add(pc)
                    else:
                        pcs.add(pc)
                    self.lines += 1
                elif main:
                    b = BANK.match(line.strip())
                    if b:
                        self.page = (int(b.group(1), 16) ^ 4) & 7
        path.unlink()

    def as_json(self) -> dict:
        out = {}
        for name, s in self.pcs.items():
            key = "main_fixed" if name == "main" else name
            out[key] = [f"{pc:04X}" for pc in sorted(p for p in s if p < 0x10000)]
            unknown = sorted(p & 0xFFFF for p in s if p >= 0x10000)
            if unknown:
                out["main_bank_unknown"] = [f"{pc:04X}" for pc in unknown]
        for name, s in self.banks.items():
            out[f"main_{name}"] = [f"{pc:04X}" for pc in sorted(s)]
        return out


def drain(out: Path, cov: Coverage, final: bool) -> None:
    """Read every finished trace file. A CPU's newest file is still open unless final."""
    for _, name, trace, _ in CPUS:
        if not trace or not any(out.glob(f"{name}_*.log")):
            continue
        files = sorted(out.glob(f"{name}_*.log"))
        if not final:
            files = files[:-1]
        for path in files:
            cov.read(path, name)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("scenario", nargs="?")
    ap.add_argument("--seconds", type=int, help="override the scenario's length")
    ap.add_argument("--seed", type=int, default=1, help="seed for random play")
    ap.add_argument("--chunk", type=int, default=60, help="frames per trace file")
    ap.add_argument("--no-reads", action="store_true", help="tap writes only (faster)")
    ap.add_argument("--keep", action="store_true", help="keep the raw trace files")
    ap.add_argument("--cpus", default=DEFAULT_CPUS, help=f"CPUs to trace (default {DEFAULT_CPUS})")
    ap.add_argument("--name", help="output folder under build/traces (default: the scenario)")
    ap.add_argument("--snap", type=int, default=0, help="screenshot and RAM dump every N seconds")
    ap.add_argument("--inp", type=Path, help="play: trace this recording instead of a new one")
    ap.add_argument("--round", type=int, help="start each game on this round (1-100)")
    ap.add_argument("--boss-hits", type=int, help="hits the round 100 boss has taken at the start (0-80)")
    ap.add_argument("--list", action="store_true", help="list the scenarios")
    args = ap.parse_args()
    if args.list or not args.scenario:
        for k, v in SCENARIOS.items():
            print(f"  {k:9} {v}")
        return 0

    events, default_s, interactive, dips = scenario(args.scenario, args.seconds, args.seed)
    seconds = args.seconds if args.seconds is not None else default_s
    events.sort(key=lambda e: e["f"])
    out = OUT_DIR / (args.name or args.scenario)
    if (out / "progress").exists() and not (out / "done").exists()             and time.time() - (out / "progress").stat().st_mtime < 30:
        raise SystemExit(f"{out} is in use by a running trace; pick another --name")
    out.mkdir(parents=True, exist_ok=True)
    for old in out.iterdir():
        if old.is_dir():
            if old.name != "cfg" or not args.inp:
                shutil.rmtree(old)
        elif old.suffix not in (".inp", ".round", ".cheats"):
            old.unlink()
    traced = set(args.cpus.split(","))
    if args.snap:
        (out / "snap").mkdir()

    cfg = {
        "out": str(out),
        "frames": seconds * FPS,
        "start": 1,
        "chunk": args.chunk,
        "snap": args.snap * FPS,
        "reads": not args.no_reads,
        "cpus": [{"tag": t, "name": n, "trace": tr and n in traced, "main": n == "main",
                  "taps": [[lo, hi] for lo, hi in taps]} for t, n, tr, taps in CPUS],
        "events": events,
    }
    # A recording keeps its cheats beside it (<name>.cheats; older ones <name>.round), so
    # its replay plays the same game.
    inp = (args.inp.resolve() if args.inp else out / "play.inp") if interactive else None
    cheats = {"round": args.round, "boss_hits": args.boss_hits}
    if args.inp and inp.with_suffix(".cheats").exists():
        saved = json.loads(inp.with_suffix(".cheats").read_text())
        cheats = {k: v if v is not None else saved.get(k) for k, v in cheats.items()}
    elif args.inp and cheats["round"] is None and inp.with_suffix(".round").exists():
        cheats["round"] = int(inp.with_suffix(".round").read_text())
    cheats = {"round": cheats["round"] or 1, "boss_hits": cheats["boss_hits"] or 0}
    if not 1 <= cheats["round"] <= 100:
        raise SystemExit("--round must be 1-100")
    if not 0 <= cheats["boss_hits"] <= 80:
        raise SystemExit("--boss-hits must be 0-80")
    cfg.update(cheats)
    cheats_lua = (ROOT / "tools" / "cheats.lua").read_text()
    script = out / "trace_run.lua"
    script.write_text("CFG = " + lua_value(cfg) + "\n\n" + cheats_lua + "\n"
                      + (ROOT / "tools" / "trace.lua").read_text(), encoding="utf-8")

    exe = mame_exe()
    rompath = romset.default_rom_dir()
    rompath = rompath.parent if rompath.name.startswith("bublbobl") else rompath
    if not (interactive and args.inp):
        write_cfg(out / "cfg", dips)
    common = [str(exe), "bublbobl", "-rompath", str(rompath), "-skip_gameinfo",
              "-input_directory", str(out), "-cfg_directory", str(out / "cfg"),
              "-nvram_directory", str(out / "nvram")]
    argv = common + ["-snapshot_directory", str(out), "-snapname", "snap/%i", "-debug", "-debugger", "none", "-autoboot_script", str(script),
                     "-video", "none", "-sound", "none", "-nothrottle"]
    if interactive:
        if not args.inp:
            record = common + ["-window", "-record", inp.name]
            if cheats != {"round": 1, "boss_hits": 0}:
                rec_script = out / "record.lua"
                rec_script.write_text("CFG = " + lua_value(cheats) + "\n\n" + cheats_lua,
                                      encoding="utf-8")
                record += ["-autoboot_script", str(rec_script)]
                inp.with_suffix(".cheats").write_text(json.dumps(cheats) + "\n")
            print("Recording: play, then close MAME to start the trace.", flush=True)
            subprocess.run(record, cwd=exe.parent,
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if not inp.exists():
            raise SystemExit(f"no recording at {inp}")
        argv[argv.index("-input_directory") + 1] = str(inp.parent)
        argv[argv.index("-cfg_directory") + 1] = str(inp.parent / "cfg")  # as recorded
        argv += ["-playback", inp.name, "-exit_after_playback"]
    print(f"{args.scenario}: {seconds or 'to the end of the recording'} s -> {out}", flush=True)
    cov = Coverage()
    started = time.time()
    proc = subprocess.Popen(argv, cwd=exe.parent, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, text=True)
    log = []
    while proc.poll() is None:
        if not args.keep:
            drain(out, cov, final=False)
        time.sleep(0.5)
    log = proc.stdout.read()
    (out / "mame.log").write_text(log)
    if not args.keep:
        drain(out, cov, final=True)
    if not (out / "done").exists():
        print(log[-2000:], file=sys.stderr)
        print("MAME stopped before the script finished", file=sys.stderr)
        return 1
    if args.keep:
        print("raw traces kept; coverage.json not written")
        return 0
    data = cov.as_json()
    (out / "coverage.json").write_text(json.dumps(data, indent=0))
    print(f"{cov.lines:,} trace lines in {time.time() - started:.0f} s")
    for k, v in data.items():
        print(f"  {k:18} {len(v):6} instructions")
    return 0


if __name__ == "__main__":
    sys.exit(main())
