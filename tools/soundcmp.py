"""Capture the YM register writes MAME makes for sound commands.

Usage: python tools/soundcmp.py CMD [CMD ...]   (hex command numbers)
Writes build/soundcmp/regs.csv: command, seconds after it, chip, port, value.
"""
import subprocess
import sys

import romset
import tomllib

ROOT = romset.ROOT


def main() -> int:
    cmds = [int(a, 16) for a in sys.argv[1:]]
    mame = tomllib.loads((ROOT / "config.local.toml").read_text())["MAME_DIR"]
    out = ROOT / "build" / "soundcmp"
    out.mkdir(parents=True, exist_ok=True)
    cfg = f'CFG = {{cmds = {{{",".join(map(str, cmds))}}}, start = 600, gap = 900, out = "{(out / "regs.csv").as_posix()}"}}\n'
    script = out / "run.lua"
    script.write_text(cfg + (ROOT / "tools" / "soundlog.lua").read_text())
    subprocess.run([f"{mame}/mame.exe", "bublbobl", "-rompath", str(ROOT / "roms"), "-skip_gameinfo",
                    "-video", "none", "-sound", "none", "-nothrottle", "-autoboot_script", str(script)],
                   cwd=mame, check=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
