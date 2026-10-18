#!/bin/sh
# Rebuild src/main/bank0.s, bank2.s and bank3.s from the tool. Names and notes come from
# notes/symbols.toml ([bankN.code], [bankN.data]); data ranges from notes/classmap.
set -e
cd "$(dirname "$0")/.."
python tools/symbols.py > /dev/null
# entries: the calls OBJECTS_TASK (3DF0) makes into page 2
BANK2_ENTRIES="--entry A59B --entry A2FC --entry 936A --entry 99E2 --entry 96E6 --entry 90DD
  --entry 92B6 --entry A820 --entry 9F76 --entry B9C4 --entry 8BA7 --entry AC80"
# jump tables (ADDR:COUNT), found from the TABLE_WORD callers
BANK0_TABLES="--table 8442:4 --table 8E5F:6 --table 9218:6 --table 95F9:6 --table 987D:6
  --table 9CCF:4 --table A0FB:5 --table A4BE:4 --table A80C:6 --table AAA8:4
  --table B33E:4 --table BBA7:4 --table BE8F:4"
BANK2_TABLES="--table 8AFF:54 --table 9F22:6 --table B0E7:4"
python tools/dasmz80.py main_bank0 --probe $BANK0_TABLES --out src/main/bank0.s
python tools/dasmz80.py main_bank2 --probe $BANK2_ENTRIES $BANK2_TABLES --out src/main/bank2.s
python tools/dasmz80.py main_bank3 --probe --out src/main/bank3.s
