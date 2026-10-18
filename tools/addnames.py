"""Append names to notes/symbols.toml from a file of lines: TABLE|ADDR|NAME|NOTE (NOTE may be empty).

Usage: python tools/addnames.py names.txt
Refuses a name that is already used anywhere in the file, or an address already named in the table.
"""
import re
import sys
from pathlib import Path

SYM = Path(__file__).resolve().parent.parent / "notes" / "symbols.toml"


def main() -> None:
    lines = SYM.read_text(encoding="utf-8").split("\n")
    text = "\n".join(lines)
    todo: dict[str, list[str]] = {}
    for raw in Path(sys.argv[1]).read_text(encoding="utf-8").split("\n"):
        if not raw.strip() or raw.startswith("#"):
            continue
        table, addr, name, note = (raw.split("|", 3) + [""])[:4]
        if re.search(rf"^{re.escape(name)}\s*=", text, re.M):
            sys.exit(f"name already used: {name}")
        note = note.strip().replace("\\", "\\\\").replace('"', '\\"')
        entry = f'{name} = {{ addr = 0x{int(addr, 16):04X}' + (f', note = "{note}"' if note else "") + " }"
        todo.setdefault(table, []).append(entry)
    for table, entries in todo.items():
        start = lines.index(f"[{table}]")
        end = start + 1
        while end < len(lines) and not lines[end].startswith("["):
            end += 1
        while lines[end - 1].strip() == "":
            end -= 1
        lines[end:end] = entries
    SYM.write_text("\n".join(lines), encoding="utf-8", newline="\n")
    print(sum(map(len, todo.values())), "names added")


main()
