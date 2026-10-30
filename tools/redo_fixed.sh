#!/bin/sh
# Rebuild disasm/main_fixed.s with the arguments used so far and put it in src/main/fixed.s.
# Names and notes come from notes/symbols.toml, so edit them there, not in the source.
set -e
cd "$(dirname "$0")/.."
# the banks' calls and jumps into the fixed ROM (call 0xNNNN in bank0.s and bank2.s)
BANK_CALLS="--entry 0B82 --entry 0D7F --entry 1444 --entry 1447 --entry 14E4 --entry 14E6
  --entry 16C2 --entry 16C5 --entry 16E1 --entry 189D --entry 22DA --entry 340B --entry 35FF
  --entry 4B51 --entry 4B5D --entry 65D0"
python tools/dasmz80.py main_fixed --probe --table 37FD:10 --table 50F6:3 --table 54BC:3 --table 61F4:7 \
  --table 6E50:5 --table 7B8C:4 --table 5406:8 --table 0B22:6 --entry 0538 --entry 1D17 \
  --entry 2AF8 --entry 3DF0 --entry 5B3C --entry 563F $BANK_CALLS --out disasm/main_fixed.s
python - <<'P'
import re
fx = open('disasm/main_fixed.s', encoding='utf-8').read()
v = {'RESET': '0x0000', 'TASK_KILL': '0x0008', 'TASK_START': '0x0010', 'TASK_SLEEP': '0x0018',
     'TASK_YIELD': '0x0020', 'TASKS_CLEAR': '0x0028', 'TASK_SPAWN': '0x0030'}
fx = re.sub(r'(\bld\s+(?:bc|de|hl|sp|ix|iy),)(' + '|'.join(v) + r')\b', lambda m: m.group(1) + v[m.group(2)], fx)
# coin B's half of COIN_TABLE; the INITIALS_CODES table; GAME_VARS_CLEAR's block, which only starts at BLOWS_COUNT
for old, new in (('ld      de,0xE372', 'ld      de,COIN_TABLE+8'),
                 ('ld      de,0x37DF', 'ld      de,INITIALS_CODES'),
                 ('ld      hl,BLOWS_COUNT\n        ld      bc,0x0035', 'ld      hl,0xE5DF\n        ld      bc,0x0035')):
    assert fx.count(old) == 1, old
    fx = fx.replace(old, new)
open('src/main/fixed.s', 'w', encoding='utf-8', newline='\n').write(fx)
P
