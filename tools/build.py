"""Assemble src/ into a byte-exact bublbobl set and verify it.

Usage: python tools/build.py [--roms DIR]

Steps: verify the ROM set and write build/images/ (romset.py); write the symbol includes
to build/include/ (symbols.py); assemble and link each
source with GNU Binutils; join the banks; check every program ROM's CRC32 and SHA1;
write the full set (graphics and PROM copied as is) to build/roms/bublbobl/.

Binutils is run inside WSL on Windows. BINUTILS_DIR in config.local.toml overrides the
default install prefix, ~/bublbobl-tools (a path in WSL / Linux).
"""

import argparse
import hashlib
import os
import shlex
import subprocess
import sys
import tomllib
import zlib
from pathlib import Path, PurePosixPath

import romset
import symbols

ROOT = romset.ROOT
BUILD = ROOT / "build"
OBJ = BUILD / "obj"

# source -> (binutils target, tool dir under BINUTILS_DIR, as flags, link base)
Z80 = ("z80-elf", "z80", ["-march=z80+xyhl+sli+xdcb"])
M6801 = ("m68hc11-elf", "m6801", ["-m68hc11"])
SOURCES = {
    "main/fixed.s": (*Z80, 0x0000),
    "main/bank0.s": (*Z80, 0x8000),
    "main/bank1.s": (*Z80, 0x8000),
    "main/bank2.s": (*Z80, 0x8000),
    "main/bank3.s": (*Z80, 0x8000),
    "sub/sub.s": (*Z80, 0x0000),
    "sound/sound.s": (*Z80, 0x0000),
    "mcu/mcu.s": (*M6801, 0xF000),
}

# the main CPU's images, which refer to each other by label
MAIN = ["main/fixed.s", "main/bank0.s", "main/bank1.s", "main/bank2.s", "main/bank3.s"]

# ROM file -> sources joined in order
OUTPUTS = {
    "a78-06-1.51": ["main/fixed.s"],
    "a78-05-1.52": ["main/bank0.s", "main/bank1.s", "main/bank2.s", "main/bank3.s"],
    "a78-08.37": ["sub/sub.s"],
    "a78-07.46": ["sound/sound.s"],
    "a78-01.17": ["mcu/mcu.s"],
}


def binutils_dir() -> str:
    cfg = ROOT / "config.local.toml"
    if cfg.exists():
        d = tomllib.loads(cfg.read_text()).get("BINUTILS_DIR")
        if d:
            return d
    return "~/bublbobl-tools"


def unix_path(p: Path) -> str:
    """Path as the Binutils side sees it (WSL /mnt/<drive>/... on Windows)."""
    if os.name != "nt":
        return str(p)
    drive, rest = p.resolve().drive, p.resolve().as_posix()[2:]
    return str(PurePosixPath("/mnt", drive[0].lower()) / rest.lstrip("/"))


def run_unix(commands: list[list[str]]) -> str:
    """Run commands in one shell, from the repo root, stopping at the first failure."""
    script = f"set -e; cd {shlex.quote(unix_path(ROOT))}; " + "; ".join(
        " ".join(c if c.startswith("~/") else shlex.quote(c) for c in cmd) for cmd in commands)
    argv = ["wsl", "-e", "bash", "-c", script] if os.name == "nt" else ["bash", "-c", script]
    result = subprocess.run(argv, capture_output=True, text=True)
    if result.returncode:
        raise SystemExit(f"assembly failed:\n{result.stdout}{result.stderr}")
    return result.stdout


def read_symbols(prefix: str, stem: str, base: int) -> tuple[dict[str, int], list[str]]:
    """An object's labels (at their link addresses) and the names it leaves undefined."""
    defined: dict[str, int] = {}
    undefined: list[str] = []
    for line in run_unix([[prefix + "nm", f"{stem}.o"]]).splitlines():
        parts = line.split()
        if len(parts) == 2 and parts[0] == "U":
            undefined.append(parts[1])
        elif len(parts) == 3 and parts[1] in "tT":
            defined[parts[2]] = int(parts[0], 16) + base
    return defined, undefined


def cross_links(symbols: dict[str, tuple[dict[str, int], list[str]]]) -> dict[str, list[str]]:
    """source -> --defsym options giving it the names it takes from the other sources."""
    options: dict[str, list[str]] = {}
    for src, (_, undefined) in symbols.items():
        options[src] = []
        for name in undefined:
            found = {other: d[name] for other, (d, _) in symbols.items() if name in d}
            if len(found) != 1:
                raise SystemExit(f"{src}: {name} is defined in {sorted(found) or 'no source'}")
            options[src].append(f"--defsym={name}=0x{next(iter(found.values())):04x}")
    return options


def assemble(src_dir: str = "src", obj_dir: str = "build/obj", sources: list[str] | None = None,
             lst_dir: str | None = None) -> dict[str, bytes]:
    """Assemble and link sources (default all), writing listings to lst_dir if given. The folders
    are relative to the repo root.

    The main CPU's images use each other's labels. Nothing in them changes size with a label's
    value, so each is assembled once, leaving those names undefined, and given them at the link."""
    (ROOT / obj_dir).mkdir(parents=True, exist_ok=True)
    tools = binutils_dir()
    names = sources or list(SOURCES)

    def stem(src: str) -> str:
        return f"{obj_dir}/" + src.replace("/", "_")[:-2]

    def prefix(src: str) -> str:
        return f"{tools}/{SOURCES[src][1]}/bin/{SOURCES[src][0]}-"

    def listing(src: str) -> list[str]:
        return [f"-aln={lst_dir}/{Path(src).stem}.lst"] if lst_dir else []

    if lst_dir:
        (ROOT / lst_dir).mkdir(parents=True, exist_ok=True)
    run_unix([[prefix(src) + "as", *SOURCES[src][2], "-I", "build/images", "-I", "build/include",
               *listing(src), "-o", f"{stem(src)}.o", f"{src_dir}/{src}"] for src in names])
    main = [src for src in names if src in MAIN]
    links = cross_links({src: read_symbols(prefix(src), stem(src), SOURCES[src][3]) for src in main})
    commands = []
    for src in names:
        base = SOURCES[src][3]
        commands += [
            [prefix(src) + "ld", f"-Ttext=0x{base:04x}", "-e", f"0x{base:04x}", *links.get(src, []),
             "-o", f"{stem(src)}.elf", f"{stem(src)}.o"],
            [prefix(src) + "objcopy", "-O", "binary", f"{stem(src)}.elf", f"{stem(src)}.bin"],
        ]
    run_unix(commands)
    return {src: (ROOT / obj_dir / (src.replace("/", "_")[:-2] + ".bin")).read_bytes() for src in names}


def first_diff(a: bytes, b: bytes) -> str:
    for i, (x, y) in enumerate(zip(a, b)):
        if x != y:
            return f"first difference at file offset {i:#06x}: built {x:02X}, expected {y:02X}"
    return f"length {len(a):#x}, expected {len(b):#x}"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--roms", type=Path, help="ROM directory or zip")
    args = ap.parse_args()
    try:
        files = romset.load(args.roms)
    except romset.RomError as e:
        print(e, file=sys.stderr)
        return 1
    images = BUILD / "images"
    images.mkdir(parents=True, exist_ok=True)
    for name, data in romset.images(files).items():
        (images / name).write_bytes(data)
    symbols.write_includes(BUILD / "include")

    built = assemble(lst_dir="build/lst")
    out_dir = BUILD / "roms" / "bublbobl"
    out_dir.mkdir(parents=True, exist_ok=True)
    ok = True
    for rom, srcs in OUTPUTS.items():
        data = b"".join(built[s] for s in srcs)
        size, crc, sha1 = romset.ROMS[rom]
        if len(data) == size and zlib.crc32(data) == crc and hashlib.sha1(data).hexdigest() == sha1:
            print(f"{rom:12} OK  {crc:08x}  <- {', '.join(srcs)}")
        else:
            print(f"{rom:12} BAD {zlib.crc32(data):08x}, expected {crc:08x}: "
                  f"{first_diff(data, files[rom])}")
            ok = False
        (out_dir / rom).write_bytes(data)
    for rom, data in files.items():
        if rom not in OUTPUTS:
            (out_dir / rom).write_bytes(data)
    if not ok:
        print("Build is NOT byte-exact.", file=sys.stderr)
        return 1
    print(f"Byte-exact set written to {out_dir}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
