# Power grid of the AC3E chip (PDN_CFG of config.yaml). Reduced from LibreLane's pdn_cfg.tcl
# (Apache-2.0, LibreLane Contributors, adapted from OpenLane, Efabless Corporation) to what this chip uses.
# The widths, pitches and layers come from config.yaml.

source $::env(SCRIPTS_DIR)/openroad/common/io.tcl
source $::env(SCRIPTS_DIR)/openroad/common/set_global_connections.tcl
set_global_connections

# Supply pins. Each ring segment has its own net (src/chip_top.sv), so there is no connection by pin name
# (PDN_ENABLE_GLOBAL_CONNECTIONS is off). Here only the core cells (tie cells, taps, fillers) and croc_soc go to
# VDD and VSS. The pads, breakers and IO cells keep their segment nets.
foreach {pin net type} {VDD VDD -power VNW VDD -power VSS VSS -ground VPW VSS -ground} {
    add_global_connection -net $net -inst_pattern {^(?!pad_|brk_|IO_|u_8|u_DB).*} -pin_pattern "^${pin}\$" $type
}
global_connect

set_voltage_domain -name CORE -power $::env(VDD_NET) -ground $::env(GND_NET)

# Core grid: vertical stripes on PDN_VERTICAL_LAYER and horizontal ones on PDN_HORIZONTAL_LAYER, out to the core ring.
define_pdn_grid -name stdcell_grid -starts_with POWER -voltage_domain CORE
foreach {layer width pitch offset spacing} [list \
        $::env(PDN_VERTICAL_LAYER) $::env(PDN_VWIDTH) $::env(PDN_VPITCH) $::env(PDN_VOFFSET) $::env(PDN_VSPACING) \
        $::env(PDN_HORIZONTAL_LAYER) $::env(PDN_HWIDTH) $::env(PDN_HPITCH) $::env(PDN_HOFFSET) $::env(PDN_HSPACING)] {
    add_pdn_stripe -grid stdcell_grid -layer $layer -width $width -pitch $pitch -offset $offset -spacing $spacing \
        -starts_with POWER -extend_to_core_ring
}
add_pdn_connect -grid stdcell_grid -layers "$::env(PDN_VERTICAL_LAYER) $::env(PDN_HORIZONTAL_LAYER)"

# Standard cell rails, tied to the vertical stripes.
add_pdn_stripe -grid stdcell_grid -layer $::env(PDN_RAIL_LAYER) -width $::env(PDN_RAIL_WIDTH) -followpins
add_pdn_connect -grid stdcell_grid -layers "$::env(PDN_RAIL_LAYER) $::env(PDN_VERTICAL_LAYER)"

# Core ring between the pads and the core, connected to the CROC supply pads on Metal2.
add_pdn_ring -grid stdcell_grid \
    -layers "$::env(PDN_CORE_VERTICAL_LAYER) $::env(PDN_CORE_HORIZONTAL_LAYER)" \
    -widths "$::env(PDN_CORE_RING_VWIDTH) $::env(PDN_CORE_RING_HWIDTH)" \
    -spacings "$::env(PDN_CORE_RING_VSPACING) $::env(PDN_CORE_RING_HSPACING)" \
    -core_offset "$::env(PDN_CORE_RING_VOFFSET) $::env(PDN_CORE_RING_HOFFSET)" \
    -allow_out_of_die -connect_to_pads -connect_to_pad_layers $::env(PDN_CORE_RING_CONNECT_TO_PAD_LAYERS)
add_pdn_connect -grid stdcell_grid -layers "$::env(PDN_CORE_VERTICAL_LAYER) $::env(PDN_CORE_HORIZONTAL_LAYER)"
add_pdn_connect -grid stdcell_grid -layers "$::env(PDN_CORE_VERTICAL_LAYER) Metal2"
add_pdn_connect -grid stdcell_grid -layers "$::env(PDN_CORE_HORIZONTAL_LAYER) Metal2"

# Macros (croc_soc and the wafer.space IDs): the core grid stops PDN_*_HALO from each one, and vias join the grid
# to the macro's own power pins where they cross.
define_pdn_grid -macro -default -name macro -starts_with POWER \
    -halo "$::env(PDN_HORIZONTAL_HALO) $::env(PDN_VERTICAL_HALO)"
add_pdn_connect -grid macro -layers "$::env(PDN_VERTICAL_LAYER) $::env(PDN_HORIZONTAL_LAYER)"
