#!/bin/sh
# Rebuild disasm/main_fixed.s with the arguments used so far and put it in src/main/fixed.s.
# Names and notes come from notes/symbols.toml, so edit them there, not in the source.
set -e
cd "$(dirname "$0")/.."
python tools/dasmz80.py main_fixed --probe --table 37FD:10 --table 50F6:3 --table 54BC:3 --table 61F4:7 \
  --table 6E50:5 --table 7B8C:4 --table 5406:8 --table 0B22:6 --entry 0538 --entry 1D17 \
  --entry 2AF8 --entry 3DF0 --entry 5B3C --out disasm/main_fixed.s
python - <<'P'
import re
fx = open('disasm/main_fixed.s', encoding='utf-8').read()
v = {'RESET': '0x0000', 'TASK_KILL': '0x0008', 'TASK_START': '0x0010', 'TASK_SLEEP': '0x0018',
     'TASK_YIELD': '0x0020', 'TASKS_CLEAR': '0x0028', 'TASK_SPAWN': '0x0030'}
fx = re.sub(r'(\bld\s+(?:bc|de|hl|sp|ix|iy),)(' + '|'.join(v) + r')\b', lambda m: m.group(1) + v[m.group(2)], fx)
open('src/main/fixed.s', 'w', encoding='utf-8', newline='\n').write(fx)
P
