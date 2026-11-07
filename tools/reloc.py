"""The relocation test (notes/relocation.md): does the source still work when its code moves?

Usage: python tools/reloc.py IMAGE [IMAGE...] [--pad N] [--seconds N] [--seed N] [--no-run]
                             [--scenario NAME] [--round N|N-M] [--special K|K-L] [--clear]
                             [--boss-hits N] [--boss-pop] [--jobs N]
       python tools/reloc.py --list

For each IMAGE this copies its source to build/reloc/src/, puts N bytes of padding after the
fixed vectors and takes the same number out of the image's free space, so that everything
between the two moves up by N. The ROM's own integrity checks are left alone: the padding's
first byte is chosen to balance them. Nothing in src/ changes.

MAME then plays the same scripted inputs on the byte-exact set and on the moved set, and the
two runs must show the same screen on every sample. Moving the sub CPU, MCU or sound code does
not change how long it takes. Moving the main CPU's would, so both of its sets are built with
the sites in CARRY_SITE made constant (notes/relocation.md). Every sample that differs is
reported, and the pictures of the first are written beside the moved run's samples. A machine
reset during a run is a failure.

--scenario plays one of tools/trace.py's scenarios instead of the one-player game: game2p,
testgrid, testram, testsound and so on, with their DIP switches.

--round runs that game on each round asked for, through tools/cheats.lua, side by side in
build/reloc/rounds/. --special does the same for each special item kind, on each --round, in
build/reloc/specials/; kinds 31-33 are the secret room's doors. A run that never reached its
round, never took its item or never entered the room is a failure, and a pair that passes keeps
only its logs.

A moved ROM has the wrong CRC, which is the point: MAME's warning is expected.
"""

import argparse
import concurrent.futures
import random
import re
import shutil
import subprocess
import sys
from pathlib import Path

import build
import mainptrs
import romset
import trace

ROOT = romset.ROOT
OUT = ROOT / "build" / "reloc"
SCREEN = 256 * 224 * 4  # bytes in one sample of the screen's pixels
EVERY = 15  # frames between samples
MAME_LIMIT = 600  # seconds; two minutes of play takes about five

# IMAGE -> the source, the label the padding goes before, the .incbin of free space it comes
# out of (file, offset, length), the ROM file, and the sum over the whole ROM to keep at 0:
# "byte", "word" (big-endian) or None.
IMAGES = {
    "sub": {"source": "sub/sub.s", "before": "VBLANK:", "fill": ('"sub.bin"', 0x7FBC, 0x44),
            "rom": "a78-08.37", "sum": "byte"},
    # the date stamp is the only thing here nothing reads; ROM_SUM starts at RESET_VEC
    "mcu": {"source": "mcu/mcu.s", "before": "COLD_START:", "fill": ('"mcu.bin"', 0x0FDF, 0x11),
            "rom": "a78-01.17", "sum": "word"},
    # the end of this range is 0 fill from 7D9A; the screen shows nothing of it, so "check" asks
    # for the chips' register writes instead
    "sound": {"source": "sound/sound.s", "before": "SOUND_START:", "fill": ('"sound.bin"', 0x7D83, 0x27D),
              "rom": "a78-07.46", "sum": None, "check": "sound"},
}

# The main CPU's five images move together. Each has no free space where the padding is wanted,
# so it comes out of a block nothing runs or reads ("cut": address, then how many pads' worth),
# and "pads" are the lines it goes before. A pad at both ends with the cut in the middle moves the
# first half up and the second half down, so every label changes. None means the end of the file.
# STEP_TO_8_DOWN runs off the end of the fixed ROM into bank 0 (`and 0x07` is split between 7FFF
# and 8000, and the routine ends at 8008), so those bytes cannot move.
MAIN_LAYOUT = {
    # 475B is 0xB4 bytes of orphaned code: never run or read, and nothing points at it
    "fixed": {"pads": ["SCHEDULER:", "STEP_TO_8_DOWN:"], "cut": (0x475B, 2)},
    # ENEMY3_WALK_THINK: never run, and nothing points at it
    "bank0": {"pads": ["B0_DATA_8009:", None], "cut": (0x97EC, 2)},
    "bank1": {"pads": ["PALETTES:"], "cut": (0xB85C, 1)},  # 0xFF fill
    "bank2": {"pads": ["TEST_MODE:"], "cut": (0xBC46, 1)},  # after the last thing anything points at
    "bank3": {"pads": ["B3_TILES_8000:"], "cut": (0xBF1A, 1)},  # 0xFF fill
}
MAIN_ROMS = {"a78-06-1.51": ["main/fixed.s"],
             "a78-05-1.52": ["main/bank0.s", "main/bank1.s", "main/bank2.s", "main/bank3.s"]}
# the end of each of the 23 ROM sums: `ld a,(EXPECTED)`, `ld hl,SUM`, `cp (hl)`
SUM_END = re.compile(r"(ld      a,\()(\w+)(\)\n\s+ld      hl,)(\w+)(\n\s+cp      \(hl\)\n\s+ret     z)")
ROM_SUMS = 23
# SPAWN_BUBBLE calls GRID_CELL with the HL that RAND_TIMER_SET leaves, DATA_622A + SPEED2_SEL, and
# not the bubble's position, so a bubble from the gaps starts with the current of a cell chosen by
# the table's address (notes/levels.md). Moved, the same bubble drifts another way. For the test
# GRID_CELL gets what HL held at the table's true address, in both sets, through this routine,
# which goes in the cut.
CELL_CALL = "call    RAND_TIMER_SET\n        call    GRID_CELL\n"
CELL_FIX = ["RELOC_CELL:", "        ld      de,DATA_622A", "        or      a", "        sbc     hl,de",
            "        ld      de,0x622A", "        add     hl,de", "        jp      GRID_CELL"]
CELL_FIX_SIZE = 13
# A + the low byte of a pair, carrying into the high byte, takes longer and runs one more
# instruction when the sum crosses a page. So moving a table changes the main CPU's timing, which
# decides the race in notes/relocation.md, and R, which is the game's random numbers (`ld a,r`).
# In both sets these sites call a routine that takes the same time either way, so whatever still
# differs is a fault. It leaves the pair and A as the original does, but not the flags. The
# reference set is the same build with a pad of 0.
CARRY_SITE = re.compile(r" +add +a,([lec])\n +ld +\1,a\n +(?:(ret +nc)|(jr|jp) +nc,\w+)\n +inc +[hdb]\n( +ret\n)?")
CARRY_SITES = 7
CARRY_PAIRS = {"l": "h", "e": "d", "c": "b"}
CARRY_FIX = [line for low, high in CARRY_PAIRS.items() for line in (
    f"RELOC_ADD_{low}:", f"        add     a,{low}", f"        ld      {low},a", "        ld      a,0",
    f"        adc     a,{high}", f"        ld      {high},a", f"        ld      a,{low}", "        ret")]
CARRY_FIX_SIZE = 24
IDLE = 0x01ED  # where tools/soundlog.lua parks the main CPU; the first pad comes before it

# every command the sound CPU has (tools/sounddec.py), and the frames between them. Not 2E: it
# plays its own table as phrases, through "pointers" made of a count byte and half a pointer,
# so what it plays depends on where things are (notes/sound.md). Play never sends it; only the
# test screen's sound picker (F449) might.
SOUND_COMMANDS = [c for c in (*range(0x01, 0x35), 0xF2, 0xF4, 0xF6, 0xF8) if c != 0x2E]
SOUND_GAP = 900
# what tools/cheats.lua waits for, in the byte-exact build
CHEAT_PCS = {"round": ("fixed", 0x1DCD), "boss": ("fixed", 0x0D50), "pop": ("bank0", 0xA972),
             "pick": ("bank2", 0x85EB), "pick_item": ("bank2", 0x863A), "pick_end": ("bank2", 0x8667)}
SECRET_DOORS = (0x31, 0x32, 0x33)  # the special kinds that open the secret room
SECRET_ROUND = 0x65  # ROUND_MAIN in the room


def moved_source(cfg: dict, pad: int) -> str:
    """The image's source with `pad` bytes added before its label and taken out of its fill."""
    text = (ROOT / "src" / cfg["source"]).read_text(encoding="utf-8")
    name, offset, length = cfg["fill"]
    if pad > length:
        raise SystemExit(f"{cfg['source']}: only {length} bytes of free space")
    fill = f".incbin {name}, 0x{offset:04X}, 0x{length:04X}"
    lines = text.split("\n")
    at = [i for i, line in enumerate(lines) if line.startswith(cfg["before"])]
    full = [i for i, line in enumerate(lines) if line.strip().startswith(fill)]
    if len(at) != 1 or len(full) != 1:
        raise SystemExit(f"{cfg['source']}: cannot find {cfg['before']} or {fill}")
    # from the end of the range, which may start with data; a length of 0 would mean "to the
    # end of the file"
    lines[full[0]] = f"        .incbin {name}, 0x{offset:04X}, 0x{length - pad:04X}" if pad < length else ""
    lines[at[0]:at[0]] = ["RELOC_PAD:", f"        .fill   {pad}, 1, 0xFF"]
    return "\n".join(lines)


def cut_lines(src: list[str], image: str, addr: int, size: int) -> None:
    """Take `size` bytes out of `src` from addr on, whole instructions at a time."""
    lines = mainptrs.listing(image)
    i = next(n for n, x in enumerate(lines) if x.addr <= addr < x.addr + x.size)
    left = size
    extra = 0
    while left > 0:
        x = lines[i]
        n = x.number - 1
        if m := re.search(r'\.incbin ("[^"]+"), 0x(\w+), 0x(\w+)', x.text):
            offset, length = int(m[2], 16), int(m[3], 16)
            skip = addr - x.addr if addr > x.addr else 0
            take = min(left, length - skip)
            parts = []
            if skip:
                parts.append(f"        .incbin {m[1]}, 0x{offset:04X}, 0x{skip:04X}")
            if length - skip - take:
                parts.append(f"        .incbin {m[1]}, 0x{offset + skip + take:04X}, 0x{length - skip - take:04X}")
            src[n] = "\n".join(parts)
            left -= take
        else:
            src[n] = ""
            left -= x.size
            extra = max(0, -left)
        i += 1
    if extra:  # the last instruction was longer than what was left to take
        src[lines[i - 1].number - 1] = f"        .fill   {extra}, 1, 0xFF"


def constant_time(site: re.Match) -> str:
    """A CARRY_SITE as a call to its routine, in the same number of bytes."""
    low, returns, jump, _ = site.groups()
    call = f"        {'jp  ' if returns else 'call'}    RELOC_ADD_{low}\n"
    return call + "        nop\n" * (3 if jump == "jp" else 2)


def moved_main(image: str, pad: int) -> str:
    """One main image's source with its pads added, its cut taken and its ROM sums made to pass."""
    cfg = MAIN_LAYOUT[image]
    src = (ROOT / "src" / "main" / f"{image}.s").read_text(encoding="utf-8").split("\n")
    addr, pads = cfg["cut"]
    fix = image == "fixed"
    cut_lines(src, image, addr, pad * pads + (CELL_FIX_SIZE + CARRY_FIX_SIZE if fix else 0))
    if fix:
        at = next(x for x in mainptrs.listing(image) if x.addr <= addr < x.addr + x.size).number - 1
        src[at] = "\n".join([*CELL_FIX, *CARRY_FIX, src[at]])
    for n, where in enumerate(cfg["pads"]):
        block = [f"RELOC_PAD_{n}:", f"        .fill   {pad}, 1, 0xFF"]
        if where is None:
            src += block
            continue
        at = [i for i, line in enumerate(src) if line.strip().startswith(where)]
        if len(at) != 1:
            raise SystemExit(f"{image}: {where}: {len(at)} matches")
        src[at[0]:at[0]] = block
    text = "\n".join(src)
    if fix:
        if text.count(CELL_CALL) != 1:
            raise SystemExit("cannot find SPAWN_BUBBLE's GRID_CELL")
        text = text.replace(CELL_CALL, CELL_CALL.replace("GRID_CELL", "RELOC_CELL"))
        text, sites = CARRY_SITE.subn(constant_time, text)
        if sites != CARRY_SITES:
            raise SystemExit(f"found {sites} carry sites, expected {CARRY_SITES}")
    return text


def neutral_sums(text: str) -> tuple[str, int]:
    """Each ROM sum compares with itself: the same size and time as the original, so nothing
    else moves. The sums cannot be balanced, as they overlap."""
    return SUM_END.subn(lambda m: m[1] + m[4] + m[3] + m[4] + m[5], text)


def build_main(pad: int, roms: Path) -> None:
    total = 0
    for image in MAIN_LAYOUT:
        path = OUT / "src" / "main" / f"{image}.s"
        path.parent.mkdir(parents=True, exist_ok=True)
        text, n = neutral_sums(moved_main(image, pad))
        total += n
        path.write_text(text, encoding="utf-8", newline="\n")
    if total != ROM_SUMS:
        raise SystemExit(f"found {total} ROM sums, expected {ROM_SUMS}")
    built = build.assemble("build/reloc/src", "build/reloc/obj", build.MAIN)
    for rom, sources in MAIN_ROMS.items():
        data = b"".join(built[src] for src in sources)
        if len(data) != romset.ROMS[rom][0]:
            raise SystemExit(f"{rom}: built {len(data):#x} bytes, expected {romset.ROMS[rom][0]:#x}")
        (roms / rom).write_bytes(data)
    print(f"main: moved by {pad}, in both directions")


def pad_address(cfg: dict) -> int:
    """Where the padding lands: the address noted on the label it goes before."""
    text = (ROOT / "src" / cfg["source"]).read_text(encoding="utf-8")
    for line in text.split("\n"):
        if line.startswith(cfg["before"]):
            return int(line.split(";")[1].strip(), 16)
    raise SystemExit("no address on the padding's label")


def balance(data: bytearray, at: int, kind: str) -> None:
    """Set the padding at offset `at` so that the ROM sums to 0."""
    if kind == "byte":
        data[at] = 0
        data[at] = -sum(data) & 0xFF
    else:
        at += at & 1  # the first whole word of the padding
        data[at:at + 2] = bytes(2)
        total = sum(data[i] << 8 | data[i + 1] for i in range(0, len(data), 2))
        data[at:at + 2] = (-total & 0xFFFF).to_bytes(2, "big")


def cheat_pcs() -> dict[str, int]:
    """Where the last main build put the code tools/cheats.lua waits for: the same distance past
    the same label as in the byte-exact build."""
    def symbols(obj_dir: str, image: str) -> dict[str, int]:
        src = f"main/{image}.s"
        tool = f"{build.binutils_dir()}/{build.SOURCES[src][1]}/bin/{build.SOURCES[src][0]}-"
        return build.read_symbols(tool, f"{obj_dir}/main_{image}", build.SOURCES[src][3])[0]

    pcs = {}
    for name, (image, pc) in CHEAT_PCS.items():
        old = symbols("build/obj", image)
        label = max((n for n, a in old.items() if a <= pc), key=old.get)
        pcs[name] = symbols("build/reloc/obj", image)[label] + pc - old[label]
    return pcs


def build_moved(names: list[str], pad: int, folder: str = "roms") -> Path:
    """Write the full set to build/reloc/<folder>/bublbobl/ with these images moved."""
    roms = OUT / folder / "bublbobl"
    roms.mkdir(parents=True, exist_ok=True)
    for f in (ROOT / "build" / "roms" / "bublbobl").iterdir():
        shutil.copy(f, roms / f.name)
    for name in names:
        if name == "main":
            build_main(pad, roms)
            continue
        cfg = IMAGES[name]
        path = OUT / "src" / cfg["source"]
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(moved_source(cfg, pad), encoding="utf-8", newline="\n")
        built = build.assemble("build/reloc/src", "build/reloc/obj", [cfg["source"]])[cfg["source"]]
        size = romset.ROMS[cfg["rom"]][0]
        if len(built) != size:
            raise SystemExit(f"{name}: built {len(built):#x} bytes, expected {size:#x}")
        data = bytearray(built)
        at = pad_address(cfg)
        if cfg["sum"]:
            balance(data, at - build.SOURCES[cfg["source"]][3], cfg["sum"])
        (roms / cfg["rom"]).write_bytes(data)
        print(f"{name}: moved by {pad} from {at:04X}")
    return OUT / folder


def scenario(seconds: int, seed: int) -> tuple[list[dict], int]:
    """Attract mode, then a one-player game of random play. Returns (events, frames)."""
    frames = seconds * 60
    rng = random.Random(seed)
    events: list[dict] = []
    start = min(frames // 3, 2400)
    trace.coin_and_start(events, start)
    trace.random_play(events, rng, start + 300, frames)
    return sorted(events, key=lambda e: e["f"]), frames


def chosen_play(name: str | None, seconds: int | None, seed: int) -> tuple[list[dict], int, dict]:
    """The game to play, as (events, frames, DIP switches): --scenario's, or the default."""
    if name is None:
        return *scenario(seconds or 120, seed), {}
    events, default, _, dips = trace.scenario(name, seconds, seed)
    return sorted(events, key=lambda e: e["f"]), (seconds or default) * trace.FPS, dips


def run_limited(argv: list[str], cwd: Path, folder: Path) -> None:
    """Run MAME, and stop if it outlasts MAME_LIMIT: a moved set that hangs is a failure."""
    try:
        result = subprocess.run(argv, cwd=cwd, capture_output=True, text=True, timeout=MAME_LIMIT)
    except subprocess.TimeoutExpired:
        raise SystemExit(f"{folder.name}: MAME still running after {MAME_LIMIT} seconds") from None
    (folder / "mame.log").write_text(f"{result.stdout}{result.stderr}\nexit code {result.returncode}\n")
    if result.returncode:
        raise SystemExit(f"{folder.name}: MAME stopped with exit code {result.returncode:#x}")


def run_mame(label: str, rompath: Path, events: list[dict], frames: int, cheats: dict | None = None,
             dips: dict | None = None) -> Path:
    folder = OUT / label
    if folder.exists():
        shutil.rmtree(folder)
    folder.mkdir(parents=True)
    samples = folder / "screen.bin"
    if dips:
        trace.write_cfg(folder / "cfg", dips)
    cfg = {"out": str(samples), "rounds": str(folder / "rounds.txt"), "items": str(folder / "items.txt"),
           "reset": str(folder / "reset"),
           "frames": frames, "every": EVERY, "events": events, **(cheats or {})}
    script = folder / "run.lua"
    lua = (ROOT / "tools" / "cheats.lua").read_text() + "\n" if cheats else ""
    script.write_text("CFG = " + trace.lua_value(cfg) + "\n\n" + lua
                      + (ROOT / "tools" / "reloc.lua").read_text(), encoding="utf-8")
    exe = trace.mame_exe()
    argv = [str(exe), "bublbobl", "-rompath", str(rompath), "-skip_gameinfo",
            "-cfg_directory", str(folder / "cfg"), "-nvram_directory", str(folder / "nvram"),
            "-autoboot_script", str(script), "-video", "none", "-sound", "none", "-nothrottle"]
    run_limited(argv, exe.parent, folder)
    if (folder / "reset").exists():
        raise SystemExit(f"{label}: the machine reset during the run")
    if not samples.exists() or samples.stat().st_size < SCREEN:
        raise SystemExit(f"{label}: no pictures from MAME; see {folder / 'mame.log'}")
    return samples


def run_sound(label: str, rompath: Path, idle: int = IDLE) -> Path:
    """Every sound command from silence, as tools/soundcmp.py. Returns the register log."""
    folder = OUT / label
    if folder.exists():
        shutil.rmtree(folder)
    folder.mkdir(parents=True)
    log = folder / "regs.csv"
    cfg = {"cmds": SOUND_COMMANDS, "start": 600, "gap": SOUND_GAP, "out": str(log), "idle": idle}
    script = folder / "run.lua"
    script.write_text("CFG = " + trace.lua_value(cfg) + chr(10)
                      + (ROOT / "tools" / "soundlog.lua").read_text(), encoding="utf-8")
    exe = trace.mame_exe()
    argv = [str(exe), "bublbobl", "-rompath", str(rompath), "-skip_gameinfo",
            "-cfg_directory", str(folder / "cfg"), "-nvram_directory", str(folder / "nvram"),
            "-autoboot_script", str(script), "-video", "none", "-sound", "none", "-nothrottle"]
    run_limited(argv, exe.parent, folder)
    if not log.exists():
        raise SystemExit(f"{label}: no register log from MAME; see {folder / 'mame.log'}")
    return log


def compare_sound(base: Path, moved: Path) -> bool:
    a, b = base.read_text().splitlines(), moved.read_text().splitlines()
    for i, (x, y) in enumerate(zip(a, b)):
        if x != y:
            print(f"DIFFERENT at register write {i} of {len(a)}: {x} and {y}")
            return False
    if len(a) != len(b):
        print(f"DIFFERENT lengths: {len(a)} and {len(b)} register writes")
        return False
    print(f"Same {len(a)} register writes, at the same times, for {len(SOUND_COMMANDS)} commands")
    return True


def picture(data: bytes, path: Path) -> None:
    from PIL import Image
    Image.frombytes("RGBA", (256, 224), data, "raw", "BGRA").convert("RGB").save(path)


def stretches(differs: list[int]) -> list[tuple[int, int]]:
    """The samples that differ as runs of neighbours: (first, last)."""
    runs: list[tuple[int, int]] = []
    for i in differs:
        if runs and i == runs[-1][1] + 1:
            runs[-1] = (runs[-1][0], i)
        else:
            runs.append((i, i))
    return runs


def compare(base: Path, moved: Path) -> bool:
    """Every sample must match; each stretch that does not is printed."""
    a, b = base.read_bytes(), moved.read_bytes()
    count = min(len(a), len(b)) // SCREEN
    differs = [i for i in range(count)
               if a[i * SCREEN:(i + 1) * SCREEN] != b[i * SCREEN:(i + 1) * SCREEN]]
    if differs:
        i = differs[0]
        picture(a[i * SCREEN:(i + 1) * SCREEN], moved.parent / "differs_base.png")
        picture(b[i * SCREEN:(i + 1) * SCREEN], moved.parent / "differs_moved.png")
        print(f"{len(differs)} of {count} samples differ; the first is in {moved.parent}/differs_*.png")
        for first, last in stretches(differs):
            print(f"  frames {(first + 1) * EVERY}-{(last + 1) * EVERY}: DIFFERENT")
    if len(a) != len(b):
        print(f"DIFFERENT lengths: {len(a) // SCREEN} and {len(b) // SCREEN} samples")
        return False
    if not differs:
        samples = [a[i * SCREEN:(i + 1) * SCREEN] for i in range(count)]
        ram = [s for s in samples if s[-1] == 0]  # a picture's last byte is alpha, FF; see reloc.lua
        print(f"Same screen on all {count} samples, every {EVERY} frames "
              f"({len(set(samples) - set(ram))} different pictures; {len(ram)} samples of video RAM instead, "
              f"{len(set(ram))} different)")
    return not differs


def number_list(text: str, low: int, high: int, name: str) -> list[int]:
    first, _, last = text.partition("-")
    numbers = list(range(int(first, 0), int(last or first, 0) + 1))
    if not numbers or not low <= numbers[0] <= numbers[-1] <= high:
        raise SystemExit(f"{name} must be within {low:#x}-{high:#x}")
    return numbers


def round_list(text: str) -> list[int]:
    return number_list(text, 1, 100, "--round")


def special_list(text: str) -> list[int]:
    return number_list(text, 1, 0x35, "--special")


def reached(samples: Path, start: int) -> list[int]:
    """The values ROUND_MAIN held from when the coin went in, in order."""
    lines = (samples.parent / "rounds.txt").read_text().split("\n")
    pairs = [tuple(map(int, line.split())) for line in lines if line]
    held = [value for frame, value in pairs if frame < start][-1:]
    return held + [value for frame, value in pairs if frame >= start]


def items_taken(samples: Path) -> list[str]:
    """Each time the special item showed and went, as "shown-gone" in frames."""
    return [line.replace(" ", "-") for line in (samples.parent / "items.txt").read_text().split("\n") if line]


def run_cases(cases: list[tuple[int, int]], reference: Path, rompath: Path, cheats: dict, pcs: tuple,
              play: tuple, jobs: int) -> bool:
    """The same game for each (round, special kind), on both sets, `jobs` runs at a time."""
    events, frames, dips = play
    start = min(e["f"] for e in events if e["field"].startswith("Coin"))

    def name(case: tuple[int, int]) -> str:
        n, kind = case
        return f"specials/{kind:02X}_{n:03}" if kind else f"rounds/{n:03}"

    def pair(case: tuple[int, int]) -> tuple[Path, Path]:
        chosen = {**cheats, "round": case[0], "special": case[1]}
        return (run_mame(f"{name(case)}/base", reference, events, frames, {**chosen, "pc": pcs[0]}, dips),
                run_mame(f"{name(case)}/moved", rompath, events, frames, {**chosen, "pc": pcs[1]}, dips))

    failed = []
    with concurrent.futures.ThreadPoolExecutor(jobs) as pool:
        running = {pool.submit(pair, case): case for case in cases}
        for done in concurrent.futures.as_completed(running):
            case = running[done]
            n, kind = case
            print(f"Round {n}" + (f", special {kind:02X}:" if kind else ":"), flush=True)
            try:
                base, moved = done.result()
            except SystemExit as stop:
                print(f"  FAILED: {stop}")
                failed.append(case)
                continue
            played = [reached(s, start) for s in (base, moved)]
            ok = compare(base, moved)
            if played[0] != played[1]:
                print(f"  DIFFERENT rounds: {played[0]} and {played[1]}")
                ok = False
            if n - 1 not in played[0]:
                print(f"  NOT REACHED: ROUND_MAIN took {played[0]}")
                ok = False
            print(f"  played {[v + 1 for v in played[0]]}", flush=True)
            if kind:
                taken = [items_taken(s) for s in (base, moved)]
                print(f"  item shown-gone {taken[0]}", flush=True)
                if taken[0] != taken[1]:
                    print(f"  DIFFERENT items: {taken[0]} and {taken[1]}")
                    ok = False
                if not taken[0]:
                    print("  NOT REACHED: the item never showed and went")
                    ok = False
                if kind in SECRET_DOORS and SECRET_ROUND not in played[0]:
                    print("  NOT REACHED: the secret room")
                    ok = False
            if ok:
                base.unlink()
                moved.unlink()
            else:
                failed.append(case)
    print(f"{len(cases) - len(failed)} of {len(cases)} runs passed"
          + (f"; failed: {sorted(failed)}" if failed else ""))
    return not failed


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("images", nargs="*")
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--pad", type=int, default=16)
    ap.add_argument("--seconds", type=int, help="default: 120, or the --scenario's own length")
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--no-run", action="store_true", help="build the moved set only")
    ap.add_argument("--scenario", choices=[n for n in trace.SCENARIOS if n != "play"],
                    help="play this trace.py scenario instead of the one-player game")
    ap.add_argument("--round", type=round_list, help="start each game on this round, or on each of N-M")
    ap.add_argument("--special", type=special_list, help="force this special item kind, or each of K-L")
    ap.add_argument("--clear", action="store_true", help="with --special: the round clears once the item is taken")
    ap.add_argument("--boss-hits", type=int, default=0, help="with --round: hits the round 100 boss has taken")
    ap.add_argument("--boss-pop", action="store_true", help="with --round: the boss's bubble pops at once")
    ap.add_argument("--jobs", type=int, default=8, help="with --round: MAME runs at a time")
    args = ap.parse_args()
    if args.list or not args.images:
        print("\n".join([*IMAGES, "main"]))
        return 0
    for name in args.images:
        if name not in IMAGES and name != "main":
            raise SystemExit(f"no image {name}: try --list")
    # main is compared with itself unmoved, as its sets have the constant sites: see CARRY_SITE
    moves_main = "main" in args.images
    reference = build_moved(["main"], 0, "ref_roms") if moves_main else ROOT / "build" / "roms"
    base_pcs = cheat_pcs() if moves_main else {name: pc for name, (_, pc) in CHEAT_PCS.items()}
    rompath = build_moved(args.images, args.pad)
    moved_pcs = cheat_pcs() if moves_main else base_pcs
    if args.no_run:
        return 0
    ok = True
    if any(n in IMAGES and IMAGES[n].get("check") == "sound" for n in args.images):
        ok = compare_sound(run_sound("sound_base", reference),
                           run_sound("sound_moved", rompath, IDLE + args.pad if "main" in args.images else IDLE))
    play = chosen_play(args.scenario, args.seconds, args.seed)
    if args.round or args.special:
        cases = [(n, kind) for n in args.round or [1] for kind in args.special or [0]]
        cheats = {"boss_hits": args.boss_hits, "boss_pop": args.boss_pop, "clear": args.clear}
        return 0 if run_cases(cases, reference, rompath, cheats, (base_pcs, moved_pcs), play, args.jobs) and ok else 1
    events, frames, dips = play
    base = run_mame("base", reference, events, frames, dips=dips)
    moved = run_mame("moved", rompath, events, frames, dips=dips)
    return 0 if compare(base, moved) and ok else 1


if __name__ == "__main__":
    sys.exit(main())
