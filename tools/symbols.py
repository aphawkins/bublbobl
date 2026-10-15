"""Export notes/symbols.toml as assembler include files.

Usage: python tools/symbols.py [--out DIR]

Writes DIR/<cpu>.inc (default build/include/) with one .equ per name, for the CPUs listed
in INCLUDES. Code labels ([<cpu>.code], [<bank>.data]) are not exported: the source that
holds them defines them. Shared RAM ([shared.mcu]) goes to every CPU that sees it, under
the same names, at that CPU's address.
"""

import argparse
import sys
import tomllib
from pathlib import Path

import romset

ROOT = romset.ROOT
SYMBOLS = ROOT / "notes" / "symbols.toml"

# cpu -> [(table path, address transform)]
INCLUDES = {
    "main": [("main.io", None), ("main.mem", None), ("shared.mcu", None)],
    "mcu": [("mcu.io", None), ("mcu.bus", None), ("mcu.ram", None),
            ("shared.mcu", lambda a: a & 0x0FFF)],  # the MCU bus sees FC00-FFFF at 0C00-0FFF
}


def table(data: dict, path: str) -> dict:
    for key in path.split("."):
        data = data.get(key, {})
    return data


def render(data: dict, cpu: str) -> str:
    lines = [f"; {cpu}.inc - generated from notes/symbols.toml by tools/symbols.py. Do not edit.", ""]
    seen: dict[str, str] = {}
    for path, transform in INCLUDES[cpu]:
        lines.append(f"; [{path}]")
        for name, v in table(data, path).items():
            if name in seen:
                raise SystemExit(f"{cpu}: {name} is in both [{seen[name]}] and [{path}]")
            seen[name] = path
            addr = transform(v["addr"]) if transform else v["addr"]
            note = f"  ; {v['note']}" if "note" in v else ""
            lines.append(f"        .equ    {name}, 0x{addr:04X}{note}")
        lines.append("")
    return "\n".join(lines)


def write_includes(out: Path) -> list[Path]:
    data = tomllib.loads(SYMBOLS.read_text(encoding="utf-8"))
    out.mkdir(parents=True, exist_ok=True)
    paths = []
    for cpu in INCLUDES:
        path = out / f"{cpu}.inc"
        path.write_text(render(data, cpu), encoding="utf-8", newline="\n")
        paths.append(path)
    return paths


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--out", type=Path, default=ROOT / "build" / "include")
    args = ap.parse_args()
    for path in write_includes(args.out):
        print(path)
    return 0


if __name__ == "__main__":
    sys.exit(main())
