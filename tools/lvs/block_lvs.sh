#!/bin/bash
# LVS of one block of a GDS against its SPICE schematic (KLayout, GF180MCU deck in tools/lvs/).
# usage: tools/lvs/block_lvs.sh <gds> <top cell> <schematic .spice> <out folder> [DNWELL subckts] [renames]
#   DNWELL subckts: comma list. renames: schematic subckt names to layout cell names, "a=b,c=d".
# The top cell is cut out with its own tree only. The schematic gets the device names of the deck
# (nfet_05v0 -> nmos_5p0, pfet_05v0 -> pmos_5p0; in the DNWELL subckts *_dw) and VPW folded into VSS, in the
# subckt definitions and in their calls. Result: <out>/lvs.log and <out>/<top>.lyrdb.
set -e
T=$(cd "$(dirname "$0")/../.." && pwd); L=$T/tools/lvs
GDS=$(readlink -f "$1"); TOP=$2; SCH=$(readlink -f "$3"); O=$(readlink -m "$4"); DW=${5:-}; RN=${6:-}
mkdir -p "$O"
klayout -b -r "$L/one_top.py" -rd input="$GDS" -rd output="$O/$TOP.gds" -rd top="$TOP" > "$O/one_top.log"
python3 "$L/fold_wells.py" --tie VPW=VSS --rename-model nfet_05v0=nmos_5p0 --rename-model pfet_05v0=pmos_5p0 \
    "$SCH" "$O/$TOP.raw.sp" > "$O/fold.log" 2>&1
python3 "$L/sch_fixup.py" "$O/$TOP.raw.sp" "$O/$TOP.sp" "$DW" "$SCH" "$RN"
( cd "$O" && PDK_ROOT=$T/gf180mcu PDK=gf180mcuD python3 "$L/run_lvs.py" --design="$O/$TOP.gds" --net="$O/$TOP.sp" \
    --gf180mcu=C --run_mode=deep --lvs_sub=VSS --set_spice_comments --set_net_only ${TOPPINS---set_top_lvl_pins} --set_combine \
    --set_purge --set_purge_nets --thr=$(nproc) ) > "$O/lvs.log" 2>&1 || true
if grep -q "Congratulations! Netlists match" "$O/lvs.log"; then echo "[LVS] $TOP MATCH"; else echo "[LVS] $TOP MISMATCH ($O/lvs.log)"; exit 1; fi
