#!/bin/sh
# Rebuild src/sound/sound.s from the tool. Names and notes come from notes/symbols.toml
# ([sound.io], [sound.mem], [sound.code], [sound.data]), so edit them there, not in the source.
set -e
cd "$(dirname "$0")/.."
python tools/symbols.py > /dev/null
# jump tables (ADDR:COUNT): COMMAND_F_JUMPS
python tools/dasmz80.py sound --table 0481:15 --out disasm/sound.s
python - <<'P'
import re
s = open('disasm/sound.s', encoding='utf-8').read()
# 8000 and 9000 as RAM bounds, not as the record and chip that share the address
s = s.replace('ld      sp,YM2203', 'ld      sp,0x9000')
s = re.sub(r'(SOUND_START:[^\n]*\n(?:[^\n]*\n){5}\s+ld\s+hl,)SSG_REC_A', r'\1RAM', s)
head = '''; Sound Z80, 3 MHz
; a78-07.46, linked at 0x0000. Built by tools/build.py.
;
; No ROM bytes live in this repo: every range not yet disassembled is pulled in
; from the verified image build/images/sound.bin with .incbin (offset, length).
; Made by tools/redo_sound.sh from tools/dasmz80.py and notes/symbols.toml: edit
; the names and notes there, not here.
;
; The main CPU writes a command to the latch (NMI). Commands wait in CMD_QUEUE
; and MAIN_LOOP plays them: 00-34 through COMMAND_TABLE, EE/EF sound off/on, F0
; echo mode, F2-F8 COMMAND_F_TABLE. A command starts channel records (blocks,
; by record id); the YM2203's timer IRQ steps them: timer A the YM3526's 9
; channels, timer B the YM2203's 3 FM channels and its SSG. Each channel has two
; records, and the first takes the channel from the second while it plays.
'''
s = s.replace('; sound - first pass by tools/dasmz80.py\n; No ROM bytes: every range not disassembled is .incbin of build/images/sound.bin.\n', head)
open('src/sound/sound.s', 'w', encoding='utf-8', newline='\n').write(s)
P
