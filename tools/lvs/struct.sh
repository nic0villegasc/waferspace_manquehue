#!/bin/bash
# Structural compare of a layout cell-level netlist against the source Verilog (cells as black boxes).
# usage: tools/lvs/struct.sh <top> <layout .v> <out folder> <source .v files...>
set -e
T=$(cd "$(dirname "$0")/../.." && pwd); L=$T/tools/lvs
TOP=$1; LAY=$(readlink -f "$2"); O=$(readlink -m "$3"); shift 3
LIB=$T/gf180mcu/gf180mcuD/libs.ref/gf180mcu_fd_sc_mcu9t5v0/lib/gf180mcu_fd_sc_mcu9t5v0__tt_025C_5v00.lib
mkdir -p "$O"; SRC=""; for f in "$@"; do SRC="$SRC $(readlink -f "$f")"; done
yosys -q -p "read_liberty -lib $LIB; read_verilog -sv $SRC; hierarchy -top $TOP; proc; flatten; opt_clean; write_verilog -noattr -noexpr $O/gold_flat.v" > "$O/yosys_gold.log" 2>&1
yosys -q -p "read_liberty -lib $LIB; read_verilog -sv $LAY; hierarchy -top $TOP; flatten; opt_clean; write_verilog -noattr -noexpr $O/gate_flat.v" > "$O/yosys_gate.log" 2>&1
klayout -b -r "$L/struct_compare.py" -rd gold="$O/gold_flat.v" -rd gate="$O/gate_flat.v" -rd top="$TOP" | tee "$O/struct.log"
grep -q "STRUCTURE MATCH" "$O/struct.log"
