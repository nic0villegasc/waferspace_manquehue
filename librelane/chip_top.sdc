current_design $::env(DESIGN_NAME)
set_units -time ns

set clock_port __VIRTUAL_CLK__
if { [info exists ::env(CLOCK_PORT)] } {
    set port_count [llength $::env(CLOCK_PORT)]

    if { $port_count == "0" } {
        puts "\[WARNING] No CLOCK_PORT found. A dummy clock will be used."
    } elseif { $port_count != "1" } {
        puts "\[WARNING] Multi-clock files are not currently supported by the base SDC file. Only the first clock will be constrained."
    }

    if { $port_count > "0" } {
        set ::clock_port [lindex $::env(CLOCK_PORT) 0]
    }
}

if { $::env(CLOCK_PORT) == $::env(CLOCK_NET) } {
    set port_args [get_ports $clock_port]
} else {
    # This should actually use CLOCK_PIN?
    set port_args [get_pins [lindex $::env(CLOCK_NET) 0]]
}

puts "\[INFO] Using clock $clock_port…"
create_clock {*}$port_args -name $clock_port -period $::env(CLOCK_PERIOD)

set input_delay_value [expr $::env(CLOCK_PERIOD) * $::env(IO_DELAY_CONSTRAINT) / 100]
set output_delay_value [expr $::env(CLOCK_PERIOD) * $::env(IO_DELAY_CONSTRAINT) / 100]
puts "\[INFO] Setting output delay to: $output_delay_value"
puts "\[INFO] Setting input delay to: $input_delay_value"

set_max_fanout $::env(MAX_FANOUT_CONSTRAINT) [current_design]
if { [info exists ::env(MAX_TRANSITION_CONSTRAINT)] } {
    set_max_transition $::env(MAX_TRANSITION_CONSTRAINT) [current_design]
}
if { [info exists ::env(MAX_CAPACITANCE_CONSTRAINT)] } {
    set_max_capacitance $::env(MAX_CAPACITANCE_CONSTRAINT) [current_design]
}

set clocks [get_clocks $clock_port]

# Every pad port of the AC3E padframe is inout, so all of them get the I/O delays: as inputs and, for the pads that
# drive, as outputs. The clock is created on the pad output (CLOCK_NET), so the delay on the clk_i port times nothing.
set clk_core_inout_ports [all_inputs]

set_input_delay -min 0 -clock $clocks $clk_core_inout_ports
set_input_delay -max $input_delay_value -clock $clocks $clk_core_inout_ports
set_output_delay $output_delay_value -clock $clocks $clk_core_inout_ports

# Output load
set cap_load [expr $::env(OUTPUT_CAP_LOAD) / 1000.0]
puts "\[INFO] Setting load to: $cap_load"
set_load $cap_load [all_outputs]

puts "\[INFO] Setting clock uncertainty to: $::env(CLOCK_UNCERTAINTY_CONSTRAINT)"
set_clock_uncertainty $::env(CLOCK_UNCERTAINTY_CONSTRAINT) $clocks

puts "\[INFO] Setting clock transition to: $::env(CLOCK_TRANSITION_CONSTRAINT)"
set_clock_transition $::env(CLOCK_TRANSITION_CONSTRAINT) $clocks

puts "\[INFO] Setting timing derate to: $::env(TIME_DERATING_CONSTRAINT)%"
set_timing_derate -early [expr 1-[expr $::env(TIME_DERATING_CONSTRAINT) / 100]]
set_timing_derate -late [expr 1+[expr $::env(TIME_DERATING_CONSTRAINT) / 100]]

if { [info exists ::env(OPENLANE_SDC_IDEAL_CLOCKS)] && $::env(OPENLANE_SDC_IDEAL_CLOCKS) } {
    unset_propagated_clock [all_clocks]
} else {
    set_propagated_clock [all_clocks]
}


# Interfaces with their own clock or no clock, as manquehue_chip scripts/chip/chip_sta.sdc (the PrimeTime chip STA).
# A set_input_delay without -add_delay replaces the clk_i delay set above on those ports.
set clk_src [get_pins [lindex $::env(CLOCK_NET) 0]]

# GPIO, UART RX, the radio DIO0 and ref_clk_i have no phase relation to clk_i on the board. Each goes into a 2-FF
# synchronizer in croc_soc, so the hold check of that first flop is not a real check. Setup stays timed.
set_false_path -hold -from [get_ports {ref_clk_i uart_rx_i rf_dio0_i gpio0_io gpio1_io}]

# QSPI flash (W25Q128JW class): timed against its SCK at the qspi_clk_o pad, a clk_i flop toggled every clk_i cycle
# (half the clk_i frequency at most). Output valid 7 ns max and held 1.5 ns min after the SCK falling edge, trace
# 1 ns. Our data changes only at the clk_i edges where SCK falls, so the hold check against the SCK rising edge at
# the same clk_i edge is not a real one: it moves to the rising edge before.
create_generated_clock -name qspi_sck -source $clk_src -divide_by 2 [get_ports qspi_clk_o]
set QSPI_IN [get_ports {qspi_sd0_io qspi_sd1_io qspi_sd2_io qspi_sd3_io}]
set_input_delay  -clock qspi_sck -clock_fall -max [expr {7.0 + 1.0}] $QSPI_IN
set_input_delay  -clock qspi_sck -clock_fall -min 1.5 -add_delay $QSPI_IN
set_multicycle_path -hold 1 -from [get_clocks $clock_port] -to [get_clocks qspi_sck]

# ADS7057 SDO on spi_sd_i (SBAS821 tables 6.5 to 6.7): timed against its SCLK at the spi_sck_o pad. Valid 10 ns max
# after the SCLK rising edge, held 2.5 ns min, level translator 5 ns, trace 1 ns.
create_generated_clock -name adc_sclk -source $clk_src -divide_by 1 -invert [get_ports spi_sck_o]
set_input_delay -clock adc_sclk -max [expr {10.0 + 5.0 + 1.0}] [get_ports spi_sd_i]
set_input_delay -clock adc_sclk -min [expr {2.5 + 1.0}] -add_delay [get_ports spi_sd_i]

set_clock_uncertainty $::env(CLOCK_UNCERTAINTY_CONSTRAINT) [get_clocks {qspi_sck adc_sclk}]
set_propagated_clock [get_clocks {qspi_sck adc_sclk}]
# The firmware sets SDO_NEG: SDO is captured by a falling-edge flop half a clock later (sdo_neg_cap_q), because the
# round trip through the SCLK and SDO pads does not fit the default capture at the slow corner. croc_soc is a timing
# model here, which merges both capture flops into one arc on its spi_sd_i pin, so this setup check can only see
# the default one. The interface is signed off in the PrimeTime chip STA of manquehue_chip (chip_sta.sdc), where the
# flops are visible. Hold stays timed.
set_false_path -setup -from [get_clocks adc_sclk] -through [get_ports spi_sd_i]
