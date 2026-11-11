# Loaded by LibreLane's STA steps before their reports (STA_EXTRA_CORNER_TCL_FILE in config.yaml).
# The constant pad pins sit on VDD and VSS (librelane/pad_ties.tcl), and OpenSTA's power calculation crashes on
# them (segmentation fault in findInstPowers). Chip-level power is not used here: croc_soc has its own power
# sign-off and the DC-DC layouts are not in this netlist. So the power report and its metrics are left out.
proc report_power {args} { puts "report_power: skipped at chip level (librelane/sta_extra.tcl)" }
proc sta::design_power {args} { return [lrepeat 16 0.0] }
