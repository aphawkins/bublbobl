"""Load and verify the bublbobl ROM set, and emit per-CPU images.

Usage: python tools/romset.py [--roms DIR] [--out DIR]

DIR defaults to ROM_DIR from config.local.toml, else roms/bublbobl (or roms/bublbobl.zip).
Refuses to run if any file is missing or fails its CRC32/SHA1 check.
"""

import argparse
import hashlib
import sys
import tomllib
import zipfile
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# MAME set `bublbobl` (Japan, Ver 0.1): name -> (size, crc32, sha1)
ROMS = {
    "a78-06-1.51": (0x8000, 0x567934B6, "b0c4d49fd551f465d148c25c3e80b278835e2f0d"),
    "a78-05-1.52": (0x10000, 0x9F8EE242, "924150d4e7e087a9b2b0a294c2d0e9903a266c6c"),
    "a78-08.37": (0x8000, 0xAE11A07B, "af7a335c8da637103103cc274e077f123908ebb7"),
    "a78-07.46": (0x8000, 0x4F9A26E8, "3105b34b88a7134493c2b3f584729f8b0407a011"),
    "a78-01.17": (0x1000, 0xB1BFB53D, "31b8f31acd3aa394acd80db362774749842e1285"),
    "a78-09.12": (0x8000, 0x20358C22, "2297af6c53d5807bf90a8e081075b8c72a994fc5"),
    "a78-10.13": (0x8000, 0x930168A9, "fd358c3c3b424bca285f67a1589eb98a345ff670"),
    "a78-11.14": (0x8000, 0x9773E512, "33c1687ee575d66bf0e98add45d06da827813765"),
    "a78-12.15": (0x8000, 0xD045549B, "0c12077d3ddc2ce6aa45a0224ad5540f3f218446"),
    "a78-13.16": (0x8000, 0xD0AF35C5, "c5a89f4d73acc0db86654540b3abfd77b3757db5"),
    "a78-14.17": (0x8000, 0x7B5369A8, "1307b26d80e6f36ebe6c442bebec41d20066eaf9"),
    "a78-15.30": (0x8000, 0x6B61A413, "44eddf12fb46fceca2addbe6da929aaea7636b13"),
    "a78-16.31": (0x8000, 0xB5492D97, "d5b045e3ebaa44809757a4220cefb3c6815470da"),
    "a78-17.32": (0x8000, 0xD69762D5, "3326fef4e0bd86681a3047dc11886bb171ecb609"),
    "a78-18.33": (0x8000, 0x9F243B68, "32dce8d311a4be003693182a999e4053baa6bb0a"),
    "a78-19.34": (0x8000, 0x66E9438C, "b94e62b6fbe7f4e08086d0365afc5cff6e0ccafd"),
    "a78-20.35": (0x8000, 0x9EF863AD, "29f91b5a3765e4d6e6c3382db1d8d8297b6e56c8"),
    "a71-25.41": (0x100, 0x2D0F8545, "089c31e2f614145ef2743164f7b52ae35bc06808"),
}

# Per-CPU images: output name -> (rom file, file offset, length, base address)
IMAGES = {
    "main_fixed.bin": ("a78-06-1.51", 0x0000, 0x8000, 0x0000),
    "main_bank0.bin": ("a78-05-1.52", 0x0000, 0x4000, 0x8000),
    "main_bank1.bin": ("a78-05-1.52", 0x4000, 0x4000, 0x8000),
    "main_bank2.bin": ("a78-05-1.52", 0x8000, 0x4000, 0x8000),
    "main_bank3.bin": ("a78-05-1.52", 0xC000, 0x4000, 0x8000),
    "sub.bin": ("a78-08.37", 0x0000, 0x8000, 0x0000),
    "sound.bin": ("a78-07.46", 0x0000, 0x8000, 0x0000),
    "mcu.bin": ("a78-01.17", 0x0000, 0x1000, 0xF000),
}


class RomError(Exception):
    pass


def default_rom_dir() -> Path:
    cfg = ROOT / "config.local.toml"
    if cfg.exists():
        rom_dir = tomllib.loads(cfg.read_text()).get("ROM_DIR")
        if rom_dir:
            return Path(rom_dir)
    folder = ROOT / "roms" / "bublbobl"
    return folder if folder.is_dir() else ROOT / "roms" / "bublbobl.zip"


def read_files(source: Path) -> dict[str, bytes]:
    if source.is_dir():
        return {n: (source / n).read_bytes() for n in ROMS if (source / n).exists()}
    if source.suffix.lower() == ".zip" and source.exists():
        with zipfile.ZipFile(source) as z:
            names = {Path(i.filename).name: i.filename for i in z.infolist()}
            return {n: z.read(names[n]) for n in ROMS if n in names}
    raise RomError(f"ROM source not found: {source}")


def load(source: Path | None = None) -> dict[str, bytes]:
    """Return every ROM file, verified. Raises RomError on any problem."""
    files = read_files(source or default_rom_dir())
    errors = []
    for name, (size, crc, sha1) in ROMS.items():
        data = files.get(name)
        if data is None:
            errors.append(f"{name}: missing")
        elif len(data) != size:
            errors.append(f"{name}: size {len(data):#x}, expected {size:#x}")
        elif zlib.crc32(data) != crc or hashlib.sha1(data).hexdigest() != sha1:
            errors.append(f"{name}: crc {zlib.crc32(data):08x}, expected {crc:08x}")
    if errors:
        raise RomError("ROM set check failed:\n  " + "\n  ".join(errors))
    return files


def images(files: dict[str, bytes]) -> dict[str, bytes]:
    return {
        out: files[rom][off : off + length]
        for out, (rom, off, length, _base) in IMAGES.items()
    }


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--roms", type=Path, help="ROM directory or zip")
    ap.add_argument("--out", type=Path, default=ROOT / "build" / "images")
    args = ap.parse_args()
    try:
        files = load(args.roms)
    except RomError as e:
        print(e, file=sys.stderr)
        return 1
    args.out.mkdir(parents=True, exist_ok=True)
    for name, data in images(files).items():
        (args.out / name).write_bytes(data)
        print(f"{name:16} {len(data):#07x} bytes @ {IMAGES[name][3]:04X}")
    print(f"ROM set OK ({len(ROMS)} files); images in {args.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
