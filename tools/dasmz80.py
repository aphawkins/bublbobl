"""First-pass Z80 disassembly: follow code from the entry points, write GNU as source.

Usage: python tools/dasmz80.py CPU [--roms DIR] [--entry ADDR ...] [--table ADDR:COUNT ...]
                                   [--out FILE]

CPU is an image in IMAGES (sub, sound, main_fixed, main_bank0-3). Starts at RST 0, the IM 1 vector
0038, NMI 0066 (where they are not FF), the start of every traced code range in
notes/classmap/<cpu>.toml, every [<cpu>.code] name, any --entry addresses and the words of each --table (a jump
table of COUNT little-endian addresses, written as .word labels). It follows
every JP, JR, DJNZ, CALL and RST, and stops at RET, RETI, RETN, JP, JR and JP (HL). Bytes
never reached stay as .incbin of build/images/<image>, split at every label, so the output
holds no ROM bytes. Labels come from [<cpu>.code] and [<cpu>.data] in notes/symbols.toml,
else L_<addr>. A 16-bit operand that is a label uses it (ROM values that are not
labels stay as numbers: name data by hand); other 16-bit operands that equal a RAM name in build/include/<cpu>.inc use it.

An instruction GNU as would encode differently (ED-prefixed duplicates, undocumented
ED and DDCB forms) stays as .incbin with a comment that reads it, so the output
assembles byte-exact.

This is a one-shot generator for the first version of src/<cpu>/*.s. After that the
source is edited by hand, so don't run it over an annotated file: write to disasm/ and
merge. Syntax is z80-elf-as with -march=z80+xyhl+sli+xdcb.
"""

import argparse
import sys
import tomllib
from pathlib import Path

import romset

ROOT = romset.ROOT

# cpu -> (image, base, end, symbols tables for labels, include tables for operands)
IMAGES = {
    "sub": ("sub.bin", 0x0000, 0x8000, ["sub.code", "sub.data"], ["main.mem"]),
    "sound": ("sound.bin", 0x0000, 0x8000, ["sound.code"], ["sound.io"]),
    "main_fixed": ("main_fixed.bin", 0x0000, 0x8000, ["main.code", "main.data"],
                   ["main.io", "main.mem", "shared.mcu"]),
}
# the four banked 16K pages of a78-05-1, each linked at 0x8000
for _n in range(4):
    IMAGES[f"main_bank{_n}"] = (f"main_bank{_n}.bin", 0x8000, 0xC000,
                                [f"bank{_n}.code", f"bank{_n}.data"],
                                ["main.io", "main.mem", "shared.mcu"])

# cpu -> the include file tools/symbols.py writes for it
INCLUDE = {"sub": "sub.inc", "main_fixed": "main.inc",
           **{f"main_bank{n}": "main.inc" for n in range(4)}}
# banks also see the fixed ROM's names (build/include/fixed.inc)
EXTRA_INCLUDE = {f"main_bank{n}": "fixed.inc" for n in range(4)}

R = ["b", "c", "d", "e", "h", "l", "(hl)", "a"]
RP = ["bc", "de", "hl", "sp"]
RP2 = ["bc", "de", "hl", "af"]
CC = ["nz", "z", "nc", "c", "po", "pe", "p", "m"]
ALU = ["add a,", "adc a,", "sub ", "sbc a,", "and ", "xor ", "or ", "cp "]
ROT = ["rlc", "rrc", "rl", "rr", "sla", "sra", "sli", "srl"]
BLOCK = {(4, 0): "ldi", (4, 1): "cpi", (4, 2): "ini", (4, 3): "outi",
         (5, 0): "ldd", (5, 1): "cpd", (5, 2): "ind", (5, 3): "outd",
         (6, 0): "ldir", (6, 1): "cpir", (6, 2): "inir", (6, 3): "otir",
         (7, 0): "lddr", (7, 1): "cpdr", (7, 2): "indr", (7, 3): "otdr"}


class Insn:
    """One decoded instruction. text uses {T} for a code target, {N} for a 16-bit value."""

    def __init__(self, n: int, text: str, target: int | None = None, value: int | None = None,
                 flow: str = "", exact: bool = True):
        self.n, self.text, self.target, self.value = n, text, target, value
        self.flow = flow          # "", "jump" (and fall through), "stop", "call"
        self.exact = exact        # False: GNU as would encode it differently


def s8(b: int) -> int:
    return b - 0x100 if b & 0x80 else b


def decode(mem, a: int) -> Insn | None:
    """Decode at a (mem(addr) -> byte). None for an opcode this tool does not read."""
    op = mem(a)
    if op in (0xDD, 0xFD):
        return decode_index(mem, a, "ix" if op == 0xDD else "iy")
    if op == 0xCB:
        b = mem(a + 1)
        x, y, z = b >> 6, (b >> 3) & 7, b & 7
        name = ROT[y] if x == 0 else ["", "bit", "res", "set"][x]
        return Insn(2, f"{name} {R[z]}" if x == 0 else f"{name} {y},{R[z]}")
    if op == 0xED:
        return decode_ed(mem, a)
    x, y, z, p, q = op >> 6, (op >> 3) & 7, op & 7, (op >> 4) & 3, (op >> 3) & 1
    n8 = lambda: mem(a + 1)
    nn = lambda: mem(a + 1) | mem(a + 2) << 8
    if x == 0:
        if z == 0:
            if y == 0:
                return Insn(1, "nop")
            if y == 1:
                return Insn(1, "ex af,af'")
            t = (a + 2 + s8(n8())) & 0xFFFF
            if y == 2:
                return Insn(2, "djnz {T}", target=t, flow="jump")
            if y == 3:
                return Insn(2, "jr {T}", target=t, flow="stop")
            return Insn(2, f"jr {CC[y - 4]},{{T}}", target=t, flow="jump")
        if z == 1:
            if q == 0:
                return Insn(3, f"ld {RP[p]},{{N}}", value=nn())
            return Insn(1, f"add hl,{RP[p]}")
        if z == 2:
            return [Insn(1, "ld (bc),a"), Insn(1, "ld a,(bc)"), Insn(1, "ld (de),a"),
                    Insn(1, "ld a,(de)"), Insn(3, "ld ({N}),hl", value=nn()),
                    Insn(3, "ld hl,({N})", value=nn()), Insn(3, "ld ({N}),a", value=nn()),
                    Insn(3, "ld a,({N})", value=nn())][y]
        if z == 3:
            return Insn(1, f"{'inc' if q == 0 else 'dec'} {RP[p]}")
        if z == 4:
            return Insn(1, f"inc {R[y]}")
        if z == 5:
            return Insn(1, f"dec {R[y]}")
        if z == 6:
            return Insn(2, f"ld {R[y]},0x{n8():02X}")
        return Insn(1, ["rlca", "rrca", "rla", "rra", "daa", "cpl", "scf", "ccf"][y])
    if x == 1:
        if op == 0x76:
            return Insn(1, "halt")
        return Insn(1, f"ld {R[y]},{R[z]}")
    if x == 2:
        return Insn(1, f"{ALU[y]}{R[z]}")
    if z == 0:
        return Insn(1, f"ret {CC[y]}")
    if z == 1:
        if q == 0:
            return Insn(1, f"pop {RP2[p]}")
        return [Insn(1, "ret", flow="stop"), Insn(1, "exx"),
                Insn(1, "jp (hl)", flow="stop"), Insn(1, "ld sp,hl")][p]
    if z == 2:
        return Insn(3, f"jp {CC[y]},{{T}}", target=nn(), flow="jump")
    if z == 3:
        if y == 0:
            return Insn(3, "jp {T}", target=nn(), flow="stop")
        if y == 2:
            return Insn(2, f"out (0x{n8():02X}),a")
        if y == 3:
            return Insn(2, f"in a,(0x{n8():02X})")
        return [None, None, None, None, Insn(1, "ex (sp),hl"), Insn(1, "ex de,hl"),
                Insn(1, "di"), Insn(1, "ei")][y]
    if z == 4:
        return Insn(3, f"call {CC[y]},{{T}}", target=nn(), flow="call")
    if z == 5:
        if q == 0:
            return Insn(1, f"push {RP2[p]}")
        if p == 0:
            return Insn(3, "call {T}", target=nn(), flow="call")
        return None
    if z == 6:
        return Insn(2, f"{ALU[y]}0x{n8():02X}")
    return Insn(1, f"rst 0x{y * 8:02X}", target=y * 8, flow="call")


def decode_ed(mem, a: int) -> Insn | None:
    b = mem(a + 1)
    x, y, z, p, q = b >> 6, (b >> 3) & 7, b & 7, (b >> 4) & 3, (b >> 3) & 1
    nn = mem(a + 2) | mem(a + 3) << 8
    if x == 2 and (y, z) in BLOCK:
        return Insn(2, BLOCK[(y, z)])
    if x != 1:
        return Insn(2, f"ED {b:02X} (no-op)", exact=False)
    if z == 0:
        return Insn(2, f"in {R[y]},(c)") if y != 6 else Insn(2, "in f,(c)", exact=False)
    if z == 1:
        return Insn(2, f"out (c),{R[y]}") if y != 6 else Insn(2, "out (c),0", exact=False)
    if z == 2:
        return Insn(2, f"{'sbc' if q == 0 else 'adc'} hl,{RP[p]}")
    if z == 3:
        if p == 2:  # the ED forms of ld (nn),hl / ld hl,(nn)
            return Insn(4, f"ld {'({N}),hl' if q == 0 else 'hl,({N})'}", value=nn, exact=False)
        return Insn(4, f"ld ({{N}}),{RP[p]}" if q == 0 else f"ld {RP[p]},({{N}})", value=nn)
    if z == 4:
        return Insn(2, "neg", exact=b == 0x44)
    if z == 5:
        if b == 0x4D:
            return Insn(2, "reti", flow="stop")
        return Insn(2, "retn", flow="stop", exact=b == 0x45)
    if z == 6:
        return Insn(2, f"im {[0, 0, 1, 2][y & 3]}", exact=b in (0x46, 0x56, 0x5E))
    return [Insn(2, "ld i,a"), Insn(2, "ld r,a"), Insn(2, "ld a,i"), Insn(2, "ld a,r"),
            Insn(2, "rrd"), Insn(2, "rld"), Insn(2, "ED 77 (no-op)", exact=False),
            Insn(2, "ED 7F (no-op)", exact=False)][y]


def decode_index(mem, a: int, ix: str) -> Insn | None:
    op = mem(a + 1)
    d = s8(mem(a + 2))
    m = f"({ix}{d:+d})"
    hi, lo = ix + "h", ix + "l"
    nn = mem(a + 2) | mem(a + 3) << 8
    if op == 0xCB:
        b = mem(a + 3)
        x, y, z = b >> 6, (b >> 3) & 7, b & 7
        if x == 0:
            text = f"{ROT[y]} {m}"
        else:
            text = f"{['', 'bit', 'res', 'set'][x]} {y},{m}"
        if z != 6 and x != 1:  # undocumented: also copies the result to a register
            text += f",{R[z]}"
        return Insn(4, text, exact=z == 6 or x != 1)
    x, y, z, p, q = op >> 6, (op >> 3) & 7, op & 7, (op >> 4) & 3, (op >> 3) & 1

    def reg(i: int) -> str:
        return {4: hi, 5: lo, 6: m}.get(i, R[i])

    if op == 0x21:
        return Insn(4, f"ld {ix},{{N}}", value=nn)
    if op == 0x22:
        return Insn(4, f"ld ({{N}}),{ix}", value=nn)
    if op == 0x2A:
        return Insn(4, f"ld {ix},({{N}})", value=nn)
    if op in (0x23, 0x2B):
        return Insn(2, f"{'inc' if op == 0x23 else 'dec'} {ix}")
    if x == 0 and z == 1 and q == 1:
        return Insn(2, f"add {ix},{ix if p == 2 else RP[p]}")
    if op in (0x34, 0x35):
        return Insn(3, f"{'inc' if op == 0x34 else 'dec'} {m}")
    if op == 0x36:
        return Insn(4, f"ld {m},0x{mem(a + 3):02X}")
    if op in (0x24, 0x25, 0x2C, 0x2D):
        return Insn(2, f"{'inc' if z == 4 else 'dec'} {reg(y)}")
    if op in (0x26, 0x2E):
        return Insn(3, f"ld {reg(y)},0x{mem(a + 2):02X}")
    if x == 1 and op != 0x76:
        if y == 6 or z == 6:  # (ix+d) with a plain register
            n = 3
            text = f"ld {m if y == 6 else R[y]},{m if z == 6 else R[z]}"
        elif y in (4, 5) or z in (4, 5):
            n, text = 2, f"ld {reg(y)},{reg(z)}"
        else:
            return None
        return Insn(n, text)
    if x == 2:
        if z == 6:
            return Insn(3, f"{ALU[y]}{m}")
        if z in (4, 5):
            return Insn(2, f"{ALU[y]}{reg(z)}")
        return None
    return {0xE1: Insn(2, f"pop {ix}"), 0xE5: Insn(2, f"push {ix}"),
            0xE3: Insn(2, f"ex (sp),{ix}"), 0xE9: Insn(2, f"jp ({ix})", flow="stop"),
            0xF9: Insn(2, f"ld sp,{ix}")}.get(op)


class Names:
    def __init__(self, cpu: str):
        t = tomllib.loads((ROOT / "notes" / "symbols.toml").read_text(encoding="utf-8"))
        _img, base, end, labels, includes = IMAGES[cpu]

        def table(path):
            d = t
            for k in path.split("."):
                d = d.get(k, {})
            return d

        self.code: dict[int, tuple[str, str | None]] = {}
        for path in labels:
            for k, v in table(path).items():
                if base <= v["addr"] < end:
                    self.code[v["addr"]] = (k, v.get("note"))
        self.ext: dict[int, str] = {}  # names in another image's code (the fixed ROM, for a bank)
        if cpu in EXTRA_INCLUDE:
            for path in ("main.code", "main.data"):
                for k, v in table(path).items():
                    if v["addr"] < 0x8000:
                        self.ext[v["addr"]] = k
        self.ram: dict[int, str] = {}
        for path in includes:
            for k, v in table(path).items():
                if not base <= v["addr"] < end and (cpu != "sub" or 0xE000 <= v["addr"] < 0xF800):
                    self.ram.setdefault(v["addr"], k)


class Dasm:
    def __init__(self, data: bytes, base: int, end: int):
        self.data, self.base, self.end = data, base, end
        self.insns: dict[int, Insn] = {}
        self.targets: set[int] = set()
        self.data_refs: set[int] = set()
        self.entries: set[int] = set()
        self.tables: dict[int, list[int]] = {}
        self.blocked: list[tuple[int, int]] = []  # classified text, fill or hand-marked data: never code

    def mem(self, a: int) -> int:
        a &= 0xFFFF
        return self.data[a - self.base] if self.base <= a < self.end else 0xFF

    def trace(self, entries: list[int], label: bool = True) -> None:
        todo = list(entries)
        if label:
            self.entries |= set(entries)
        while todo:
            a = todo.pop()
            while self.base <= a < self.end and a not in self.insns:
                if any(lo <= a < hi for lo, hi in self.blocked):
                    break
                i = decode(self.mem, a)
                if i is None:  # a path into data, or an opcode this tool does not read
                    print(f"warning: opcode not read at {a:04X}: {self.mem(a):02X} "
                          f"{self.mem(a + 1):02X}; path stopped", file=sys.stderr)
                    break
                if a + i.n > self.end:  # runs off the end of the image
                    break
                self.insns[a] = i
                if i.target is not None and self.base <= i.target < self.end:
                    self.targets.add(i.target)
                    todo.append(i.target)
                if i.value is not None and self.base <= i.value < self.end:
                    self.data_refs.add(i.value)
                if i.flow == "stop":
                    break
                a += i.n

    def bad_targets(self) -> set[int]:
        """Branch and call targets that fall inside an instruction."""
        return {i.target for i in self.insns.values()
                if i.target is not None and self.base <= i.target < self.end
                and self.inside(i.target)}

    def probe(self) -> int:
        """Trace every untraced gap whose bytes decode cleanly from its start to a stop.

        A gap is a run of bytes in no instruction and no blocked range. Data seldom decodes
        for dozens of instructions and ends exactly on a RET, JP or JR, so such a gap is code
        the trace did not reach (a routine called through a bank switch). Returns the number
        of gaps taken."""
        taken = 0
        again = True
        while again:
            again = False
            covered = bytearray(self.end - self.base)
            for a, i in self.insns.items():
                covered[a - self.base:a - self.base + i.n] = b"" * i.n
            for lo, hi in self.blocked:
                for a in range(max(lo, self.base), min(hi, self.end)):
                    covered[a - self.base] = 1
            a = self.base
            while a < self.end:
                if covered[a - self.base]:
                    a += 1
                    continue
                e = a
                while e < self.end and not covered[e - self.base]:
                    e += 1
                p, last, count = a, None, 0
                while p < e:
                    i = decode(self.mem, p)
                    if i is None or p + i.n > e:
                        break
                    last, count, p = i, count + 1, p + i.n
                if p == e and last is not None and last.flow == "stop" and count >= 4:
                    before = (dict(self.insns), set(self.targets), set(self.data_refs))
                    bad = self.bad_targets()
                    self.trace([a], label=False)
                    # reject it when something now jumps into the middle of an instruction
                    if self.bad_targets() - bad:
                        self.insns, self.targets, self.data_refs = before
                        self.blocked.append((a, e))
                    else:
                        self.targets.add(a)
                        taken += 1
                    again = True
                    break
                a = e
        return taken

    def table(self, a: int, count: int) -> list[int]:
        words = [self.mem(a + 2 * k) | self.mem(a + 2 * k + 1) << 8 for k in range(count)]
        self.tables[a] = words
        self.targets |= set(words)
        return words

    def inside(self, a: int) -> bool:
        """True when a falls inside an instruction but not at its start."""
        for k in range(1, 4):
            i = self.insns.get(a - k)
            if i and i.n > k:
                return True
        return False

    def source(self, cpu: str, names: Names) -> str:
        img = IMAGES[cpu][0]
        want = self.targets | self.entries | set(self.tables) | set(names.code)
        labels = {}
        for a in sorted(want):
            if self.base <= a < self.end and not self.inside(a):
                labels[a] = names.code[a][0] if a in names.code else f"L_{a:04X}"

        def num(v: int) -> str:
            if v in labels:
                return labels[v]
            return names.ram.get(v) or names.ext.get(v) or f"0x{v:04X}"

        out = [
            f"; {cpu} - first pass by tools/dasmz80.py",
            f"; No ROM bytes: every range not disassembled is .incbin of build/images/{img}.",
            "",
            *([f'        .include "{INCLUDE[cpu]}"'] if cpu in INCLUDE else []),
            *([f'        .include "{EXTRA_INCLUDE[cpu]}"'] if cpu in EXTRA_INCLUDE else []),
            "        .section .text",
            "",
        ]
        a = self.base
        while a < self.end:
            if a in labels:
                note = names.code.get(a, (None, None))[1]
                if note:
                    out.append(f"; {note}")
                out.append(f"{labels[a] + ':':<24}; {a:04X}")
            if a in self.tables:
                for w in self.tables[a]:
                    out.append(f"        .word   {labels.get(w, f'0x{w:04X}')}")
                a += 2 * len(self.tables[a])
                continue
            i = self.insns.get(a)
            if i is not None:
                text = i.text
                if i.target is not None:
                    text = text.replace("{T}", labels.get(i.target) or names.ext.get(i.target) or f"0x{i.target:04X}")
                if i.value is not None:
                    text = text.replace("{N}", num(i.value))
                mnem, _, ops = text.partition(" ")
                # a target inside another instruction has no label: keep the bytes, read in a comment
                if i.target is not None and i.target not in labels and i.flow != "call"                         and text.split()[0] in ("jr", "djnz"):
                    out.append(f'        .incbin "{img}", 0x{a - self.base:04X}, {i.n}'
                               f"{'':<8}; {text} (target is inside an instruction)")
                elif i.exact:
                    out.append(f"        {mnem:<7} {ops}".rstrip())
                else:
                    out.append(f'        .incbin "{img}", 0x{a - self.base:04X}, {i.n}'
                               f"{'':<8}; {text}")
                if i.flow == "stop":
                    out.append("")
                a += i.n
            else:
                end = a + 1
                while (end < self.end and end not in self.insns and end not in labels
                       and end not in self.tables):
                    end += 1
                out.append(f'        .incbin "{img}", 0x{a - self.base:04X}, 0x{end - a:04X}')
                a = end
        return "\n".join(out) + "\n"


def traced_starts(cpu: str) -> list[int]:
    path = ROOT / "notes" / "classmap" / f"{IMAGES[cpu][0].removesuffix('.bin')}.toml"
    if not path.exists():
        return []
    ranges = tomllib.loads(path.read_text(encoding="utf-8")).get("range", [])
    return [r["start"] for r in ranges if r["kind"] == "code" and r.get("source") == "trace"]


def blocked_ranges(cpu: str) -> list[tuple[int, int]]:
    """Ranges the classification map calls text or fill: a path that runs into one stops."""
    path = ROOT / "notes" / "classmap" / f"{IMAGES[cpu][0].removesuffix('.bin')}.toml"
    if not path.exists():
        return []
    ranges = tomllib.loads(path.read_text(encoding="utf-8")).get("range", [])
    return [(r["start"], r["end"] + 1) for r in ranges if r["kind"] in ("text", "fill")
            or r["kind"] == "data" and r.get("source") == "manual"]


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("cpu", choices=IMAGES)
    ap.add_argument("--roms", type=Path, help="ROM directory or zip")
    ap.add_argument("--entry", type=lambda s: int(s, 16), action="append", default=[],
                    help="extra code entry point (hex)")
    ap.add_argument("--table", action="append", default=[],
                    help="jump table ADDR:COUNT (hex address, decimal count)")
    ap.add_argument("--probe", action="store_true",
                    help="also trace untraced gaps that decode cleanly to a RET/JP/JR")
    ap.add_argument("--out", type=Path)
    args = ap.parse_args()
    img, base, end, _l, _i = IMAGES[args.cpu]
    try:
        data = romset.images(romset.load(args.roms))[img]
    except romset.RomError as e:
        print(e, file=sys.stderr)
        return 1
    d = Dasm(data[:end - base], base, end)
    d.blocked = blocked_ranges(args.cpu)
    names = Names(args.cpu)
    entries = [a for a in (0x0000, 0x0038, 0x0066) if base <= a < end and d.mem(a) != 0xFF]
    entries += list(names.code) + args.entry
    # [<cpu>.data] names are labels, not entry points
    data_names = set()
    t = tomllib.loads((ROOT / "notes" / "symbols.toml").read_text(encoding="utf-8"))
    for path in IMAGES[args.cpu][3]:
        if path.endswith(".data"):
            cpu, kind = path.split(".")
            data_names |= {v["addr"] for v in t.get(cpu, {}).get(kind, {}).values()}
    for t in args.table:
        addr, count = t.split(":")
        entries += d.table(int(addr, 16), int(count))
    d.trace([a for a in entries if a not in data_names])
    # traced starts are entry points but get no label of their own
    d.trace([a for a in traced_starts(args.cpu) if a not in data_names], label=False)
    if args.probe:
        print(f"probe: {d.probe()} gaps taken", file=sys.stderr)
    out = args.out or ROOT / "disasm" / f"{args.cpu}.s"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(d.source(args.cpu, names), encoding="utf-8", newline="\n")
    code = sum(i.n for i in d.insns.values())
    print(f"{len(d.insns)} instructions, {code:#x} code bytes; {len(d.targets)} targets; "
          f"written to {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
