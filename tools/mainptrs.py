"""Sort the main CPU's 16-bit operands into addresses and numbers, and make the addresses labels.

Usage: python tools/mainptrs.py [--report]

Run by tools/redo_main.sh after tools/dasmz80.py, on freshly made sources. An operand that falls
in the ROM's range may be a pointer, or a count, a screen size, a colour or a pair of bytes. How
the next instructions use it decides (NUMBER_CALLS and the rules in classify()), and what no rule
settles is listed by hand in NUMBERS and POINTERS. --report prints every operand and its reading
and changes nothing.
"""

import argparse
import bisect
import re
import sys
import tomllib

import build
import dataptrs
import romset

ROOT = romset.ROOT
IMAGES = {"fixed": 0x0000, "bank0": 0x8000, "bank1": 0x8000, "bank2": 0x8000, "bank3": 0x8000}
LABEL = re.compile(r"([A-Za-z_]\w*):\s*;\s*([0-9A-F]{4})")
INCBIN = re.compile(r'\.incbin\s+"[^"]+",\s*0x[0-9A-Fa-f]+,\s*(0x[0-9A-Fa-f]+)')
OPERAND = re.compile(r"(ld|call|jp)\s+(.*)")
WORD = re.compile(r"\.word 0x([0-9A-F]{4})$")


class Line:
    def __init__(self, addr: int, size: int, text: str, number: int):
        self.addr, self.size, self.text, self.number = addr, size, text, number

    @property
    def code(self) -> str:
        return re.sub(r"\s+", " ", self.text.split(";")[0].strip())


def listing(image: str) -> list[Line]:
    """Every line of the source that makes bytes, from the assembler's listing."""
    src = (ROOT / "src" / "main" / f"{image}.s").read_text(encoding="utf-8").split("\n")
    lst = f"build/lst/{image}.lst"
    (ROOT / "build" / "lst").mkdir(exist_ok=True)
    build.run_unix([[f"{build.binutils_dir()}/z80/bin/z80-elf-as", *build.Z80[2], "-I", "build/images",
                     "-I", "build/include", f"-aln={lst}", "-o", f"build/lst/{image}.o",
                     f"src/main/{image}.s"]])
    lines: list[Line] = []
    for row in (ROOT / lst).read_text(encoding="utf-8", errors="replace").splitlines():
        if m := re.match(r"\s*(\d+)\s+([0-9a-f]{4})\s+((?:[0-9A-F]{2}\s?)+)", row):
            n, addr, data = int(m[1]), int(m[2], 16) + IMAGES[image], m[3].replace(" ", "")
            if lines and lines[-1].number == n:
                lines[-1].size += len(data) // 2
            else:
                lines.append(Line(addr, len(data) // 2, src[n - 1], n))
        elif (m := re.match(r"\s*(\d+)\s+((?:[0-9A-F]{2}\s?)+)$", row)) and lines and lines[-1].number == int(m[1]):
            lines[-1].size += len(m[2].replace(" ", "")) // 2
    for line in lines:
        if m := INCBIN.search(line.text):
            line.size = int(m[1], 16)
    return lines


# a value in this register before a call to one of these is not an address
NUMBER_CALLS = {
    "bc": {"TILE_RECT", "SPRITE_GRID", "SPRITE_GRID_D", "SPRITE", "SPRITE_GRID_FX", "TILE_COLS_COPY",
           "TILE_COLS_FILL", "PLAYER_NEAR_CHECK", "ZERO_BC"},
    "de": {"ANIM_STEP", "COUNTER_STEP", "IX_COUNT_DE", "SCORE_UPDATE", "BUBBLE_SCORE_UPDATE", "MUL16",
           "SPRITE_GRID_D"},
}


# and before one of these it is
POINTER_CALLS = {
    "hl": {"PRINT_TEXT", "PRINT_COUNTED", "ADD_HL_A", "TABLE_WORD", "SPRITE_GRID", "SPRITE_GRID_D",
           "SPRITE_GRID_FX", "SPRITE_LIST", "SPRITE_LIST_FX", "ENEMY_ANIM_FLIP", "ENEMY_ANIM_SPRITE",
           "ENEMY3_ATTACK_STEP", "STAR_COLOURS_SET"},
    "de": {"TILE_RECT", "TILE_COLS_COPY", "ADD_DE_A", "OBJ_PTR", "ENEMY_PATH_SET", "ENEMY4_TURN_SET",
           "EXTEND_JUMP_START", "OBJ_POS_LIST"},
    "bc": {"ADD_BC_A"},
    "iy": {"PRINT_TEXTS"},
}


# what no rule settles, by image and address of the instruction
NUMBERS = {
    "fixed": {
        0x00C4: "RAM test length", 0x00F4: "RAM test length", 0x0138: "delay", 0x0321: "two bytes for E1D2",
        0x1444: "a size", 0x1932: "row step", 0x1B5F: "colour", 0x25F5: "timer", 0x261E: "timer value",
        0x2265: "ROUND_TALLY value", 0x3002: "two bytes", 0x34F5: "row step", 0x404E: "timer",
        0x4C6A: "position", 0x4CCB: "position", 0x5063: "timer", 0x630F: "two bytes", 0x7098: "timer",
    },
    "bank0": {0x83A0: "ANIM_STEP pair", 0x85B4: "timer", 0xA8F9: "colour", 0xA8FF: "colour"},
    "bank2": {
        0x8453: "timer", 0x84E3: "timer", 0x8657: "timer", 0x86D7: "timer", 0x8CDD: "a size", 0x90E6: "timer",
        0x9123: "timer", 0x91C6: "timer", 0x91DB: "timer", 0x9242: "score", 0x9305: "colour", 0x930B: "colour",
        0x948B: "timer", 0x97AF: "timer", 0x9AAB: "timer", 0xA514: "position", 0xABF0: "position",
        0xBBA9: "count", 0xBBD0: "count",
    },
}
# the IM 2 vector rebuilt from I and MCU_RAM, compared as a ROM sum's end is
POINTERS = {"fixed": {0x1C77, 0x1DAB, 0x6EC2}}
# the page of fixed-ROM operands with no BANK_SELECT near them, from build/romreads/: the page
# their readers (the instruction itself, TILE_RECT, ENDING_SCROLL_STEP) read them on
PAGES = [(0x24ED, 0x2571, 3), (0x258A, 0x25A6, 0), (0x2B50, 0x2B56, 1), (0x5644, 0x5657, 1),
         (0x72C9, 0x77FF, 1), (0x7A00, 0x7FFF, 0)]
# name, start, count (None: until the first target), stride, the pointer's offset in a record
TABLES = {
    "fixed": [("ANIM_LISTS", 0x10A2, 32, 2, 0), ("SPEED_PATTERNS", 0x11CE, None, 2, 0),
              ("PRINT_TEXTS", 0x23AF, 13, 5, 2), ("PRINT_TEXTS", 0x320D, 3, 5, 2),
              ("PRINT_TEXTS", 0x3574, 7, 5, 2), ("PLAYER_ANIMS", 0x4584, 12, 8, 5)],
    "bank0": [("ENEMY_SCRIPTS", 0x80C9, 7, 2, 0), ("ENEMY_SCRIPTS", 0x8160, 7, 2, 0)],
    "bank1": [("GRID_EDGES", 0x95AA, 32, 2, 0), ("SECRET_TABLES", 0x9A6A, 14, 2, 0)],
    "bank2": [("PRINT_TEXTS", 0x819B, 0x17, 5, 2), ("VIDEO_RAM_AREAS", 0x8070, 2, 6, 4)],
}
# .word entries in the fixed ROM that point into a bank: value -> bank. Task 3 is ROUND_ENEMIES
WORDS = {0x85A9: "bank0"}
BANK1 = """; Main Z80 - banked ROM page 1 (FB40 = 5)
; a78-05-1.52 file 0x4000-0x7FFF, linked at 0x8000. Built by tools/build.py.
;
; No ROM bytes live in this repo: every range is pulled in from the verified image
; build/images/main_bank1.bin with .incbin (offset, length). The labels and .word lines
; are from tools/mainptrs.py and notes/symbols.toml.

        .section .text

        .incbin "main_bank1.bin", 0x0000, 0x4000
"""
# TAMPER_CHECK in disguise: the operand is a label plus or minus a fixed offset
OFFSETS = {"bank2": {0xA46B: ("IRQ_VECTOR_ENTRY", -34), 0xA46F: ("IRQ_HANDLER", -1)}}


def following(lines: list[Line], i: int, count: int = 5) -> list[str]:
    return [x.code for x in lines[i + 1:i + 1 + count]]


def classify(image: str, lines: list[Line], i: int) -> str:
    """'number: why', 'pointer: why' or None, from how the next instructions use the operand."""
    code = lines[i].code
    addr = lines[i].addr
    if addr in NUMBERS.get(image, ()):
        return f"number: {NUMBERS[image][addr]}"
    if addr in POINTERS.get(image, ()) or addr in OFFSETS.get(image, ()):
        return "pointer: by hand"
    nxt = following(lines, i, 6)
    m = re.match(r"ld (bc|de|hl|ix|iy),0x", code)
    if code.startswith(("call ", "jp ")):
        return "pointer: code"
    if re.match(r"ld \w+,\(0x", code):
        return "pointer: read"
    if not m:
        raise SystemExit(f"{image} {addr:04X}: {code}: no rule for this form")
    reg = m[1]
    if reg == "hl" and nxt[:2] == ["or a", "sbc hl,de"]:
        return "number: end of a ROM sum"
    if reg == "hl" and re.match(r"ld \(0x\w+\),hl", nxt[0]) and re.match(r"ld hl,0x\w+", nxt[1]) \
            and nxt[2] == "ld (hl),0x01":
        return "number: start of a ROM sum"
    if reg in ("hl", "de") and nxt[0] in ("ld a,(de)", "cp (hl)", "ld a,(hl)"):
        return "pointer: read"
    if reg == "hl" and any(n == "ldir" for n in nxt[:3]) and nxt[0].startswith("ld de,"):
        return "pointer: copied from"
    for n in nxt:
        if c := re.match(r"(?:call|jp) (\w+)", n):
            if c[1] in NUMBER_CALLS.get(reg, ()) and not (reg == "de" and c[1] == "SPRITE_GRID_D" and "hl" in code):
                return f"number: {c[1]}"
            if c[1] in POINTER_CALLS.get(reg, ()):
                return f"pointer: {c[1]}"
            break
        if reg == "bc" and n in ("ldir", "rst 0x20", "rst 0x18", "dec bc", "lddr"):
            return f"number: {n}"
        if n in ("ret",) or n.startswith(".incbin"):
            break
    return "pointer: used as one"


def operands(lines: list[Line]):
    """(index, value) of each operand in the ROM's range."""
    for i, line in enumerate(lines):
        if OPERAND.match(line.code):
            for v in re.findall(r"0x[0-9A-Fa-f]{4}\b", line.code):
                if 0x100 <= int(v, 16) < 0xC000:
                    yield i, int(v, 16)


def selected_bank(lines: list[Line], i: int) -> int | None:
    """The page selected at line i of the fixed ROM, from the nearest BANK_SELECT before it."""
    for j in range(i - 1, max(i - 80, 0), -1):
        code = lines[j].code
        if code == "call BANK_RESTORE" or code in ("ret",):
            return None
        if code == "call BANK_SELECT":
            m = re.match(r"ld a,0x(\w\w)", lines[j - 1].code)
            return int(m[1], 16) if m else None
    return None


def page_of(lines: list[Line], i: int, value: int, labels: dict[str, dict[int, str]]) -> str:
    """The bank a fixed-ROM operand in 8000-BFFF means."""
    addr = lines[i].addr
    for lo, hi, page in PAGES:
        if lo <= addr <= hi:
            return f"bank{page}"
    if (sel := selected_bank(lines, i)) is not None:
        return f"bank{sel}"
    named = [b for b in ("bank0", "bank2", "bank3") if value in labels[b]
             and not labels[b][value].startswith("L_")]
    if len(named) != 1:
        raise SystemExit(f"fixed {addr:04X}: {lines[i].code}: which bank? {named}")
    return named[0]


def kind_of(reason: str) -> str:
    if reason in ("pointer: PRINT_TEXT", "pointer: PRINT_COUNTED", "pointer: PRINT_TEXTS"):
        return "TEXT"
    if reason in ("pointer: TILE_RECT", "pointer: TILE_COLS_COPY"):
        return "TILES"
    if "SPRITE" in reason or "ENEMY_ANIM" in reason:
        return "SPRITES"
    return "CODE" if reason == "pointer: code" else "DATA"


def label_name(image: str, addr: int, kind: str) -> str:
    return f"{kind}_{addr:04X}" if image == "fixed" else f"B{image[-1]}_{kind}_{addr:04X}"


class Targets:
    """The labels every image needs, and how to spell an address in an operand."""

    def __init__(self, lines: dict[str, list[Line]]):
        self.lines = lines
        self.labels: dict[str, dict[int, str]] = {}
        for image in IMAGES:
            text = (ROOT / "src" / "main" / f"{image}.s").read_text(encoding="utf-8")
            self.labels[image] = {}
            for m in LABEL.finditer(text):
                self.labels[image].setdefault(int(m[2], 16), m[1])
        self.new: dict[str, dict[int, str]] = {image: {} for image in IMAGES}
        self.starts = {image: [x.addr for x in ls] for image, ls in lines.items()}
        self.operand: dict[tuple[str, int, int], str] = {}
        self.word: dict[tuple[str, int], str] = {}
        self.table_word: dict[tuple[str, int], str] = {}

    def line_at(self, image: str, addr: int) -> Line | None:
        if image not in self.lines:
            return None
        i = bisect.bisect_right(self.starts[image], addr) - 1
        x = self.lines[image][i]
        return x if i >= 0 and x.addr <= addr < x.addr + x.size else None

    def spell(self, image: str, addr: int, kind: str, user: str) -> str:
        """The expression for addr in `image`, as written in `user`, adding a label if need be."""
        have = self.new[image].get(addr) or self.labels[image].get(addr)
        # an L_ label may be in two banks at once: another image needs a name of its own
        if have and (user == image or image == "fixed" or not have.startswith("L_")):
            return have
        line = self.line_at(image, addr)
        if line and line.addr != addr and not line.code.startswith(".incbin"):
            # data the disassembler read as code: the instruction's label, plus the offset
            return f"{self.spell(image, line.addr, kind, user)}+{addr - line.addr}"
        self.new[image][addr] = label_name(image, addr, kind)
        return self.new[image][addr]


def table_entries(image: str, data: bytes) -> dict[int, int]:
    """Pointer address -> target for each table in `image`."""
    out: dict[int, int] = {}
    org = IMAGES[image]

    def word(a: int) -> int:
        return data[a - org] | data[a - org + 1] << 8

    for _, start, count, stride, offset in TABLES.get(image, ()):
        if count is None:  # a word table that ends where its first list starts
            at, end = start, 0x10000
            while at < end:
                end = min(end, word(at))
                at += 2
            count = (at - start) // 2
        for n in range(count):
            at = start + n * stride + offset
            out[at] = word(at)
    return out


def rewrite(image: str, lines: list[Line], t: Targets, data: bytes) -> None:
    path = ROOT / "src" / "main" / f"{image}.s"
    src = path.read_text(encoding="utf-8").split("\n")
    in_code = {a: n for a, n in t.new[image].items()
               if (x := t.line_at(image, a)) and not x.code.startswith(".incbin")}
    for i, v in operands(lines):
        key = (image, lines[i].addr, v)
        if key in t.operand:
            n = lines[i].number - 1
            src[n] = re.sub(f"0x{v:04X}\\b", t.operand[key], src[n], count=1)
    for line in lines:
        if m := WORD.match(line.code):
            src[line.number - 1] = src[line.number - 1].replace(f"0x{m[1]}", t.word[image, line.addr])
    by_line: dict[int, list[str]] = {}
    for addr, name in in_code.items():
        by_line.setdefault(t.line_at(image, addr).number - 1, []).append(f"{name + ':':<24}; {addr:04X}")
    for n in sorted(by_line, reverse=True):
        src[n:n] = by_line[n]
    rest = {a: n for a, n in t.new[image].items() if a not in in_code}
    pointers = table_entries(image, data)
    foreign = {at: t.table_word[image, at] for at in pointers}
    text = dataptrs.apply("\n".join(src), IMAGES[image], pointers, {}, names=rest, foreign=foreign)
    path.write_text(text, encoding="utf-8", newline="\n")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--report", action="store_true")
    args = ap.parse_args()
    (ROOT / "src" / "main" / "bank1.s").write_text(BANK1, encoding="utf-8", newline="\n")
    lines = {image: listing(image) for image in ("fixed", "bank0", "bank2", "bank3")}
    t = Targets(lines)
    images = {i: (ROOT / "build" / "images" / f"main_{i}.bin").read_bytes() for i in IMAGES}
    symbols = tomllib.loads((ROOT / "notes" / "symbols.toml").read_text(encoding="utf-8"))
    for name, v in symbols["bank1"]["data"].items():  # bank 1's source has no labels of its own
        if v["addr"] not in t.labels["bank1"]:
            t.new["bank1"][v["addr"]] = name
    tally: dict[tuple[str, str], int] = {}
    for image, ls in lines.items():
        for i, v in operands(ls):
            reason = classify(image, ls, i)
            key = (image, reason.split(":")[0])
            tally[key] = tally.get(key, 0) + 1
            if not reason.startswith("pointer"):
                continue
            addr = ls[i].addr
            if addr in OFFSETS.get(image, ()):
                name, off = OFFSETS[image][addr]
                t.operand[image, addr, v] = f"{name}{off:+d}"
                continue
            target = "fixed" if v < 0x8000 else image if image != "fixed" else page_of(ls, i, v, t.labels)
            t.operand[image, addr, v] = t.spell(target, v, kind_of(reason), image)
        for line in ls:
            if m := WORD.match(line.code):
                v = int(m[1], 16)
                target = WORDS.get(v) or ("fixed" if v < 0x8000 else image)
                t.word[image, line.addr] = t.spell(target, v, "CODE", image)
    for image in IMAGES:
        for at, target in table_entries(image, images[image]).items():
            where = "fixed" if target < 0x8000 else image
            t.table_word[image, at] = t.spell(where, target, "DATA", image)
    print(tally)
    for image in IMAGES:
        print(image, len(t.new[image]), "new labels;", len(table_entries(image, images[image])), "table pointers")
    if not args.report:
        for image in IMAGES:
            rewrite(image, lines.get(image, []), t, images[image])
    return 0


if __name__ == "__main__":
    sys.exit(main())
