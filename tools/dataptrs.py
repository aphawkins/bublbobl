"""Turn the pointers inside a source's .incbin ranges into .word labels.

apply() is called by the tools that know a data format (tools/soundptrs.py). It is given
where each pointer is and what it points at. Every .incbin holding a pointer or a target is
split around it, so a pointer becomes `.word LABEL` and its target gets a label: the source
is still byte-exact, and the data now moves with the code. No ROM bytes enter the source.
"""

import re

LABEL = re.compile(r"([A-Za-z_]\w*):\s*;\s*([0-9A-F]{4})")
INCBIN = re.compile(r'(\s+)\.incbin\s+("[^"]+"),\s*0x([0-9A-Fa-f]+),\s*0x([0-9A-Fa-f]+)(.*)$')


def apply(text: str, base: int, pointers: dict[int, int], kinds: dict[int, str],
          big_endian: bool = False, names: dict[int, str] | None = None,
          foreign: dict[int, str] | None = None) -> str:
    """pointers: address of a pointer -> its target. kinds: target -> label prefix.

    A target that has no label yet must lie in an .incbin. It is labelled <prefix>_<addr>, or
    with its entry in names, which also labels addresses no pointer here points at. foreign
    gives the expression for each pointer (by its address) whose target is in another image."""
    names = names or {}
    foreign = foreign or {}
    lines = text.split("\n")
    labels = {int(m.group(2), 16): m.group(1) for line in lines if (m := LABEL.match(line))}
    ranges = []
    for line in lines:
        if m := INCBIN.match(line):
            ranges.append((int(m.group(3), 16) + base, int(m.group(4), 16)))

    def inside(a: int) -> bool:
        return any(start <= a < start + n for start, n in ranges)

    for target in sorted({t for a, t in pointers.items() if a not in foreign} | set(names)):
        if target not in labels:
            if not inside(target):
                raise SystemExit(f"target {target:04X} is in code, and has no label")
            labels[target] = names.get(target) or f"{kinds[target]}_{target:04X}"
    defined = {int(m.group(2), 16) for line in lines if (m := LABEL.match(line))}

    out = []
    done = set()
    for line in lines:
        m = INCBIN.match(line)
        if not m:
            out.append(line)
            continue
        indent, name, note = m.group(1), m.group(2), m.group(5)
        start = int(m.group(3), 16) + base
        end = start + int(m.group(4), 16)
        cuts = sorted({a for a in pointers if start <= a < end}
                      | {t for t in labels if start <= t < end and t not in defined})
        at = start
        first = True

        def emit(upto: int) -> None:
            nonlocal at, first
            if upto > at:
                out.append(f"{indent}.incbin {name}, 0x{at - base:04X}, 0x{upto - at:04X}"
                           + (note if first else ""))
                first = False
                at = upto

        for cut in cuts:
            if cut < at:
                raise SystemExit(f"{cut:04X} is inside the pointer before it")
            emit(cut)
            if cut in labels and cut not in defined:
                out.append(f"{labels[cut] + ':':<24}; {cut:04X}")
            if cut in pointers:
                if cut + 2 > end:
                    raise SystemExit(f"the pointer at {cut:04X} runs out of its .incbin")
                out.append(f"{indent}.word   {foreign.get(cut) or labels[pointers[cut]]}")
                done.add(cut)
                at = cut + 2
        emit(end)
    missing = set(pointers) - done
    if missing:
        raise SystemExit(f"pointers outside any .incbin: {sorted(hex(a) for a in missing)}")
    return "\n".join(out)
