"""The relocation test (EXTRACTION_PLAN 12.5): does the source still work when its code moves?

Usage: python tools/reloc.py IMAGE [IMAGE...] [--pad N] [--seconds N] [--seed N] [--no-run]
       python tools/reloc.py --list

For each IMAGE this copies its source to build/reloc/src/, puts N bytes of padding after the
fixed vectors and takes the same number out of the image's free space, so that everything
between the two moves up by N. The ROM's own integrity checks are left alone: the padding's
first byte is chosen to balance them. Nothing in src/ changes.

MAME then plays the same scripted inputs on the byte-exact set and on the moved set. Moving
code does not change how long it takes, so the two runs must show the same screen on every
sample. The first sample that differs is reported, and both pictures are written to
build/reloc/.

A moved ROM has the wrong CRC, which is the point: MAME's warning is expected.
"""

import argparse
import random
import shutil
import subprocess
import sys
from pathlib import Path

import build
import romset
import trace

ROOT = romset.ROOT
OUT = ROOT / "build" / "reloc"
SCREEN = 256 * 224 * 4  # bytes in one sample of the screen's pixels
EVERY = 15  # frames between samples

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

# every command the sound CPU has (tools/sounddec.py), and the frames between them. Not 2E: it
# plays its own table as phrases, through "pointers" made of a count byte and half a pointer,
# so what it plays depends on where things are (notes/sound.md). Play never sends it; only the
# test screen's sound picker (F449) might.
SOUND_COMMANDS = [c for c in (*range(0x01, 0x35), 0xF2, 0xF4, 0xF6, 0xF8) if c != 0x2E]
SOUND_GAP = 900


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


def build_moved(names: list[str], pad: int) -> Path:
    """Write the full set to build/reloc/roms/bublbobl/ with these images moved."""
    roms = OUT / "roms" / "bublbobl"
    roms.mkdir(parents=True, exist_ok=True)
    for f in (ROOT / "build" / "roms" / "bublbobl").iterdir():
        shutil.copy(f, roms / f.name)
    for name in names:
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
    return OUT / "roms"


def scenario(seconds: int, seed: int) -> tuple[list[dict], int]:
    """Attract mode, then a one-player game of random play. Returns (events, frames)."""
    frames = seconds * 60
    rng = random.Random(seed)
    events: list[dict] = []
    start = min(frames // 3, 2400)
    trace.coin_and_start(events, start)
    trace.random_play(events, rng, start + 300, frames)
    return sorted(events, key=lambda e: e["f"]), frames


def run_mame(label: str, rompath: Path, events: list[dict], frames: int) -> Path:
    folder = OUT / label
    if folder.exists():
        shutil.rmtree(folder)
    folder.mkdir(parents=True)
    samples = folder / "screen.bin"
    cfg = {"out": str(samples), "frames": frames, "every": EVERY, "events": events}
    script = folder / "run.lua"
    script.write_text("CFG = " + trace.lua_value(cfg) + "\n\n"
                      + (ROOT / "tools" / "reloc.lua").read_text(), encoding="utf-8")
    exe = trace.mame_exe()
    argv = [str(exe), "bublbobl", "-rompath", str(rompath), "-skip_gameinfo",
            "-cfg_directory", str(folder / "cfg"), "-nvram_directory", str(folder / "nvram"),
            "-autoboot_script", str(script), "-video", "none", "-sound", "none", "-nothrottle"]
    result = subprocess.run(argv, cwd=exe.parent, capture_output=True, text=True)
    (folder / "mame.log").write_text(result.stdout + result.stderr)
    if not samples.exists() or samples.stat().st_size < SCREEN:
        raise SystemExit(f"{label}: no pictures from MAME; see {folder / 'mame.log'}")
    return samples


def run_sound(label: str, rompath: Path) -> Path:
    """Every sound command from silence, as tools/soundcmp.py. Returns the register log."""
    folder = OUT / label
    if folder.exists():
        shutil.rmtree(folder)
    folder.mkdir(parents=True)
    log = folder / "regs.csv"
    cfg = {"cmds": SOUND_COMMANDS, "start": 600, "gap": SOUND_GAP, "out": str(log)}
    script = folder / "run.lua"
    script.write_text("CFG = " + trace.lua_value(cfg) + chr(10)
                      + (ROOT / "tools" / "soundlog.lua").read_text(), encoding="utf-8")
    exe = trace.mame_exe()
    argv = [str(exe), "bublbobl", "-rompath", str(rompath), "-skip_gameinfo",
            "-cfg_directory", str(folder / "cfg"), "-nvram_directory", str(folder / "nvram"),
            "-autoboot_script", str(script), "-video", "none", "-sound", "none", "-nothrottle"]
    result = subprocess.run(argv, cwd=exe.parent, capture_output=True, text=True)
    (folder / "mame.log").write_text(result.stdout + result.stderr)
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


def compare(base: Path, moved: Path) -> bool:
    a, b = base.read_bytes(), moved.read_bytes()
    count = min(len(a), len(b)) // SCREEN
    for i in range(count):
        x, y = a[i * SCREEN:(i + 1) * SCREEN], b[i * SCREEN:(i + 1) * SCREEN]
        if x != y:
            picture(x, OUT / "differs_base.png")
            picture(y, OUT / "differs_moved.png")
            print(f"DIFFERENT at sample {i} of {count}, frame {(i + 1) * EVERY}; "
                  f"see {OUT}/differs_*.png")
            return False
    if len(a) != len(b):
        print(f"DIFFERENT lengths: {len(a) // SCREEN} and {len(b) // SCREEN} samples")
        return False
    print(f"Same screen on all {count} samples, every {EVERY} frames")
    return True


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("images", nargs="*")
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--pad", type=int, default=16)
    ap.add_argument("--seconds", type=int, default=120)
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--no-run", action="store_true", help="build the moved set only")
    args = ap.parse_args()
    if args.list or not args.images:
        print("\n".join(IMAGES))
        return 0
    for name in args.images:
        if name not in IMAGES:
            raise SystemExit(f"no image {name}: try --list")
    rompath = build_moved(args.images, args.pad)
    if args.no_run:
        return 0
    ok = True
    if any(IMAGES[n].get("check") == "sound" for n in args.images):
        ok = compare_sound(run_sound("sound_base", ROOT / "build" / "roms"),
                           run_sound("sound_moved", rompath))
    events, frames = scenario(args.seconds, args.seed)
    base = run_mame("base", ROOT / "build" / "roms", events, frames)
    moved = run_mame("moved", rompath, events, frames)
    return 0 if compare(base, moved) and ok else 1


if __name__ == "__main__":
    sys.exit(main())
