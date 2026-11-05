"""Write the sound ROM's data pointers as labels in src/sound/sound.s.

Usage: python tools/soundptrs.py

Run by tools/redo_sound.sh. The pointers are found by walking the data as the sound CPU
does (formats in notes/sound.md), from COMMAND_TABLE, COMMAND_F_TABLE, the voice tables,
the envelope tables and SSG_F_JUMPS. RECORD_TABLE holds RAM addresses, so it stays as it
is, and so do the second words of COMMAND_F_TABLE's entries and SSG_F_JUMPS's entries:
the first are never read (F3, F5, F7 go to COMMAND_F_NONE) and the second are numbers.
"""

import dataptrs
import romset
import sounddec

ROOT = romset.ROOT
SOURCE = ROOT / "src" / "sound" / "sound.s"

OPL_VOICES, OPL_VOICE_COUNT = 0x28D7, 29
OPN_VOICES, OPN_VOICE_COUNT = 0x2A8A, 59
SSG_F_JUMPS = 0x25BC
ENVELOPES = ((0x3A71, 1), (0x3A79, 20), (0x3B3D, 5), (0x3B60, 14))  # table, entries of 5 bytes
ROM_END = 0x8000


def find(d: bytes) -> tuple[dict[int, int], dict[int, str]]:
    """Every pointer in the data: {its address: target}, and {target: label prefix}."""
    snd = sounddec.Sound(d)
    pointers: dict[int, int] = {}
    kinds: dict[int, str] = {}

    def point(at: int, kind: str) -> int:
        target = snd.word(at)
        if not 0x0100 <= target < ROM_END:
            raise SystemExit(f"{at:04X}: {target:04X} is not in the ROM")
        pointers[at] = target
        kinds.setdefault(target, kind)
        return target

    def block(a: int) -> None:
        if d[a] & 0xFE in (0xF0, 0xF1):
            return
        count = d[a + 2]
        # command 2E says 255 phrases but has one (tools/sounddec.py)
        for i in range(count if count < 0x80 else 1):
            point(a + 4 + 3 * i + 1, "PHRASE")

    def entry(a: int) -> None:
        first = d[a]
        if first == 0:
            return
        if first >= sounddec.BLOCK_MIN:
            block(a)
            return
        for i in range(first):
            at = a + 1 + 2 * i
            if d[at + 1] == 0:  # high byte 0: another command to queue
                continue
            w = point(at, "BLOCK")
            if d[w] >= sounddec.BLOCK_MIN:
                block(w)

    for c in range(sounddec.COMMAND_COUNT):
        entry(point(sounddec.COMMAND_TABLE + 2 * c, "ENTRY"))
    for i in range(4):
        entry(point(sounddec.COMMAND_F_TABLE + 4 * i, "ENTRY"))
    for i in range(OPL_VOICE_COUNT):
        point(OPL_VOICES + 2 * i, "VOICE")
    for i in range(OPN_VOICE_COUNT):
        point(OPN_VOICES + 2 * i, "VOICE")
    for table, count in ENVELOPES:
        for i in range(count):
            point(table + 5 * i + 3, "POINTS")
    for i in range(16):
        point(SSG_F_JUMPS + 4 * i, "HANDLER")
    return pointers, kinds


def main() -> int:
    d = (ROOT / "build" / "images" / "sound.bin").read_bytes()
    pointers, kinds = find(d)
    text = SOURCE.read_text(encoding="utf-8")
    SOURCE.write_text(dataptrs.apply(text, 0, pointers, kinds), encoding="utf-8", newline="\n")
    print(f"{len(pointers)} pointers to {len(set(pointers.values()))} targets")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
