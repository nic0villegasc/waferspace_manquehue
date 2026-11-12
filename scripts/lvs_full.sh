#!/bin/bash
# Full-chip transistor LVS with the DC-DC (make lvs-full).
# usage: scripts/lvs_full.sh <LibreLane run folder> <out folder>
#   CROC=abstract (default): croc_soc as a pin-only abstract (its own LVS is the macro run), deep mode.
#   CROC=flat: croc_soc at transistor level, SRAMs as black boxes, flat mode (KLayout 0.30.9 crashes in deep
#   mode on croc_soc inside the chip). Hours: run it overnight.   THR=<workers> (default every CPU)
# Layout: <run>/final/gds/chip_top_dcdc.gds (make merge). Schematic: scripts/full_sch.py (chip netlist with
# the DC-DC pads wired by name to DB_V0, VCOs_wrapper and 3 x Seg8_PS_V0) and the block netlists:
#   DB_V0         cell netlist of the layout, proven equal to the source Verilog (tools/lvs/struct.sh)
#   VCOs_wrapper  S. Sanchez VCOs_wrapper_connect.spice with the deck fix-ups (tools/lvs/block_lvs.sh)
#   Seg8_PS_V0    xschem 8-Seg_PS_V0.sch, layout finger counts of the power switches (240 / 850)
set -e
T=$(cd "$(dirname "$0")/.." && pwd); L=$T/tools/lvs
RUN=$(readlink -f "$1"); O=$(readlink -m "$2"); THR=${THR:-$(nproc)}; CROC=${CROC:-abstract}
KIT=${LVS_PDK_KIT:-$T/gf180mcu/gf180mcuD/libs.ref}
B=$T/out/blk
mkdir -p "$O"
echo "[LVS-FULL] run $RUN, croc $CROC, $THR workers, results in $O"
for f in "$B/db_v0/DB_V0.layout.v" "$B/vco_in_db/VCOs_wrapper.sp" "$B/seg8_lw/Seg8_PS_V0.sp"; do
    [ -f "$f" ] || { echo "missing block netlist $f (run the block checks first)"; exit 1; }; done
# --- standard cells, folded as in make lvs
python3 "$L/fold_wells.py" --tie VPW=VSS --rename-model nfet_05v0=nmos_5p0 --rename-model pfet_05v0=pmos_5p0 \
    "$KIT/gf180mcu_fd_sc_mcu7t5v0/cdl/gf180mcu_fd_sc_mcu7t5v0.cdl" "$O/sc7t.cdl" > /dev/null
python3 "$L/fold_wells.py" --tie VPW=VSS --rename-model nfet_05v0=nmos_5p0 --rename-model pfet_05v0=pmos_5p0 \
    "$KIT/gf180mcu_fd_sc_mcu9t5v0/cdl/gf180mcu_fd_sc_mcu9t5v0.cdl" "$O/sc9t.cdl" > /dev/null
IO_CDL=$KIT/gf180mcu_fd_io/cdl/gf180mcu_fd_io.cdl
SRAM_CDL=$(ls "$KIT"/gf180mcu_fd_ip_sram/cdl/gf180mcu_fd_ip_sram__sram*.cdl)
python3 "$L/bb_cdl.py" "$T/macros/croc/croc_soc_bb.v" > "$O/croc_soc_bb.cdl"
PAD_CDL=""; for v in "$T"/macros/pad_custom/*.v; do [ -e "$v" ] || continue
    c="$O/$(basename "$v" .v)_bb.cdl"; python3 "$L/bb_cdl.py" "$v" > "$c"; PAD_CDL="$PAD_CDL $c"; done
# --- DC-DC block netlists
sed -E "s/^(module DB_V0 \()/\1VDD, VSS, /; s/^(  inout CH1_IN1;)/  inout VDD;\n  inout VSS;\n\1/" "$B/db_v0/DB_V0.layout.v" > "$O/DB_V0.v"
python3 "$L/verilog2spice.py" -v "$O/DB_V0.v" -c "$O/sc9t.cdl" -o "$O/DB_V0.sp" > "$O/v2s_db.log" 2>&1 || { tail -5 "$O/v2s_db.log"; exit 1; }
# the 9-track cells come from sc9t.cdl only: drop the copy of inv_1 inside the VCO netlist
python3 - "$B/vco_in_db/VCOs_wrapper.sp" "$O/VCOs_wrapper.sp" <<'PY'
import sys, re
s = open(sys.argv[1]).read()
s = re.sub(r"(?ims)^\.subckt\s+gf180mcu_fd_sc_mcu9t5v0__\S+.*?^\.ends[^\n]*\n", "", s)
open(sys.argv[2], "w").write(s)
PY
cp "$B/seg8_lw/Seg8_PS_V0.sp" "$O/Seg8_PS_V0.sp"
# --- chip schematic
python3 "$T/scripts/full_sch.py" "$RUN/final/pnl/chip_top.pnl.v" "$O/chip_full.v"
BB_ARGS="--blackbox-cdl $IO_CDL"; for c in $PAD_CDL; do BB_ARGS="$BB_ARGS --blackbox-cdl $c"; done
REAL="-c $O/sc7t.cdl -c $O/DB_V0.sp -c $O/VCOs_wrapper.sp -c $O/Seg8_PS_V0.sp"
if [ "$CROC" = flat ]; then
    python3 "$L/verilog2spice.py" -v "$T/macros/croc/croc_soc.v" -c "$O/sc7t.cdl" $(for c in $SRAM_CDL; do echo --blackbox-cdl $c; done) \
        -o "$O/croc_soc.sp" > "$O/v2s_croc.log" 2>&1 || { tail -5 "$O/v2s_croc.log"; exit 1; }
    sed -i "/^\.INCLUDE/Id" "$O/croc_soc.sp"      # sc7t.cdl comes in once, through chip_top.sp
    REAL="$REAL -c $O/croc_soc.sp"
else
    BB_ARGS="$BB_ARGS --blackbox-cdl $O/croc_soc_bb.cdl"
fi
python3 "$L/verilog2spice.py" -v "$O/chip_full.v" $REAL $BB_ARGS -o "$O/chip_top.sp" > "$O/v2s_chip.log" 2>&1 || { tail -5 "$O/v2s_chip.log"; exit 1; }
# --- layout: IO cells, own pads and SRAMs as black boxes; croc_soc abstract or full
G=$RUN/final/gds/chip_top_dcdc.gds
BB="$(grep -o 'gf180mcu_fd_io__[a-z0-9_]*' "$O/chip_full.v" | sort -u | tr '\n' ',')"
BB="$BB$(for c in $SRAM_CDL; do basename -s .cdl $c; done | tr '\n' ',')"
if [ "$CROC" != flat ]; then
    klayout -b -r "$L/abstract_cell.py" -rd input="$G" -rd output="$O/chip.in.gds" -rd cell=croc_soc -rd top=chip_top > "$O/abstract.log" 2>&1
    BB="croc_soc,$BB"; G=$O/chip.in.gds
fi
BB="${BB%,}"
klayout -b -r "$L/unprefix_cells.py" -rd input="$G" -rd output="$O/chip.unprefixed.gds" > "$O/unprefix.log" 2>&1
G=$O/chip.unprefixed.gds
klayout -b -r "$L/blackbox_gds_cells.rb" -rd input="$G" -rd output="$O/chip_top.lvs.gds" -rd cells="$BB" > "$O/blackbox_gds.log" 2>&1
# --- compare
MODE=deep; [ "$CROC" = flat ] && MODE=flat
EXCL=fillcap,endcap,filltie,mcu7t5v0__fill_,mcu9t5v0__fill_,antenna
FLAGS="--set_spice_comments --set_net_only --set_top_lvl_pins --set_combine --set_purge --set_purge_nets"
echo "[LVS-FULL] compare ($MODE mode) started $(date +%H:%M)"
( cd "$O" && PDK_ROOT=$(dirname "$KIT") PDK=gf180mcuD python3 "$L/run_lvs.py" \
    --design="$O/chip_top.lvs.gds" --net="$O/chip_top.sp" --gf180mcu=C --run_mode=$MODE --lvs_sub=VSS \
    $FLAGS --thr=$THR --blackbox_macros="$BB" --exclude_from_compare=$EXCL ) > "$O/lvs.log" 2>&1 || true
if grep -q "Congratulations! Netlists match" "$O/lvs.log"; then echo "[LVS-FULL] MATCH $(date +%H:%M)"
else echo "[LVS-FULL] MISMATCH $(date +%H:%M): $O/lvs.log, $O/chip_top.lyrdb"; exit 1; fi
