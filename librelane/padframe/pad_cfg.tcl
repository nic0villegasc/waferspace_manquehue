# GENERATED from 04_chip_top/padframe/padframe.yaml by 10_automation/scripts/generate_padframe.py; never edit it by hand.
# Pad placement for the OpenROAD.PadRing step (PAD_CFG). Based on LibreLane's
# scripts/openroad/common/pad_cfg.tcl (Apache-2.0, LibreLane Contributors), with every pad and
# ring breaker placed at the position computed from padframe.yaml instead of spread automatically.

source $::env(SCRIPTS_DIR)/openroad/common/set_global_connections.tcl
set_global_connections

make_io_sites \
    -horizontal_site $::env(PAD_SITE_NAME) \
    -vertical_site $::env(PAD_SITE_NAME) \
    -corner_site $::env(PAD_CORNER_SITE_NAME) \
    -offset $::env(PAD_EDGE_SPACING) \
    -rotation_horizontal $::env(PAD_ROTATION_HORIZONTAL) \
    -rotation_vertical $::env(PAD_ROTATION_VERTICAL) \
    -rotation_corner $::env(PAD_ROTATION_CORNER)

# Pads: place_pad -row <row> -location <lower-left coordinate along the side, µm> <instance>
place_pad -row IO_WEST -location 4623.5 pad_CH3_IN1 -master gf180mcu_fd_io__in_c  ;# pad 1
place_pad -row IO_WEST -location 4523.5 pad_CH2_IN2 -master gf180mcu_fd_io__in_c  ;# pad 2
place_pad -row IO_WEST -location 4423.5 pad_CH2_IN1 -master gf180mcu_fd_io__in_c  ;# pad 3
place_pad -row IO_WEST -location 4323.5 pad_CH1_IN2 -master gf180mcu_fd_io__in_c  ;# pad 4
place_pad -row IO_WEST -location 4223.5 pad_CH1_IN1 -master gf180mcu_fd_io__in_c  ;# pad 5
place_pad -row IO_WEST -location 4123.5 pad_CHx_Vs2 -master gf180mcu_fd_io__bi_24t  ;# pad 6
place_pad -row IO_WEST -location 4023.5 pad_CHx_Vs1 -master gf180mcu_fd_io__bi_24t  ;# pad 7
place_pad -row IO_WEST -location 3923.5 pad_CHx_Vg2 -master gf180mcu_fd_io__asig_5p0  ;# pad 8
place_pad -row IO_WEST -location 3823.5 pad_CHx_Vg1 -master gf180mcu_fd_io__asig_5p0  ;# pad 9
place_pad -row IO_WEST -location 3723.5 pad_GD_vss -master gf180mcu_fd_io__asig_5p0  ;# pad 10
place_pad -row IO_WEST -location 3623.5 pad_GD_vdd -master gf180mcu_fd_io__asig_5p0  ;# pad 11
place_pad -row IO_WEST -location 3523.5 pad_digital_vdd_1 -master gf180mcu_fd_io__dvdd  ;# pad 12
place_pad -row IO_WEST -location 3423.5 pad_digital_vss_1 -master gf180mcu_fd_io__dvss  ;# pad 13
place_pad -row IO_WEST -location 3323.5 pad_PS3_VSS -master gf180mcu_fd_io__asig_5p0  ;# pad 14
place_pad -row IO_WEST -location 3223.5 pad_PS2_VSS -master gf180mcu_fd_io__asig_5p0  ;# pad 15
place_pad -row IO_WEST -location 3123.5 pad_PS1_VSS -master gf180mcu_fd_io__asig_5p0  ;# pad 16
place_pad -row IO_WEST -location 3023.5 pad_PS3_VDD -master gf180mcu_fd_io__asig_5p0  ;# pad 17
place_pad -row IO_WEST -location 2923.5 pad_PS2_VDD -master gf180mcu_fd_io__asig_5p0  ;# pad 18
place_pad -row IO_WEST -location 2823.5 pad_PS1_VDD -master gf180mcu_fd_io__asig_5p0  ;# pad 19
place_pad -row IO_WEST -location 2723.5 pad_CH3_Vc -master gf180mcu_fd_io__asig_5p0  ;# pad 20
place_pad -row IO_WEST -location 2623.5 pad_CH2_Vc -master gf180mcu_fd_io__asig_5p0  ;# pad 21
place_pad -row IO_WEST -location 2523.5 pad_CH1_Vc -master gf180mcu_fd_io__asig_5p0  ;# pad 22
place_pad -row IO_WEST -location 2423.5 pad_unused_23 -master gf180mcu_fd_io__bi_24t  ;# pad 23
place_pad -row IO_WEST -location 2323.5 pad_unused_24 -master gf180mcu_fd_io__bi_24t  ;# pad 24
place_pad -row IO_WEST -location 2223.5 pad_unused_25 -master gf180mcu_fd_io__bi_24t  ;# pad 25
place_pad -row IO_WEST -location 2123.5 pad_unused_26 -master gf180mcu_fd_io__bi_24t  ;# pad 26
place_pad -row IO_WEST -location 2023.5 pad_unused_27 -master gf180mcu_fd_io__bi_24t  ;# pad 27
place_pad -row IO_WEST -location 1923.5 pad_unused_28 -master gf180mcu_fd_io__bi_24t  ;# pad 28
place_pad -row IO_WEST -location 1823.5 pad_unused_29 -master gf180mcu_fd_io__bi_24t  ;# pad 29
place_pad -row IO_WEST -location 1723.5 pad_unused_30 -master gf180mcu_fd_io__bi_24t  ;# pad 30
place_pad -row IO_WEST -location 1623.5 pad_unused_31 -master gf180mcu_fd_io__bi_24t  ;# pad 31
place_pad -row IO_WEST -location 1523.5 pad_unused_32 -master gf180mcu_fd_io__bi_24t  ;# pad 32
place_pad -row IO_WEST -location 1423.5 pad_unused_33 -master gf180mcu_fd_io__bi_24t  ;# pad 33
place_pad -row IO_WEST -location 1323.5 pad_unused_34 -master gf180mcu_fd_io__bi_24t  ;# pad 34
place_pad -row IO_WEST -location 1223.5 pad_rf_rstn_o -master gf180mcu_fd_io__bi_24t  ;# pad 35
place_pad -row IO_WEST -location 1123.5 pad_rf_dio0_i -master gf180mcu_fd_io__in_c  ;# pad 36
place_pad -row IO_WEST -location 1023.5 pad_scan_en_i -master gf180mcu_fd_io__bi_24t  ;# pad 37
place_pad -row IO_WEST -location 923.5 pad_scan_out_o -master gf180mcu_fd_io__bi_24t  ;# pad 38
place_pad -row IO_WEST -location 823.5 pad_CROC_vdd_1 -master gf180mcu_fd_io__dvdd  ;# pad 39
place_pad -row IO_WEST -location 723.5 pad_CROC_vss_1 -master gf180mcu_fd_io__dvss  ;# pad 40
place_pad -row IO_WEST -location 623.5 pad_scan_in_i -master gf180mcu_fd_io__bi_24t  ;# pad 41
place_pad -row IO_WEST -location 523.5 pad_afe_irq_i -master gf180mcu_fd_io__bi_24t  ;# pad 42
place_pad -row IO_WEST -location 423.5 pad_spi_sd_i -master gf180mcu_fd_io__bi_24t  ;# pad 43
place_pad -row IO_SOUTH -location 410.5 pad_spi_sd_o -master gf180mcu_fd_io__bi_24t  ;# pad 44
place_pad -row IO_SOUTH -location 514.5 pad_spi_cs1_o -master gf180mcu_fd_io__bi_24t  ;# pad 45
place_pad -row IO_SOUTH -location 618.5 pad_spi_cs0_o -master gf180mcu_fd_io__bi_24t  ;# pad 46
place_pad -row IO_SOUTH -location 722.5 pad_spi_sck_o -master gf180mcu_fd_io__bi_24t  ;# pad 47
place_pad -row IO_SOUTH -location 826.5 pad_gpio1_io -master gf180mcu_fd_io__bi_24t  ;# pad 48
place_pad -row IO_SOUTH -location 930.5 pad_gpio0_io -master gf180mcu_fd_io__bi_24t  ;# pad 49
place_pad -row IO_SOUTH -location 1034.5 pad_CROC_vdd_2 -master gf180mcu_fd_io__dvdd  ;# pad 50
place_pad -row IO_SOUTH -location 1138.5 pad_CROC_vss_2 -master gf180mcu_fd_io__dvss  ;# pad 51
place_pad -row IO_SOUTH -location 1242.5 pad_qspi_sd3_io -master gf180mcu_fd_io__bi_24t  ;# pad 52
place_pad -row IO_SOUTH -location 1346.5 pad_qspi_sd2_io -master gf180mcu_fd_io__bi_24t  ;# pad 53
place_pad -row IO_SOUTH -location 1450.5 pad_qspi_sd1_io -master gf180mcu_fd_io__bi_24t  ;# pad 54
place_pad -row IO_EAST -location 423.5 pad_qspi_sd0_io -master gf180mcu_fd_io__bi_24t  ;# pad 55
place_pad -row IO_EAST -location 523.5 pad_qspi_cs2_o -master gf180mcu_fd_io__bi_24t  ;# pad 56
place_pad -row IO_EAST -location 623.5 pad_qspi_cs1_o -master gf180mcu_fd_io__bi_24t  ;# pad 57
place_pad -row IO_EAST -location 723.5 pad_qspi_cs0_o -master gf180mcu_fd_io__bi_24t  ;# pad 58
place_pad -row IO_EAST -location 823.5 pad_qspi_clk_o -master gf180mcu_fd_io__bi_24t  ;# pad 59
place_pad -row IO_EAST -location 923.5 pad_uart_tx_o -master gf180mcu_fd_io__bi_24t  ;# pad 60
place_pad -row IO_EAST -location 1023.5 pad_uart_rx_i -master gf180mcu_fd_io__bi_24t  ;# pad 61
place_pad -row IO_EAST -location 1123.5 pad_jtag_tdo_o -master gf180mcu_fd_io__bi_24t  ;# pad 62
place_pad -row IO_EAST -location 1223.5 pad_jtag_tdi_i -master gf180mcu_fd_io__bi_24t  ;# pad 63
place_pad -row IO_EAST -location 1323.5 pad_jtag_tms_i -master gf180mcu_fd_io__bi_24t  ;# pad 64
place_pad -row IO_EAST -location 1423.5 pad_jtag_trst_ni -master gf180mcu_fd_io__in_c  ;# pad 65
place_pad -row IO_EAST -location 1523.5 pad_jtag_tck_i -master gf180mcu_fd_io__in_s  ;# pad 66
place_pad -row IO_EAST -location 1623.5 pad_status_o -master gf180mcu_fd_io__bi_24t  ;# pad 67
place_pad -row IO_EAST -location 1723.5 pad_CROC_vdd_3 -master gf180mcu_fd_io__dvdd  ;# pad 68
place_pad -row IO_EAST -location 1823.5 pad_CROC_vss_3 -master gf180mcu_fd_io__dvss  ;# pad 69
place_pad -row IO_EAST -location 1923.5 pad_testmode_i -master gf180mcu_fd_io__in_c  ;# pad 70
place_pad -row IO_EAST -location 2023.5 pad_ref_clk_i -master gf180mcu_fd_io__in_s  ;# pad 71
place_pad -row IO_EAST -location 2123.5 pad_rst_ni -master gf180mcu_fd_io__in_c  ;# pad 72
place_pad -row IO_EAST -location 2223.5 pad_clk_i -master gf180mcu_fd_io__in_s  ;# pad 73
place_pad -row IO_EAST -location 2323.5 pad_CROC_vss_4 -master gf180mcu_fd_io__dvss  ;# pad 74
place_pad -row IO_EAST -location 2423.5 pad_CROC_vdd_4 -master gf180mcu_fd_io__dvdd  ;# pad 75
place_pad -row IO_EAST -location 2523.5 pad_unused_76 -master gf180mcu_fd_io__bi_24t  ;# pad 76
place_pad -row IO_EAST -location 2623.5 pad_unused_77 -master gf180mcu_fd_io__bi_24t  ;# pad 77
place_pad -row IO_EAST -location 2723.5 pad_unused_78 -master gf180mcu_fd_io__bi_24t  ;# pad 78
place_pad -row IO_EAST -location 2823.5 pad_unused_79 -master gf180mcu_fd_io__bi_24t  ;# pad 79
place_pad -row IO_EAST -location 2923.5 pad_unused_80 -master gf180mcu_fd_io__bi_24t  ;# pad 80
place_pad -row IO_EAST -location 3023.5 pad_unused_81 -master gf180mcu_fd_io__bi_24t  ;# pad 81
place_pad -row IO_EAST -location 3123.5 pad_unused_82 -master gf180mcu_fd_io__bi_24t  ;# pad 82
place_pad -row IO_EAST -location 3223.5 pad_digital_vss_2 -master gf180mcu_fd_io__dvss  ;# pad 83
place_pad -row IO_EAST -location 3323.5 pad_digital_vdd_2 -master gf180mcu_fd_io__dvdd  ;# pad 84
place_pad -row IO_EAST -location 3423.5 pad_CH_sel -master gf180mcu_fd_io__in_c  ;# pad 85
place_pad -row IO_EAST -location 3523.5 pad_digital_vdd_3 -master gf180mcu_fd_io__dvdd  ;# pad 86
place_pad -row IO_EAST -location 3623.5 pad_digital_vss_3 -master gf180mcu_fd_io__dvss  ;# pad 87
place_pad -row IO_EAST -location 3723.5 pad_VCO_sel -master gf180mcu_fd_io__in_c  ;# pad 88
place_pad -row IO_EAST -location 3823.5 pad_PWM_sel -master gf180mcu_fd_io__in_c  ;# pad 89
place_pad -row IO_EAST -location 3923.5 pad_Sat_sel -master gf180mcu_fd_io__in_c  ;# pad 90
place_pad -row IO_EAST -location 4023.5 pad_Diff_sel -master gf180mcu_fd_io__in_c  ;# pad 91
place_pad -row IO_EAST -location 4123.5 pad_CH_sel0 -master gf180mcu_fd_io__bi_24t  ;# pad 92
place_pad -row IO_EAST -location 4223.5 pad_CH_out_sel1 -master gf180mcu_fd_io__in_c  ;# pad 93
place_pad -row IO_EAST -location 4323.5 pad_CH_out_sel0 -master gf180mcu_fd_io__in_c  ;# pad 94
place_pad -row IO_EAST -location 4423.5 pad_VCO_vss -master gf180mcu_fd_io__asig_5p0  ;# pad 95
place_pad -row IO_EAST -location 4523.5 pad_VCO_vdd -master gf180mcu_fd_io__asig_5p0  ;# pad 96
place_pad -row IO_EAST -location 4623.5 pad_V_REF -master gf180mcu_fd_io__asig_5p0  ;# pad 97
place_pad -row IO_NORTH -location 1450.5 pad_V_FB -master gf180mcu_fd_io__asig_5p0  ;# pad 98
place_pad -row IO_NORTH -location 1346.5 pad_VCOR -master gf180mcu_fd_io__bi_24t  ;# pad 99
place_pad -row IO_NORTH -location 1242.5 pad_VCOF -master gf180mcu_fd_io__bi_24t  ;# pad 100
place_pad -row IO_NORTH -location 1138.5 pad_VCDLR -master gf180mcu_fd_io__bi_24t  ;# pad 101
place_pad -row IO_NORTH -location 1034.5 pad_VCDLF -master gf180mcu_fd_io__bi_24t  ;# pad 102
place_pad -row IO_NORTH -location 930.5 pad_digital_vdd_4 -master gf180mcu_fd_io__dvdd  ;# pad 103
place_pad -row IO_NORTH -location 826.5 pad_digital_vss_4 -master gf180mcu_fd_io__dvss  ;# pad 104
place_pad -row IO_NORTH -location 722.5 pad_CHx_VCOR -master gf180mcu_fd_io__bi_24t  ;# pad 105
place_pad -row IO_NORTH -location 618.5 pad_CHx_VCOF -master gf180mcu_fd_io__bi_24t  ;# pad 106
place_pad -row IO_NORTH -location 514.5 pad_CHx_PD -master gf180mcu_fd_io__bi_24t  ;# pad 107
place_pad -row IO_NORTH -location 410.5 pad_CH3_IN2 -master gf180mcu_fd_io__in_c  ;# pad 108

# Ring breakers
place_pad -row IO_WEST -location 2508.5 brk_after_22 -master gf180mcu_fd_io__brk5
place_pad -row IO_EAST -location 2508.5 brk_after_75 -master gf180mcu_fd_io__brk5

place_corners $::env(PAD_CORNER)
place_io_fill -row IO_NORTH {*}$::env(PAD_FILLERS)
place_io_fill -row IO_SOUTH {*}$::env(PAD_FILLERS)
place_io_fill -row IO_WEST {*}$::env(PAD_FILLERS)
place_io_fill -row IO_EAST {*}$::env(PAD_FILLERS)
connect_by_abutment

# I/O terminals on the pad pins (PAD_PLACE_IO_TERMINALS, as in LibreLane's script)
if { [info exists ::env(PAD_PLACE_IO_TERMINALS)] } {
    set block [ord::get_db_block]
    foreach inst_name {pad_CH3_IN1 pad_CH2_IN2 pad_CH2_IN1 pad_CH1_IN2 pad_CH1_IN1 pad_CHx_Vs2 pad_CHx_Vs1 pad_CHx_Vg2 pad_CHx_Vg1 pad_GD_vss pad_GD_vdd pad_digital_vdd_1 pad_digital_vss_1 pad_PS3_VSS pad_PS2_VSS pad_PS1_VSS pad_PS3_VDD pad_PS2_VDD pad_PS1_VDD pad_CH3_Vc pad_CH2_Vc pad_CH1_Vc pad_unused_23 pad_unused_24 pad_unused_25 pad_unused_26 pad_unused_27 pad_unused_28 pad_unused_29 pad_unused_30 pad_unused_31 pad_unused_32 pad_unused_33 pad_unused_34 pad_rf_rstn_o pad_rf_dio0_i pad_scan_en_i pad_scan_out_o pad_CROC_vdd_1 pad_CROC_vss_1 pad_scan_in_i pad_afe_irq_i pad_spi_sd_i pad_spi_sd_o pad_spi_cs1_o pad_spi_cs0_o pad_spi_sck_o pad_gpio1_io pad_gpio0_io pad_CROC_vdd_2 pad_CROC_vss_2 pad_qspi_sd3_io pad_qspi_sd2_io pad_qspi_sd1_io pad_qspi_sd0_io pad_qspi_cs2_o pad_qspi_cs1_o pad_qspi_cs0_o pad_qspi_clk_o pad_uart_tx_o pad_uart_rx_i pad_jtag_tdo_o pad_jtag_tdi_i pad_jtag_tms_i pad_jtag_trst_ni pad_jtag_tck_i pad_status_o pad_CROC_vdd_3 pad_CROC_vss_3 pad_testmode_i pad_ref_clk_i pad_rst_ni pad_clk_i pad_CROC_vss_4 pad_CROC_vdd_4 pad_unused_76 pad_unused_77 pad_unused_78 pad_unused_79 pad_unused_80 pad_unused_81 pad_unused_82 pad_digital_vss_2 pad_digital_vdd_2 pad_CH_sel pad_digital_vdd_3 pad_digital_vss_3 pad_VCO_sel pad_PWM_sel pad_Sat_sel pad_Diff_sel pad_CH_sel0 pad_CH_out_sel1 pad_CH_out_sel0 pad_VCO_vss pad_VCO_vdd pad_V_REF pad_V_FB pad_VCOR pad_VCOF pad_VCDLR pad_VCDLF pad_digital_vdd_4 pad_digital_vss_4 pad_CHx_VCOR pad_CHx_VCOF pad_CHx_PD pad_CH3_IN2} {
        set master_name [[[$block findInst $inst_name] getMaster] getName]
        foreach master_pin $::env(PAD_PLACE_IO_TERMINALS) {
            set parts [split $master_pin /]
            if {$master_name == [lindex $parts 0]} {
                place_io_terminals $inst_name/[lindex $parts 1]
                break
            }
        }
    }
}

remove_io_rows
