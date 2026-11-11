#!/bin/bash
# Chip LVS (KLayout, GF180MCU deck in tools/lvs/) of a chip run, without the DC-DC layouts (make lvs).
#
# usage: scripts/lvs.sh <LibreLane run folder> <out folder>      (THR=<workers>, default every CPU)
#
# Layout:     <run>/final/gds/chip_top.gds, the chip before make merge.
# Schematic:  <run>/final/pnl/chip_top.pnl.v (pads, supply segments, pad ties).
# Hierarchical: croc_soc is a black box here (pins from macros/croc/croc_soc_bb.v), and in the layout a pin-only
# abstract (tools/lvs/abstract_cell.py). Its inside is checked by the LVS of the macro run. A full croc_soc in the
# chip crashes KLayout 0.30.9 (malloc in deep extraction).
# Black boxes (pins only, on both sides): croc_soc, the IO cells and the wafer.space IDs (no devices, no pins: left
# out of the schematic). The DC-DC layouts are not in this GDS and not in this netlist.
# Result: <out>/lvs_compare_summary.txt and <out>/chip_top.lyrdb (open it in KLayout's Netlist Browser).
set -e
T=$(cd "$(dirname "$0")/.." && pwd)
RUN=$(readlink -f "$1")
O=$(readlink -m "$2")
THR=${THR:-$(nproc)}
KIT=${LVS_PDK_KIT:-$T/gf180mcu/gf180mcuD/libs.ref}
L=$T/tools/lvs
# Physical-only standard cells (no devices): left out of the compare on both sides
EXCL=fillcap,endcap,filltie,mcu7t5v0__fill_
mkdir -p "$O"
echo "[LVS] run $RUN, $THR workers, results in $O"

# Schematic: the chip netlist without the wafer.space IDs, croc_soc as a black box
grep -v "gf180mcu_ws_ip__" "$RUN/final/pnl/chip_top.pnl.v" > "$O/chip_top.v"
python3 "$L/bb_cdl.py" "$T/macros/croc/croc_soc_bb.v" > "$O/croc_soc_bb.cdl"

# Standard cells: VPW folded into VSS and the device names of the deck (as manquehue_chip make lvs)
python3 "$L/fold_wells.py" --tie VPW=VSS --rename-model nfet_05v0=nmos_5p0 --rename-model pfet_05v0=pmos_5p0 \
    "$KIT/gf180mcu_fd_sc_mcu7t5v0/cdl/gf180mcu_fd_sc_mcu7t5v0.cdl" "$O/sc7t.folded.cdl" > "$O/fold_wells.log"

IO_CDL=$KIT/gf180mcu_fd_io/cdl/gf180mcu_fd_io.cdl
BB_ARGS=""
for c in "$O/croc_soc_bb.cdl" $IO_CDL; do BB_ARGS="$BB_ARGS --blackbox-cdl $c"; done
python3 "$L/verilog2spice.py" -v "$O/chip_top.v" -c "$O/sc7t.folded.cdl" $BB_ARGS -o "$O/chip_top.sp" \
    > "$O/verilog2spice.log" 2>&1 || { tail -20 "$O/verilog2spice.log"; exit 1; }

# Black boxes in the layout too: device layers removed in a copy of the GDS, metal, vias and pin labels kept
klayout -b -r "$L/abstract_cell.py" -rd input="$RUN/final/gds/chip_top.gds" -rd output="$O/chip_top.abstract.gds" \
    -rd cell=croc_soc -rd top=chip_top > "$O/abstract.log" 2>&1
BB="croc_soc,$(grep -o 'gf180mcu_fd_io__[a-z0-9_]*' "$O/chip_top.v" | sort -u | tr '\n' ',')"
BB="${BB%,}"
klayout -b -r "$L/blackbox_gds_cells.rb" -rd input="$O/chip_top.abstract.gds" \
    -rd output="$O/chip_top.lvs_blackbox.gds" -rd cells="$BB" > "$O/blackbox_gds.log" 2>&1

# Compare (deep mode, every worker)
FLAGS="--set_spice_comments --set_net_only --set_top_lvl_pins --set_combine --set_purge --set_purge_nets"
( cd "$O" && PDK_ROOT=$(dirname "$KIT") PDK=gf180mcuD python3 "$L/run_lvs.py" \
    --design="$O/chip_top.lvs_blackbox.gds" --net="$O/chip_top.sp" --gf180mcu=C --run_mode=deep --lvs_sub=VSS \
    $FLAGS --thr=$THR --blackbox_macros="$BB" --exclude_from_compare=$EXCL ) > "$O/lvs.log" 2>&1

# Second, independent comparison with a ranked summary
klayout -b -r "$L/lvs_compare.rb" -rd layout_netlist="$O/extracted_netlist_chip_top.cir" \
    -rd schematic_netlist="$O/chip_top.sp" -rd device_class_map="" -rd blackbox_macros="$BB" \
    -rd exclude_from_compare=$EXCL -rd summary="$O/lvs_compare_summary.txt" > "$O/lvs_compare.log" 2>&1 || true

if grep -q "Congratulations! Netlists match" "$O/lvs.log"; then
    echo "[LVS] MATCH (open $O/chip_top.lyrdb in KLayout to review)"
else
    echo "[LVS] MISMATCH: see $O/lvs_compare_summary.txt, and $O/chip_top.lyrdb in KLayout's Netlist Browser"
    exit 1
fi
