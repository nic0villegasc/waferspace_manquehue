# Power grid of the AC3E chip (PDN_CFG of config.yaml). Reduced from LibreLane's pdn_cfg.tcl
# (Apache-2.0, LibreLane Contributors, adapted from OpenLane, Efabless Corporation) to what this chip uses.
#
# croc_soc fills the core and touches its left, bottom and top edges, so the core grid cannot reach the power
# ring just inside its outline. The chip grid is therefore:
#   1. core grid: vertical stripes and the standard cell rails (only the tie-cell column east of croc_soc has
#      rows), the core ring around everything, connected to the CROC supply pads;
#   2. croc grid: horizontal Metal5 straps across croc_soc's power ring, kept to the free gaps of its edge bands by
#      obstructions made from its own Metal5 obstructions and power pins;
#   3. after pdngen: each strap extended over the left core ring, with a via array to it (croc_ring_link).
# Widths, pitches and layers of the core grid come from config.yaml (PDN_*).

source $::env(SCRIPTS_DIR)/openroad/common/io.tcl
source $::env(SCRIPTS_DIR)/openroad/common/set_global_connections.tcl
set_global_connections

set ::CROC_INST i_chip_core.i_croc_soc   ;# global: read by the pdngen wrapper at the end
set block [ord::get_db_block]
set tech [ord::get_db_tech]
set dbu [$tech getDbUnitsPerMicron]

# Supply pins. Each ring segment has its own net (src/chip_top.sv), so there is no connection by pin name
# (PDN_ENABLE_GLOBAL_CONNECTIONS is off). Here only the core cells (tie cells, taps, fillers) and croc_soc go to
# VDD and VSS. The pads, breakers and IO cells keep their segment nets.
foreach {pin net type} {VDD VDD -power VNW VDD -power VSS VSS -ground VPW VSS -ground} {
    add_global_connection -net $net -inst_pattern {^(?!pad_|brk_|IO_|u_8|u_DB).*} -pin_pattern "^${pin}\$" $type
}
global_connect

set_voltage_domain -name CORE -power $::env(VDD_NET) -ground $::env(GND_NET)

# 1. Core grid: vertical stripes out to the core ring, the rails, and the ring itself.
define_pdn_grid -name stdcell_grid -starts_with POWER -voltage_domain CORE
add_pdn_stripe -grid stdcell_grid -layer $::env(PDN_VERTICAL_LAYER) -width $::env(PDN_VWIDTH) -pitch $::env(PDN_VPITCH) \
    -offset $::env(PDN_VOFFSET) -spacing $::env(PDN_VSPACING) -starts_with POWER -extend_to_core_ring
add_pdn_stripe -grid stdcell_grid -layer $::env(PDN_RAIL_LAYER) -width $::env(PDN_RAIL_WIDTH) -followpins
add_pdn_connect -grid stdcell_grid -layers "$::env(PDN_RAIL_LAYER) $::env(PDN_VERTICAL_LAYER)"
add_pdn_ring -grid stdcell_grid \
    -layers "$::env(PDN_CORE_VERTICAL_LAYER) $::env(PDN_CORE_HORIZONTAL_LAYER)" \
    -widths "$::env(PDN_CORE_RING_VWIDTH) $::env(PDN_CORE_RING_HWIDTH)" \
    -spacings "$::env(PDN_CORE_RING_VSPACING) $::env(PDN_CORE_RING_HSPACING)" \
    -core_offset "$::env(PDN_CORE_RING_VOFFSET) $::env(PDN_CORE_RING_HOFFSET)" \
    -allow_out_of_die -connect_to_pads -connect_to_pad_layers $::env(PDN_CORE_RING_CONNECT_TO_PAD_LAYERS)
add_pdn_connect -grid stdcell_grid -layers "$::env(PDN_CORE_VERTICAL_LAYER) $::env(PDN_CORE_HORIZONTAL_LAYER)"
add_pdn_connect -grid stdcell_grid -layers "$::env(PDN_CORE_VERTICAL_LAYER) Metal2"
add_pdn_connect -grid stdcell_grid -layers "$::env(PDN_CORE_HORIZONTAL_LAYER) Metal2"

# 2. croc grid. Obstructions on Metal5 over croc_soc's own Metal5 obstructions and power pins, 1 um wider, so the
# straps exist only in the free gaps of its edge bands (pdngen keeps out of obstructions, not out of a macro's own).
set croc [$block findInst $::CROC_INST]
set m5 [$tech findLayer Metal5]
set grow [expr {int(1.0 * $dbu)}]
if {[$croc getOrient] != "R0"} { error "pdn_cfg.tcl: $::CROC_INST must be unflipped (orientation N)" }
lassign [$croc getLocation] cx cy
set boxes [list]
foreach obs [[$croc getMaster] getObstructions] {
    if {[$obs getTechLayer] == $m5} { lappend boxes $obs }
}
foreach mterm [[$croc getMaster] getMTerms] {
    if {[$mterm getSigType] ni {POWER GROUND}} continue
    foreach mpin [$mterm getMPins] {
        foreach geo [$mpin getGeometry] {
            if {[$geo getTechLayer] == $m5} { lappend boxes $geo }
        }
    }
}
foreach b $boxes {
    odb::dbObstruction_create $block $m5 [expr {$cx + [$b xMin] - $grow}] [expr {$cy + [$b yMin] - $grow}] \
        [expr {$cx + [$b xMax] + $grow}] [expr {$cy + [$b yMax] + $grow}]
}
puts "\[INFO\] croc grid: [llength $boxes] Metal5 obstructions from croc_soc"

# Straps: 5 um wide in VDD/VSS pairs 40 um apart, offset 12 um, so each pair sits in a gap between croc_soc's own
# Metal5 stripes (every 20 um). The obstructions remove any strap that would still touch them.
define_pdn_grid -macro -instances [list $::CROC_INST] -name croc -starts_with POWER -halo "0 0" -grid_over_boundary
add_pdn_stripe -grid croc -layer Metal5 -width 5 -pitch 40 -offset 12 -spacing 1 -starts_with POWER
add_pdn_connect -grid croc -layers "Metal4 Metal5"

# Other macros (the wafer.space IDs): the core grid stops PDN_*_HALO from each one.
define_pdn_grid -macro -default -name macro -starts_with POWER \
    -halo "$::env(PDN_HORIZONTAL_HALO) $::env(PDN_VERTICAL_HALO)"
add_pdn_connect -grid macro -layers "$::env(PDN_VERTICAL_LAYER) $::env(PDN_HORIZONTAL_LAYER)"

# 3. The croc grid stops at croc_soc's left edge, short of the core ring. After pdngen, each strap that starts there
# is extended over the left ring bar of its own net, with an array of single-cut Metal4-Metal5 vias.
proc croc_ring_link {inst_name} {
    set block [ord::get_db_block]
    set tech [ord::get_db_tech]
    set dbu [$tech getDbUnitsPerMicron]
    set m4 [$tech findLayer Metal4]
    set m5 [$tech findLayer Metal5]
    set edge [[[$block findInst $inst_name] getBBox] xMin]
    set cut ""
    foreach v [$tech getVias] {
        if {[[$v getBottomLayer] getName] == "Metal4" && [[$v getTopLayer] getName] == "Metal5"} { set cut $v; break }
    }
    if {$cut == ""} { error "croc_ring_link: no Metal4-Metal5 via in the tech LEF" }
    set step [expr {int(1.0 * $dbu)}]
    set margin [expr {int(0.5 * $dbu)}]
    set n 0
    foreach net {VDD VSS} {
        set dbnet [$block findNet $net]
        set ring ""
        set straps [list]
        foreach sw [$dbnet getSWires] {
            foreach w [$sw getWires] {
                if {[$w isVia]} continue
                if {[$w getTechLayer] == $m4 && [$w getWireShapeType] == "RING" && [$w xMax] < $edge} { set ring $w }
                if {[$w getTechLayer] == $m5 && [$w xMin] == $edge} { lappend straps [list $sw [$w yMin] [$w yMax]] }
            }
        }
        if {$ring == ""} { error "croc_ring_link: no left core ring bar for $net" }
        set rx0 [$ring xMin]
        set rx1 [$ring xMax]
        foreach s $straps {
            lassign $s sw y0 y1
            odb::dbSBox_create $sw $m5 $rx0 $y0 $edge $y1 STRIPE
            for {set x [expr {$rx0 + $margin}]} {$x <= $rx1 - $margin} {incr x $step} {
                for {set y [expr {$y0 + $margin}]} {$y <= $y1 - $margin} {incr y $step} {
                    odb::dbSBox_create $sw $cut $x $y STRIPE
                }
            }
            incr n
        }
    }
    puts "\[INFO\] croc_ring_link: $n croc straps joined to the left core ring"
    if {$n == 0} { error "croc_ring_link: no croc strap reaches the left edge" }
}
rename ::pdngen ::pdngen_lib
proc ::pdngen {args} {
    ::pdngen_lib {*}$args
    croc_ring_link $::CROC_INST
}
