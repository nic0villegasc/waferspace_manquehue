#!/bin/bash
# Transistor-level LVS of croc_soc on its own (make lvs-croc): the macro GDS against its gate netlist
# (macros/croc/croc_soc.v) with the 7-track cells, SRAM macros as black boxes, KLayout deep mode.
# With make lvs-full (croc_soc as a pin abstract) it covers every transistor of the chip: KLayout 0.30.9 does not
# finish croc_soc inside the full chip (deep mode crashes, flat mode does not finish).
# usage: scripts/lvs_croc.sh <out folder>     (THR=<workers>, default every CPU)
set -e
T=$(cd "$(dirname "$0")/.." && pwd); L=$T/tools/lvs; O=$(readlink -m "$1"); THR=${THR:-$(nproc)}
KIT=${LVS_PDK_KIT:-$T/gf180mcu/gf180mcuD/libs.ref}
mkdir -p "$O"
python3 "$L/fold_wells.py" --tie VPW=VSS --rename-model nfet_05v0=nmos_5p0 --rename-model pfet_05v0=pmos_5p0 \
    "$KIT/gf180mcu_fd_sc_mcu7t5v0/cdl/gf180mcu_fd_sc_mcu7t5v0.cdl" "$O/sc7t.cdl" > /dev/null
SRAM_CDL=$(ls "$KIT"/gf180mcu_fd_ip_sram/cdl/gf180mcu_fd_ip_sram__sram*.cdl)
python3 "$L/verilog2spice.py" -v "$T/macros/croc/croc_soc.v" -c "$O/sc7t.cdl" $(for c in $SRAM_CDL; do echo --blackbox-cdl $c; done) \
    -o "$O/croc_soc.sp" > "$O/v2s.log" 2>&1 || { tail -5 "$O/v2s.log"; exit 1; }
BB=$(for c in $SRAM_CDL; do basename -s .cdl $c; done | tr '\n' ,); BB=${BB%,}
klayout -b -r "$L/blackbox_gds_cells.rb" -rd input="$T/macros/croc/croc_soc.gds" -rd output="$O/croc_soc.lvs.gds" -rd cells="$BB" > "$O/bb.log" 2>&1
( cd "$O" && PDK_ROOT=$(dirname "$KIT") PDK=gf180mcuD python3 "$L/run_lvs.py" --design="$O/croc_soc.lvs.gds" --net="$O/croc_soc.sp" \
    --gf180mcu=C --run_mode=deep --lvs_sub=VSS --set_spice_comments --set_net_only --set_top_lvl_pins --set_combine \
    --set_purge --set_purge_nets --thr=$THR --blackbox_macros="$BB" --exclude_from_compare=fillcap,endcap,filltie,mcu7t5v0__fill_,antenna ) \
    > "$O/lvs.log" 2>&1 || true
if grep -q "Congratulations! Netlists match" "$O/lvs.log"; then echo "[LVS-CROC] MATCH"; else echo "[LVS-CROC] MISMATCH: $O/lvs.log"; exit 1; fi
