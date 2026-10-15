"""First-pass MCU disassembly: follow code from the vectors, write GNU as source.

Usage: python tools/dasm6801.py [--roms DIR] [--entry ADDR ...] [--out FILE]

Starts at the RESET, IRQ1 and OCF vectors (plus any --entry addresses), follows every
branch, JSR and JMP, and stops at RTS, RTI, BRA, JMP and WAI. Bytes that are never reached
stay as .incbin of build/images/mcu.bin, split at every label, so the output holds no ROM
bytes. Labels come from [mcu.code] in notes/symbols.toml, else L_<addr>; operands use
the names in [mcu.io], [mcu.ram] and [shared.mcu] (as `.include "mcu.inc"` defines them).
Immediate values that are not shared-RAM addresses stay as numbers: name those by hand.

This is a one-shot generator for the first version of src/mcu/mcu.s. After that the source
is edited by hand, so don't run it over an annotated file: write to disasm/ and merge.

Syntax is m68hc11-elf-as: 68HC11 mnemonics (ldaa, staa, lsld ...), `*addr` for the
two-byte direct form, a bare address for the three-byte extended form (EXTRACTION_PLAN
§12.3).
"""

import argparse
import sys
import tomllib
from pathlib import Path

import romset

ROOT = romset.ROOT
BASE = 0xF000
VECTORS = {0xFFF0: "SCI", 0xFFF2: "TOF", 0xFFF4: "OCF", 0xFFF6: "ICF",
           0xFFF8: "IRQ1", 0xFFFA: "SWI", 0xFFFC: "NMI", 0xFFFE: "RESET"}

# opcode -> (mnemonic, mode). Modes: inh, rel, imm8, imm16, dir, ext, idx
OPS: dict[int, tuple[str, str]] = {}
for op, m in {0x01: "nop", 0x04: "lsrd", 0x05: "lsld", 0x06: "tap", 0x07: "tpa", 0x08: "inx",
              0x09: "dex", 0x0A: "clv", 0x0B: "sev", 0x0C: "clc", 0x0D: "sec", 0x0E: "cli",
              0x0F: "sei", 0x10: "sba", 0x11: "cba", 0x16: "tab", 0x17: "tba", 0x19: "daa",
              0x1B: "aba", 0x30: "tsx", 0x31: "ins", 0x32: "pula", 0x33: "pulb", 0x34: "des",
              0x35: "txs", 0x36: "psha", 0x37: "pshb", 0x38: "pulx", 0x39: "rts", 0x3A: "abx",
              0x3B: "rti", 0x3C: "pshx", 0x3D: "mul", 0x3E: "wai", 0x3F: "swi"}.items():
    OPS[op] = (m, "inh")
for i, m in enumerate(["bra", "brn", "bhi", "bls", "bcc", "bcs", "bne", "beq",
                       "bvc", "bvs", "bpl", "bmi", "bge", "blt", "bgt", "ble"]):
    OPS[0x20 + i] = (m, "rel")
OPS[0x8D] = ("bsr", "rel")
for low, m in {0x0: "neg", 0x3: "com", 0x4: "lsr", 0x6: "ror", 0x7: "asr", 0x8: "asl",
               0x9: "rol", 0xA: "dec", 0xC: "inc", 0xD: "tst", 0xF: "clr"}.items():
    OPS[0x40 + low] = (m + "a", "inh")
    OPS[0x50 + low] = (m + "b", "inh")
    OPS[0x60 + low] = (m, "idx")
    OPS[0x70 + low] = (m, "ext")
OPS[0x6E] = ("jmp", "idx")
OPS[0x7E] = ("jmp", "ext")
for row, names in ((0x80, ["suba", "cmpa", "sbca", "subd", "anda", "bita", "ldaa", "staa",
                           "eora", "adca", "oraa", "adda", "cpx", "jsr", "lds", "sts"]),
                   (0xC0, ["subb", "cmpb", "sbcb", "addd", "andb", "bitb", "ldab", "stab",
                           "eorb", "adcb", "orab", "addb", "ldd", "std", "ldx", "stx"])):
    for low, m in enumerate(names):
        wide = m in ("subd", "cpx", "lds", "addd", "ldd", "ldx")
        if m not in ("staa", "jsr", "sts", "stab", "std", "stx"):
            OPS[row + low] = (m, "imm16" if wide else "imm8")
        OPS[row + 0x10 + low] = (m, "dir")
        OPS[row + 0x20 + low] = (m, "idx")
        OPS[row + 0x30 + low] = (m, "ext")
SIZE = {"inh": 1, "rel": 2, "imm8": 2, "imm16": 3, "dir": 2, "ext": 3, "idx": 2}
STOP = {"rts", "rti", "bra", "jmp", "wai"}


class Names:
    def __init__(self):
        t = tomllib.loads((ROOT / "notes" / "symbols.toml").read_text(encoding="utf-8"))
        mcu = t.get("mcu", {})
        self.code = {v["addr"]: (k, v.get("note")) for k, v in mcu.get("code", {}).items()}
        self.io = {v["addr"]: k for k, v in mcu.get("io", {}).items()}
        self.ram: dict[int, str] = {}
        for k, v in mcu.get("ram", {}).items():
            if k != "RAM_START":
                self.ram.setdefault(v["addr"], k)
        self.shared = {v["addr"] & 0x0FFF: k for k, v in t.get("shared", {}).get("mcu", {}).items()}

    def data(self, a: int) -> str | None:
        """Name for a direct or extended data operand."""
        return self.io.get(a) or self.ram.get(a)


class Dasm:
    def __init__(self, data: bytes):
        self.data = data
        self.insns: dict[int, tuple[str, str, int | None]] = {}  # addr -> mnem, mode, operand
        self.code_refs: set[int] = set()  # branch / call / jump targets
        self.data_refs: set[int] = set()  # ROM addresses used as data (imm16, ext loads)

    def byte(self, a: int) -> int:
        return self.data[a - BASE]

    def trace(self, entries: list[int]) -> None:
        todo = list(entries)
        while todo:
            a = todo.pop()
            while BASE <= a < 0xFFF0 and a not in self.insns:
                op = self.byte(a)
                if op not in OPS:
                    raise SystemExit(f"invalid 6801 opcode {op:02X} at {a:04X}")
                m, mode = OPS[op]
                n = SIZE[mode]
                arg = None
                if mode in ("imm8", "dir", "idx"):
                    arg = self.byte(a + 1)
                elif mode in ("imm16", "ext"):
                    arg = self.byte(a + 1) << 8 | self.byte(a + 2)
                elif mode == "rel":
                    off = self.byte(a + 1)
                    arg = (a + 2 + off - (0x100 if off & 0x80 else 0)) & 0xFFFF
                self.insns[a] = (m, mode, arg)
                if mode == "rel" or (m in ("jsr", "jmp") and mode in ("ext", "dir")):
                    self.code_refs.add(arg)
                    todo.append(arg)
                elif mode in ("imm16", "ext") and arg >= BASE:
                    self.data_refs.add(arg)
                if m in STOP:
                    break
                a += n

    def operand(self, m: str, mode: str, arg: int | None, labels: dict[int, str],
                names: "Names") -> str:
        if mode == "inh":
            return ""
        if mode == "idx":
            return f"{arg:#04x},x" if arg else "0,x"
        if mode == "dir":
            return "*" + (names.data(arg) or f"0x{arg:02X}")
        if mode == "imm8":
            return f"#0x{arg:02X}"
        if arg in labels:
            return ("#" if mode == "imm16" else "") + labels[arg]
        if mode == "imm16":
            name = names.shared.get(arg) if 0x0C00 <= arg < 0x1000 else None
            return "#" + (name or f"0x{arg:04X}")
        # ext: always the three-byte form, even below 0x100
        return names.data(arg) or f"0x{arg:04X}"

    def source(self, names: "Names") -> str:
        targets = self.code_refs | {a for a in self.data_refs if BASE <= a < 0xFFF0}
        targets |= {self.vector(v) for v in VECTORS if self.vector(v) >= BASE}
        labels = {a: names.code[a][0] if a in names.code else f"L_{a:04X}" for a in targets}
        for a, (name, _note) in names.code.items():
            labels.setdefault(a, name)
        out = [
            "; MCU - MC6801U4",
            "; a78-01.17, linked at 0xF000. Built by tools/build.py.",
            ";",
            "; No ROM bytes live in this repo: every range not yet disassembled is pulled in",
            "; from the verified image build/images/mcu.bin with .incbin (offset, length).",
            "; Syntax: m68hc11-elf-as. `*addr` is the two-byte direct form; a bare address",
            "; is the three-byte extended form, which the original also uses below 0x100.",
            "",
            '        .include "mcu.inc"',
            "        .section .text",
            "",
        ]
        a = BASE
        while a < 0xFFF0:
            if a in labels:
                note = names.code.get(a, (None, None))[1]
                if note:
                    out.append(f"; {note}")
                out.append(f"{labels[a] + ':':<24}; {a:04X}")
            if a in self.insns:
                m, mode, arg = self.insns[a]
                opnd = self.operand(m, mode, arg, labels, names)
                out.append(f"        {m:<7} {opnd}".rstrip())
                if m in STOP:
                    out.append("")
                a += SIZE[mode]
            else:
                end = a + 1
                while end < 0xFFF0 and end not in self.insns and end not in labels:
                    end += 1
                out.append(f'        .incbin "mcu.bin", 0x{a - BASE:04X}, 0x{end - a:04X}')
                a = end
        out += ["", "; Vectors"]
        for v, name in VECTORS.items():
            t = self.vector(v)
            out.append(f"        .word   {labels[t] if t in labels else f'0x{t:04X}'}"
                       f"{'':<8}; {v:04X} {name}")
        return "\n".join(out) + "\n"

    def vector(self, v: int) -> int:
        return self.byte(v) << 8 | self.byte(v + 1)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--roms", type=Path, help="ROM directory or zip")
    ap.add_argument("--entry", type=lambda s: int(s, 16), action="append", default=[],
                    help="extra code entry point (hex)")
    ap.add_argument("--out", type=Path, default=ROOT / "disasm" / "mcu.s")
    args = ap.parse_args()
    try:
        data = romset.images(romset.load(args.roms))["mcu.bin"]
    except romset.RomError as e:
        print(e, file=sys.stderr)
        return 1
    d = Dasm(data)
    entries = [d.vector(v) for v in VECTORS if d.vector(v) >= BASE] + args.entry
    d.trace(entries)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(d.source(Names()), encoding="utf-8", newline="\n")
    code = sum(SIZE[mode] for _m, mode, _a in d.insns.values())
    print(f"{len(d.insns)} instructions, {code:#x} code bytes of {0xFF0:#x}; "
          f"{len(d.code_refs)} code labels; written to {args.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
