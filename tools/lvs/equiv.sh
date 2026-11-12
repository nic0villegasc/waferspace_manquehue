#!/bin/bash
# Logic equivalence of a cell-level netlist extracted from the layout against the source Verilog (Yosys).
# usage: tools/lvs/equiv.sh <top> <layout .v> <out folder> <source .v files...>
# Cell functions from the 9-track liberty. Port directions of the layout netlist come from the source top.
# Supply ports (dVDD, dVSS, VDD, VSS) are left out on both sides. Exit 0 when equivalent.
set -e
T=$(cd "$(dirname "$0")/../.." && pwd)
TOP=$1; LAY=$(readlink -f "$2"); O=$(readlink -m "$3"); shift 3
LIB=$T/gf180mcu/gf180mcuD/libs.ref/gf180mcu_fd_sc_mcu9t5v0/lib/gf180mcu_fd_sc_mcu9t5v0__tt_025C_5v00.lib
mkdir -p "$O"
SRC=""; for f in "$@"; do SRC="$SRC $(readlink -f "$f")"; done
cat > "$O/equiv.ys" <<YS
read_liberty -ignore_miss_func $LIB
read_verilog -sv $SRC
hierarchy -top $TOP
proc; flatten; opt_clean
select -clear
opt_clean
rename -top gold
design -stash gold
read_liberty -ignore_miss_func $LIB
read_verilog -sv $O/gate.v
hierarchy -top $TOP
flatten; opt_clean
rename -top gate
design -stash gate
design -copy-from gold -as gold gold
design -copy-from gate -as gate gate
miter -equiv -flatten -make_assert -make_outputs -ignore_gold_x gold gate miter
hierarchy -top miter
sat -verify -prove-asserts -set-init-zero -tempinduct -seq 1 -show-ports miter
YS
python3 - "$LAY" "$O/gate.v" $SRC <<PY
import re, sys
lay, out, srcs = sys.argv[1], sys.argv[2], sys.argv[3:]
txt = " ".join(open(s).read() for s in srcs)
txt = re.sub(r"//.*", "", txt)
m = re.search(r"module\s+$TOP\s*\((.*?)\);", txt, re.S)
dirs = {}
for d, names in re.findall(r"\b(input|output|inout)\s+(?:wire\s+)?([\w\s,]+?)(?=[,;)]\s*(?:input|output|inout|\)|$))", m.group(1) + ")"):
    for n in names.split(","):
        n = n.strip()
        if n: dirs[n] = d
g = open(lay).read()
g = re.sub(r"^\s*inout (\w+);", lambda mm: "  %s %s;" % (dirs.get(mm.group(1), "inout"), mm.group(1)) if dirs.get(mm.group(1), "inout") != "inout" else mm.group(0), g, flags=re.M)
have = set(re.findall(r"^\s*(?:input|output|inout) (\w+);", g, flags=re.M))
miss = [n for n in dirs if n not in have]
if miss:
    g = re.sub(r"(module\s+\w+\s*\()", lambda mm: mm.group(1) + ", ".join(miss) + ", ", g, count=1)
    g = g.replace(");\n", ");\n" + "".join("  %s %s;\n" % (dirs[n], n) for n in miss), 1)
    print("source ports with no net in the layout netlist (left open):", miss)
open(out, "w").write(g)
print("port directions from the source:", sum(1 for v in dirs.values() if v != "inout"))
PY
yosys -q -l "$O/equiv.log" "$O/equiv.ys" > /dev/null 2>&1 && { echo "[EQUIV] $TOP EQUIVALENT"; exit 0; } || { echo "[EQUIV] $TOP NOT PROVEN ($O/equiv.log)"; exit 1; }
