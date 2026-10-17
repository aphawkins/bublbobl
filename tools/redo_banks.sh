#!/bin/sh
# Rebuild src/main/bank0.s, bank2.s and bank3.s from the tool. Names and notes come from
# notes/symbols.toml ([bankN.code], [bankN.data]); data ranges from notes/classmap.
set -e
cd "$(dirname "$0")/.."
python tools/symbols.py > /dev/null
# entries: the calls OBJECTS_TASK (3DF0) makes into page 2
BANK2_ENTRIES="--entry A59B --entry A2FC --entry 936A --entry 99E2 --entry 96E6 --entry 90DD
  --entry 92B6 --entry A820 --entry 9F76 --entry B9C4 --entry 8BA7 --entry AC80"
python tools/dasmz80.py main_bank0 --probe --out src/main/bank0.s
python tools/dasmz80.py main_bank2 --probe $BANK2_ENTRIES --out src/main/bank2.s
python tools/dasmz80.py main_bank3 --probe --out src/main/bank3.s
