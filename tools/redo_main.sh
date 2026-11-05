#!/bin/sh
# Rebuild all of src/main/ from the tools. The images' labels depend on each other, so the
# fixed ROM and the banks are made together, and tools/mainptrs.py labels them last.
set -e
cd "$(dirname "$0")/.."
sh tools/redo_fixed.sh
sh tools/redo_banks.sh
python tools/mainptrs.py
