// GENERATED from 04_chip_top/padframe/padframe.yaml by 10_automation/scripts/generate_padframe.py; never edit it by hand.
// LOCALLY EDITED (test): DC-DC side (pads 1-26, 76-108) and ring breakers taken from SSanchez slot_0p5x1 / chip_top_0p5x1.svh; pads 27-75 (CROC) untouched. Regenerating with generate_padframe.py overwrites this.
// Padframe only: no core yet, so the signal pads' core-side inputs are tied off and
// their outputs (Y) are left open. Pad instance pad_<pin> is the pad of that pin.

`default_nettype none

module chip_top (
    `ifdef USE_POWER_PINS
    inout  wire VDD,
    inout  wire VSS,
    inout  wire DVDD,
    inout  wire DVSS,
    // supplies of the DC-DC ring segments (slot_0p5x1)
    inout  wire DB_DVDD,
    inout  wire VCO_VDD,
    inout  wire PS1_VDD,
    inout  wire PS2_VDD,
    inout  wire PS3_VDD,
    inout  wire GD2_VDD,
    inout  wire GD3_VDD,
    `endif
    inout  wire CH1_in1,
    inout  wire CH1_in2,
    inout  wire CH2_in1,
    inout  wire CH2_in2,
    inout  wire CH3_in1,
    inout  wire CH3_in2,
    inout  wire CH_sel,
    inout  wire CH_out_sel0,
    inout  wire CH_out_sel1,
    inout  wire Seg_sel0,
    inout  wire Seg_sel1,
    inout  wire VCO_sel,
    inout  wire PWM_sel,
    inout  wire CHx_Vs1,
    inout  wire CHx_Vs2,
    inout  wire CHx_PD,
    inout  wire CHx_VCOF,
    inout  wire CHx_VCOR,
    inout  wire V_FB,
    inout  wire V_REF,
    inout  wire [3:0] PS1_Vc,
    inout  wire [3:0] PS2_Vc,
    inout  wire [1:0] PS3_Vc,
    inout  wire unused_27,
    inout  wire unused_28,
    inout  wire unused_29,
    inout  wire unused_30,
    inout  wire unused_31,
    inout  wire unused_32,
    inout  wire unused_33,
    inout  wire unused_34,
    inout  wire rf_rstn_o,
    inout  wire rf_dio0_i,
    inout  wire scan_en_i,
    inout  wire scan_out_o,
    inout  wire scan_in_i,
    inout  wire afe_irq_i,
    inout  wire spi_sd_i,
    inout  wire spi_sd_o,
    inout  wire spi_cs1_o,
    inout  wire spi_cs0_o,
    inout  wire spi_sck_o,
    inout  wire gpio1_io,
    inout  wire gpio0_io,
    inout  wire qspi_sd3_io,
    inout  wire qspi_sd2_io,
    inout  wire qspi_sd1_io,
    inout  wire qspi_sd0_io,
    inout  wire qspi_cs2_o,
    inout  wire qspi_cs1_o,
    inout  wire qspi_cs0_o,
    inout  wire qspi_clk_o,
    inout  wire uart_tx_o,
    inout  wire uart_rx_i,
    inout  wire jtag_tdo_o,
    inout  wire jtag_tdi_i,
    inout  wire jtag_tms_i,
    inout  wire jtag_trst_ni,
    inout  wire jtag_tck_i,
    inout  wire status_o,
    inout  wire testmode_i,
    inout  wire ref_clk_i,
    inout  wire rst_ni,
    inout  wire clk_i,
);

    // In the foundry pads, the I/O and core voltage domains are shorted
    `ifdef USE_POWER_PINS
    assign VDD = DVDD;
    assign VSS = DVSS;
    `endif

    // pad 1 (west): slot0p5x1 DB_DVDD CH3_in1
    (* keep *) gf180mcu_fd_io__bi_24t pad_CH3_in1 (
        `ifdef USE_POWER_PINS
        .DVDD (DB_DVDD),
        .DVSS (DVSS),
        .VDD  (DB_DVDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b1),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (CH3_in1)
    );
    // pad 2 (west): slot0p5x1 DB_DVDD CH3_in2
    (* keep *) gf180mcu_fd_io__bi_24t pad_CH3_in2 (
        `ifdef USE_POWER_PINS
        .DVDD (DB_DVDD),
        .DVSS (DVSS),
        .VDD  (DB_DVDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b1),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (CH3_in2)
    );
    // pad 3 (west): slot0p5x1 DB_DVDD CHx_Vs1
    (* keep *) gf180mcu_fd_io__bi_24t pad_CHx_Vs1 (
        `ifdef USE_POWER_PINS
        .DVDD (DB_DVDD),
        .DVSS (DVSS),
        .VDD  (DB_DVDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b1),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b0),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (CHx_Vs1)
    );
    // pad 4 (west): slot0p5x1 DB_DVDD CHx_Vs2
    (* keep *) gf180mcu_fd_io__bi_24t pad_CHx_Vs2 (
        `ifdef USE_POWER_PINS
        .DVDD (DB_DVDD),
        .DVSS (DVSS),
        .VDD  (DB_DVDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b1),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b0),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (CHx_Vs2)
    );
    // pad 5 (west): slot0p5x1 DB_DVDD CHx_PD
    (* keep *) gf180mcu_fd_io__bi_24t pad_CHx_PD (
        `ifdef USE_POWER_PINS
        .DVDD (DB_DVDD),
        .DVSS (DVSS),
        .VDD  (DB_DVDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b1),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b0),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (CHx_PD)
    );
    // pad 6 (west): slot0p5x1 DB_DVDD CHx_VCOF
    (* keep *) gf180mcu_fd_io__bi_24t pad_CHx_VCOF (
        `ifdef USE_POWER_PINS
        .DVDD (DB_DVDD),
        .DVSS (DVSS),
        .VDD  (DB_DVDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b1),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b0),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (CHx_VCOF)
    );
    // pad 7 (west): slot0p5x1 DB_DVDD CHx_VCOR
    (* keep *) gf180mcu_fd_io__bi_24t pad_CHx_VCOR (
        `ifdef USE_POWER_PINS
        .DVDD (DB_DVDD),
        .DVSS (DVSS),
        .VDD  (DB_DVDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b1),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b0),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (CHx_VCOR)
    );
    // pad 8 (west): slot0p5x1 PS1_VDD ps1_vdd_w2
    (* keep *) gf180mcu_fd_io__dvdd pad_ps1_vdd_w2 (
        `ifdef USE_POWER_PINS
        .DVDD (PS1_VDD),
        .DVSS (DVSS),
        .VDD  (PS1_VDD),
        .VSS  (VSS)
        `endif
    );
    // pad 9 (west): slot0p5x1 PS1_VDD ps1_vdd_w1
    (* keep *) gf180mcu_fd_io__dvdd pad_ps1_vdd_w1 (
        `ifdef USE_POWER_PINS
        .DVDD (PS1_VDD),
        .DVSS (DVSS),
        .VDD  (PS1_VDD),
        .VSS  (VSS)
        `endif
    );
    // pad 10 (west): slot0p5x1 PS1_VDD ps1_vdd_w0
    (* keep *) gf180mcu_fd_io__dvdd pad_ps1_vdd_w0 (
        `ifdef USE_POWER_PINS
        .DVDD (PS1_VDD),
        .DVSS (DVSS),
        .VDD  (PS1_VDD),
        .VSS  (VSS)
        `endif
    );
    // pad 11 (west): slot0p5x1 PS1_VDD ps1_vss_w1
    (* keep *) gf180mcu_fd_io__dvss pad_ps1_vss_w1 (
        `ifdef USE_POWER_PINS
        .DVDD (PS1_VDD),
        .DVSS (DVSS),
        .VDD  (PS1_VDD),
        .VSS  (VSS)
        `endif
    );
    // pad 12 (west): slot0p5x1 PS1_VDD ps1_vss_w0
    (* keep *) gf180mcu_fd_io__dvss pad_ps1_vss_w0 (
        `ifdef USE_POWER_PINS
        .DVDD (PS1_VDD),
        .DVSS (DVSS),
        .VDD  (PS1_VDD),
        .VSS  (VSS)
        `endif
    );
    // pad 13 (west): slot0p5x1 PS2_VDD ps2_vdd_w2
    (* keep *) gf180mcu_fd_io__dvdd pad_ps2_vdd_w2 (
        `ifdef USE_POWER_PINS
        .DVDD (PS2_VDD),
        .DVSS (DVSS),
        .VDD  (PS2_VDD),
        .VSS  (VSS)
        `endif
    );
    // pad 14 (west): slot0p5x1 PS2_VDD ps2_vdd_w1
    (* keep *) gf180mcu_fd_io__dvdd pad_ps2_vdd_w1 (
        `ifdef USE_POWER_PINS
        .DVDD (PS2_VDD),
        .DVSS (DVSS),
        .VDD  (PS2_VDD),
        .VSS  (VSS)
        `endif
    );
    // pad 15 (west): slot0p5x1 PS2_VDD ps2_vdd_w0
    (* keep *) gf180mcu_fd_io__dvdd pad_ps2_vdd_w0 (
        `ifdef USE_POWER_PINS
        .DVDD (PS2_VDD),
        .DVSS (DVSS),
        .VDD  (PS2_VDD),
        .VSS  (VSS)
        `endif
    );
    // pad 16 (west): slot0p5x1 PS2_VDD ps2_vss_w1
    (* keep *) gf180mcu_fd_io__dvss pad_ps2_vss_w1 (
        `ifdef USE_POWER_PINS
        .DVDD (PS2_VDD),
        .DVSS (DVSS),
        .VDD  (PS2_VDD),
        .VSS  (VSS)
        `endif
    );
    // pad 17 (west): slot0p5x1 PS2_VDD ps2_vss_w0
    (* keep *) gf180mcu_fd_io__dvss pad_ps2_vss_w0 (
        `ifdef USE_POWER_PINS
        .DVDD (PS2_VDD),
        .DVSS (DVSS),
        .VDD  (PS2_VDD),
        .VSS  (VSS)
        `endif
    );
    // pad 18 (west): slot0p5x1 GD2_VDD gd2_vss
    (* keep *) gf180mcu_fd_io__dvss pad_gd2_vss (
        `ifdef USE_POWER_PINS
        .DVDD (GD2_VDD),
        .DVSS (DVSS),
        .VDD  (GD2_VDD),
        .VSS  (VSS)
        `endif
    );
    // pad 19 (west): slot0p5x1 GD2_VDD gd2_vdd
    (* keep *) gf180mcu_fd_io__dvdd pad_gd2_vdd (
        `ifdef USE_POWER_PINS
        .DVDD (GD2_VDD),
        .DVSS (DVSS),
        .VDD  (GD2_VDD),
        .VSS  (VSS)
        `endif
    );
    // pad 20 (west): slot0p5x1 PS3_VDD ps3_vdd_w2
    (* keep *) gf180mcu_fd_io__dvdd pad_ps3_vdd_w2 (
        `ifdef USE_POWER_PINS
        .DVDD (PS3_VDD),
        .DVSS (DVSS),
        .VDD  (PS3_VDD),
        .VSS  (VSS)
        `endif
    );
    // pad 21 (west): slot0p5x1 PS3_VDD ps3_vdd_w1
    (* keep *) gf180mcu_fd_io__dvdd pad_ps3_vdd_w1 (
        `ifdef USE_POWER_PINS
        .DVDD (PS3_VDD),
        .DVSS (DVSS),
        .VDD  (PS3_VDD),
        .VSS  (VSS)
        `endif
    );
    // pad 22 (west): slot0p5x1 PS3_VDD ps3_vdd_w0
    (* keep *) gf180mcu_fd_io__dvdd pad_ps3_vdd_w0 (
        `ifdef USE_POWER_PINS
        .DVDD (PS3_VDD),
        .DVSS (DVSS),
        .VDD  (PS3_VDD),
        .VSS  (VSS)
        `endif
    );
    // pad 23 (west): slot0p5x1 PS3_VDD ps3_vss_w1
    (* keep *) gf180mcu_fd_io__dvss pad_ps3_vss_w1 (
        `ifdef USE_POWER_PINS
        .DVDD (PS3_VDD),
        .DVSS (DVSS),
        .VDD  (PS3_VDD),
        .VSS  (VSS)
        `endif
    );
    // pad 24 (west): slot0p5x1 PS3_VDD ps3_vss_w0
    (* keep *) gf180mcu_fd_io__dvss pad_ps3_vss_w0 (
        `ifdef USE_POWER_PINS
        .DVDD (PS3_VDD),
        .DVSS (DVSS),
        .VDD  (PS3_VDD),
        .VSS  (VSS)
        `endif
    );
    // pad 25 (west): slot0p5x1 GD3_VDD gd3_vss
    (* keep *) gf180mcu_fd_io__dvss pad_gd3_vss (
        `ifdef USE_POWER_PINS
        .DVDD (GD3_VDD),
        .DVSS (DVSS),
        .VDD  (GD3_VDD),
        .VSS  (VSS)
        `endif
    );
    // pad 26 (west): slot0p5x1 GD3_VDD gd3_vdd
    (* keep *) gf180mcu_fd_io__dvdd pad_gd3_vdd (
        `ifdef USE_POWER_PINS
        .DVDD (GD3_VDD),
        .DVSS (DVSS),
        .VDD  (GD3_VDD),
        .VSS  (VSS)
        `endif
    );
    // pad 27 (west): unused pad
    (* keep *) gf180mcu_fd_io__bi_24t pad_unused_27 (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b0),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (unused_27)
    );
    // pad 28 (west): unused pad
    (* keep *) gf180mcu_fd_io__bi_24t pad_unused_28 (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b0),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (unused_28)
    );
    // pad 29 (west): unused pad
    (* keep *) gf180mcu_fd_io__bi_24t pad_unused_29 (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b0),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (unused_29)
    );
    // pad 30 (west): unused pad
    (* keep *) gf180mcu_fd_io__bi_24t pad_unused_30 (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b0),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (unused_30)
    );
    // pad 31 (west): unused pad
    (* keep *) gf180mcu_fd_io__bi_24t pad_unused_31 (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b0),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (unused_31)
    );
    // pad 32 (west): unused pad
    (* keep *) gf180mcu_fd_io__bi_24t pad_unused_32 (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b0),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (unused_32)
    );
    // pad 33 (west): unused pad
    (* keep *) gf180mcu_fd_io__bi_24t pad_unused_33 (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b0),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (unused_33)
    );
    // pad 34 (west): unused pad
    (* keep *) gf180mcu_fd_io__bi_24t pad_unused_34 (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b0),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (unused_34)
    );
    // pad 35 (west): PAD-089 rf_rstn_o
    (* keep *) gf180mcu_fd_io__bi_24t pad_rf_rstn_o (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b0),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (rf_rstn_o)
    );
    // pad 36 (west): PAD-090 rf_dio0_i
    (* keep *) gf180mcu_fd_io__in_c pad_rf_dio0_i (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (rf_dio0_i)
    );
    // pad 37 (west): PAD-075 scan_en_i
    (* keep *) gf180mcu_fd_io__bi_24t pad_scan_en_i (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b0),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (scan_en_i)
    );
    // pad 38 (west): PAD-074 scan_out_o
    (* keep *) gf180mcu_fd_io__bi_24t pad_scan_out_o (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b0),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (scan_out_o)
    );
    // pad 39 (west): PAD-043 CROC_vdd
    (* keep *) gf180mcu_fd_io__dvdd pad_CROC_vdd_1 (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS)
        `endif
    );
    // pad 40 (west): PAD-044 CROC_vss
    (* keep *) gf180mcu_fd_io__dvss pad_CROC_vss_1 (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS)
        `endif
    );
    // pad 41 (west): PAD-073 scan_in_i
    (* keep *) gf180mcu_fd_io__bi_24t pad_scan_in_i (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b0),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (scan_in_i)
    );
    // pad 42 (west): PAD-072 afe_irq_i
    (* keep *) gf180mcu_fd_io__bi_24t pad_afe_irq_i (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b0),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (afe_irq_i)
    );
    // pad 43 (west): PAD-071 spi_sd_i
    (* keep *) gf180mcu_fd_io__bi_24t pad_spi_sd_i (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b0),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (spi_sd_i)
    );
    // pad 44 (south): PAD-070 spi_sd_o
    (* keep *) gf180mcu_fd_io__bi_24t pad_spi_sd_o (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b0),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (spi_sd_o)
    );
    // pad 45 (south): PAD-069 spi_cs1_o
    (* keep *) gf180mcu_fd_io__bi_24t pad_spi_cs1_o (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b0),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (spi_cs1_o)
    );
    // pad 46 (south): PAD-068 spi_cs0_o
    (* keep *) gf180mcu_fd_io__bi_24t pad_spi_cs0_o (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b0),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (spi_cs0_o)
    );
    // pad 47 (south): PAD-067 spi_sck_o
    (* keep *) gf180mcu_fd_io__bi_24t pad_spi_sck_o (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b0),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (spi_sck_o)
    );
    // pad 48 (south): PAD-066 gpio1_io
    (* keep *) gf180mcu_fd_io__bi_24t pad_gpio1_io (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b0),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (gpio1_io)
    );
    // pad 49 (south): PAD-065 gpio0_io
    (* keep *) gf180mcu_fd_io__bi_24t pad_gpio0_io (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b0),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (gpio0_io)
    );
    // pad 50 (south): PAD-043 CROC_vdd
    (* keep *) gf180mcu_fd_io__dvdd pad_CROC_vdd_2 (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS)
        `endif
    );
    // pad 51 (south): PAD-044 CROC_vss
    (* keep *) gf180mcu_fd_io__dvss pad_CROC_vss_2 (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS)
        `endif
    );
    // pad 52 (south): PAD-064 qspi_sd3_io
    (* keep *) gf180mcu_fd_io__bi_24t pad_qspi_sd3_io (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b0),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (qspi_sd3_io)
    );
    // pad 53 (south): PAD-063 qspi_sd2_io
    (* keep *) gf180mcu_fd_io__bi_24t pad_qspi_sd2_io (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b0),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (qspi_sd2_io)
    );
    // pad 54 (south): PAD-062 qspi_sd1_io
    (* keep *) gf180mcu_fd_io__bi_24t pad_qspi_sd1_io (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b0),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (qspi_sd1_io)
    );
    // pad 55 (east): PAD-061 qspi_sd0_io
    (* keep *) gf180mcu_fd_io__bi_24t pad_qspi_sd0_io (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b0),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (qspi_sd0_io)
    );
    // pad 56 (east): PAD-060 qspi_cs2_o
    (* keep *) gf180mcu_fd_io__bi_24t pad_qspi_cs2_o (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b0),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (qspi_cs2_o)
    );
    // pad 57 (east): PAD-059 qspi_cs1_o
    (* keep *) gf180mcu_fd_io__bi_24t pad_qspi_cs1_o (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b0),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (qspi_cs1_o)
    );
    // pad 58 (east): PAD-058 qspi_cs0_o
    (* keep *) gf180mcu_fd_io__bi_24t pad_qspi_cs0_o (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b0),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (qspi_cs0_o)
    );
    // pad 59 (east): PAD-057 qspi_clk_o
    (* keep *) gf180mcu_fd_io__bi_24t pad_qspi_clk_o (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b0),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (qspi_clk_o)
    );
    // pad 60 (east): PAD-056 uart_tx_o
    (* keep *) gf180mcu_fd_io__bi_24t pad_uart_tx_o (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b0),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (uart_tx_o)
    );
    // pad 61 (east): PAD-055 uart_rx_i
    (* keep *) gf180mcu_fd_io__bi_24t pad_uart_rx_i (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b0),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (uart_rx_i)
    );
    // pad 62 (east): PAD-054 jtag_tdo_o
    (* keep *) gf180mcu_fd_io__bi_24t pad_jtag_tdo_o (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b0),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (jtag_tdo_o)
    );
    // pad 63 (east): PAD-053 jtag_tdi_i
    (* keep *) gf180mcu_fd_io__bi_24t pad_jtag_tdi_i (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b0),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (jtag_tdi_i)
    );
    // pad 64 (east): PAD-052 jtag_tms_i
    (* keep *) gf180mcu_fd_io__bi_24t pad_jtag_tms_i (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b0),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (jtag_tms_i)
    );
    // pad 65 (east): PAD-051 jtag_trst_ni
    (* keep *) gf180mcu_fd_io__in_c pad_jtag_trst_ni (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (jtag_trst_ni)
    );
    // pad 66 (east): PAD-050 jtag_tck_i
    (* keep *) gf180mcu_fd_io__in_s pad_jtag_tck_i (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (jtag_tck_i)
    );
    // pad 67 (east): PAD-049 status_o
    (* keep *) gf180mcu_fd_io__bi_24t pad_status_o (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b0),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (status_o)
    );
    // pad 68 (east): PAD-043 CROC_vdd
    (* keep *) gf180mcu_fd_io__dvdd pad_CROC_vdd_3 (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS)
        `endif
    );
    // pad 69 (east): PAD-044 CROC_vss
    (* keep *) gf180mcu_fd_io__dvss pad_CROC_vss_3 (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS)
        `endif
    );
    // pad 70 (east): PAD-048 testmode_i
    (* keep *) gf180mcu_fd_io__in_c pad_testmode_i (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (testmode_i)
    );
    // pad 71 (east): PAD-047 ref_clk_i
    (* keep *) gf180mcu_fd_io__in_s pad_ref_clk_i (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (ref_clk_i)
    );
    // pad 72 (east): PAD-046 rst_ni
    (* keep *) gf180mcu_fd_io__in_c pad_rst_ni (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (rst_ni)
    );
    // pad 73 (east): PAD-045 clk_i
    (* keep *) gf180mcu_fd_io__in_s pad_clk_i (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (clk_i)
    );
    // pad 74 (east): PAD-044 CROC_vss
    (* keep *) gf180mcu_fd_io__dvss pad_CROC_vss_4 (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS)
        `endif
    );
    // pad 75 (east): PAD-043 CROC_vdd
    (* keep *) gf180mcu_fd_io__dvdd pad_CROC_vdd_4 (
        `ifdef USE_POWER_PINS
        .DVDD (DVDD),
        .DVSS (DVSS),
        .VDD  (VDD),
        .VSS  (VSS)
        `endif
    );
    // pad 76 (east): slot0p5x1 PS3_VDD ps3_vss_e
    (* keep *) gf180mcu_fd_io__dvss pad_ps3_vss_e (
        `ifdef USE_POWER_PINS
        .DVDD (PS3_VDD),
        .DVSS (DVSS),
        .VDD  (PS3_VDD),
        .VSS  (VSS)
        `endif
    );
    // pad 77 (east): slot0p5x1 PS3_VDD PS3_Vc[0]
    (* keep *) gf180mcu_fd_io__asig_5p0 pad_PS3_Vc_0 (
        `ifdef USE_POWER_PINS
        .DVDD (PS3_VDD),
        .DVSS (DVSS),
        .VDD  (PS3_VDD),
        .VSS  (VSS),
        `endif
        .ASIG5V (PS3_Vc[0])
    );
    // pad 78 (east): slot0p5x1 PS3_VDD PS3_Vc[1]
    (* keep *) gf180mcu_fd_io__asig_5p0 pad_PS3_Vc_1 (
        `ifdef USE_POWER_PINS
        .DVDD (PS3_VDD),
        .DVSS (DVSS),
        .VDD  (PS3_VDD),
        .VSS  (VSS),
        `endif
        .ASIG5V (PS3_Vc[1])
    );
    // pad 79 (east): slot0p5x1 PS3_VDD ps3_vdd_e
    (* keep *) gf180mcu_fd_io__dvdd pad_ps3_vdd_e (
        `ifdef USE_POWER_PINS
        .DVDD (PS3_VDD),
        .DVSS (DVSS),
        .VDD  (PS3_VDD),
        .VSS  (VSS)
        `endif
    );
    // pad 80 (east): slot0p5x1 PS2_VDD ps2_vss_e
    (* keep *) gf180mcu_fd_io__dvss pad_ps2_vss_e (
        `ifdef USE_POWER_PINS
        .DVDD (PS2_VDD),
        .DVSS (DVSS),
        .VDD  (PS2_VDD),
        .VSS  (VSS)
        `endif
    );
    // pad 81 (east): slot0p5x1 PS2_VDD PS2_Vc[0]
    (* keep *) gf180mcu_fd_io__asig_5p0 pad_PS2_Vc_0 (
        `ifdef USE_POWER_PINS
        .DVDD (PS2_VDD),
        .DVSS (DVSS),
        .VDD  (PS2_VDD),
        .VSS  (VSS),
        `endif
        .ASIG5V (PS2_Vc[0])
    );
    // pad 82 (east): slot0p5x1 PS2_VDD PS2_Vc[1]
    (* keep *) gf180mcu_fd_io__asig_5p0 pad_PS2_Vc_1 (
        `ifdef USE_POWER_PINS
        .DVDD (PS2_VDD),
        .DVSS (DVSS),
        .VDD  (PS2_VDD),
        .VSS  (VSS),
        `endif
        .ASIG5V (PS2_Vc[1])
    );
    // pad 83 (east): slot0p5x1 PS2_VDD PS2_Vc[2]
    (* keep *) gf180mcu_fd_io__asig_5p0 pad_PS2_Vc_2 (
        `ifdef USE_POWER_PINS
        .DVDD (PS2_VDD),
        .DVSS (DVSS),
        .VDD  (PS2_VDD),
        .VSS  (VSS),
        `endif
        .ASIG5V (PS2_Vc[2])
    );
    // pad 84 (east): slot0p5x1 PS2_VDD PS2_Vc[3]
    (* keep *) gf180mcu_fd_io__asig_5p0 pad_PS2_Vc_3 (
        `ifdef USE_POWER_PINS
        .DVDD (PS2_VDD),
        .DVSS (DVSS),
        .VDD  (PS2_VDD),
        .VSS  (VSS),
        `endif
        .ASIG5V (PS2_Vc[3])
    );
    // pad 85 (east): slot0p5x1 PS2_VDD ps2_vdd_e
    (* keep *) gf180mcu_fd_io__dvdd pad_ps2_vdd_e (
        `ifdef USE_POWER_PINS
        .DVDD (PS2_VDD),
        .DVSS (DVSS),
        .VDD  (PS2_VDD),
        .VSS  (VSS)
        `endif
    );
    // pad 86 (east): slot0p5x1 PS1_VDD ps1_vss_e
    (* keep *) gf180mcu_fd_io__dvss pad_ps1_vss_e (
        `ifdef USE_POWER_PINS
        .DVDD (PS1_VDD),
        .DVSS (DVSS),
        .VDD  (PS1_VDD),
        .VSS  (VSS)
        `endif
    );
    // pad 87 (east): slot0p5x1 PS1_VDD PS1_Vc[0]
    (* keep *) gf180mcu_fd_io__asig_5p0 pad_PS1_Vc_0 (
        `ifdef USE_POWER_PINS
        .DVDD (PS1_VDD),
        .DVSS (DVSS),
        .VDD  (PS1_VDD),
        .VSS  (VSS),
        `endif
        .ASIG5V (PS1_Vc[0])
    );
    // pad 88 (east): slot0p5x1 PS1_VDD PS1_Vc[1]
    (* keep *) gf180mcu_fd_io__asig_5p0 pad_PS1_Vc_1 (
        `ifdef USE_POWER_PINS
        .DVDD (PS1_VDD),
        .DVSS (DVSS),
        .VDD  (PS1_VDD),
        .VSS  (VSS),
        `endif
        .ASIG5V (PS1_Vc[1])
    );
    // pad 89 (east): slot0p5x1 PS1_VDD PS1_Vc[2]
    (* keep *) gf180mcu_fd_io__asig_5p0 pad_PS1_Vc_2 (
        `ifdef USE_POWER_PINS
        .DVDD (PS1_VDD),
        .DVSS (DVSS),
        .VDD  (PS1_VDD),
        .VSS  (VSS),
        `endif
        .ASIG5V (PS1_Vc[2])
    );
    // pad 90 (east): slot0p5x1 PS1_VDD PS1_Vc[3]
    (* keep *) gf180mcu_fd_io__asig_5p0 pad_PS1_Vc_3 (
        `ifdef USE_POWER_PINS
        .DVDD (PS1_VDD),
        .DVSS (DVSS),
        .VDD  (PS1_VDD),
        .VSS  (VSS),
        `endif
        .ASIG5V (PS1_Vc[3])
    );
    // pad 91 (east): slot0p5x1 PS1_VDD ps1_vdd_e
    (* keep *) gf180mcu_fd_io__dvdd pad_ps1_vdd_e (
        `ifdef USE_POWER_PINS
        .DVDD (PS1_VDD),
        .DVSS (DVSS),
        .VDD  (PS1_VDD),
        .VSS  (VSS)
        `endif
    );
    // pad 92 (east): slot0p5x1 VCO_VDD V_REF
    (* keep *) gf180mcu_fd_io__asig_5p0 pad_V_REF (
        `ifdef USE_POWER_PINS
        .DVDD (VCO_VDD),
        .DVSS (DVSS),
        .VDD  (VCO_VDD),
        .VSS  (VSS),
        `endif
        .ASIG5V (V_REF)
    );
    // pad 93 (east): slot0p5x1 VCO_VDD V_FB
    (* keep *) gf180mcu_fd_io__asig_5p0 pad_V_FB (
        `ifdef USE_POWER_PINS
        .DVDD (VCO_VDD),
        .DVSS (DVSS),
        .VDD  (VCO_VDD),
        .VSS  (VSS),
        `endif
        .ASIG5V (V_FB)
    );
    // pad 94 (east): slot0p5x1 VCO_VDD vco_vss
    (* keep *) gf180mcu_fd_io__dvss pad_vco_vss (
        `ifdef USE_POWER_PINS
        .DVDD (VCO_VDD),
        .DVSS (DVSS),
        .VDD  (VCO_VDD),
        .VSS  (VSS)
        `endif
    );
    // pad 95 (east): slot0p5x1 VCO_VDD vco_vdd
    (* keep *) gf180mcu_fd_io__dvdd pad_vco_vdd (
        `ifdef USE_POWER_PINS
        .DVDD (VCO_VDD),
        .DVSS (DVSS),
        .VDD  (VCO_VDD),
        .VSS  (VSS)
        `endif
    );
    // pad 96 (east): slot0p5x1 DB_DVDD PWM_sel
    (* keep *) gf180mcu_fd_io__bi_24t pad_PWM_sel (
        `ifdef USE_POWER_PINS
        .DVDD (DB_DVDD),
        .DVSS (DVSS),
        .VDD  (DB_DVDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b1),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (PWM_sel)
    );
    // pad 97 (east): slot0p5x1 DB_DVDD VCO_sel
    (* keep *) gf180mcu_fd_io__bi_24t pad_VCO_sel (
        `ifdef USE_POWER_PINS
        .DVDD (DB_DVDD),
        .DVSS (DVSS),
        .VDD  (DB_DVDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b1),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (VCO_sel)
    );
    // pad 98 (north): slot0p5x1 DB_DVDD Seg_sel0
    (* keep *) gf180mcu_fd_io__bi_24t pad_Seg_sel0 (
        `ifdef USE_POWER_PINS
        .DVDD (DB_DVDD),
        .DVSS (DVSS),
        .VDD  (DB_DVDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b1),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (Seg_sel0)
    );
    // pad 99 (north): slot0p5x1 DB_DVDD Seg_sel1
    (* keep *) gf180mcu_fd_io__bi_24t pad_Seg_sel1 (
        `ifdef USE_POWER_PINS
        .DVDD (DB_DVDD),
        .DVSS (DVSS),
        .VDD  (DB_DVDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b1),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (Seg_sel1)
    );
    // pad 100 (north): slot0p5x1 DB_DVDD CH_out_sel0
    (* keep *) gf180mcu_fd_io__bi_24t pad_CH_out_sel0 (
        `ifdef USE_POWER_PINS
        .DVDD (DB_DVDD),
        .DVSS (DVSS),
        .VDD  (DB_DVDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b1),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (CH_out_sel0)
    );
    // pad 101 (north): slot0p5x1 DB_DVDD CH_out_sel1
    (* keep *) gf180mcu_fd_io__bi_24t pad_CH_out_sel1 (
        `ifdef USE_POWER_PINS
        .DVDD (DB_DVDD),
        .DVSS (DVSS),
        .VDD  (DB_DVDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b1),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (CH_out_sel1)
    );
    // pad 102 (north): slot0p5x1 DB_DVDD CH_sel
    (* keep *) gf180mcu_fd_io__bi_24t pad_CH_sel (
        `ifdef USE_POWER_PINS
        .DVDD (DB_DVDD),
        .DVSS (DVSS),
        .VDD  (DB_DVDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b1),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (CH_sel)
    );
    // pad 103 (north): slot0p5x1 DB_DVDD db_dvss
    (* keep *) gf180mcu_fd_io__dvss pad_db_dvss (
        `ifdef USE_POWER_PINS
        .DVDD (DB_DVDD),
        .DVSS (DVSS),
        .VDD  (DB_DVDD),
        .VSS  (VSS)
        `endif
    );
    // pad 104 (north): slot0p5x1 DB_DVDD db_dvdd
    (* keep *) gf180mcu_fd_io__dvdd pad_db_dvdd (
        `ifdef USE_POWER_PINS
        .DVDD (DB_DVDD),
        .DVSS (DVSS),
        .VDD  (DB_DVDD),
        .VSS  (VSS)
        `endif
    );
    // pad 105 (north): slot0p5x1 DB_DVDD CH1_in1
    (* keep *) gf180mcu_fd_io__bi_24t pad_CH1_in1 (
        `ifdef USE_POWER_PINS
        .DVDD (DB_DVDD),
        .DVSS (DVSS),
        .VDD  (DB_DVDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b1),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (CH1_in1)
    );
    // pad 106 (north): slot0p5x1 DB_DVDD CH1_in2
    (* keep *) gf180mcu_fd_io__bi_24t pad_CH1_in2 (
        `ifdef USE_POWER_PINS
        .DVDD (DB_DVDD),
        .DVSS (DVSS),
        .VDD  (DB_DVDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b1),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (CH1_in2)
    );
    // pad 107 (north): slot0p5x1 DB_DVDD CH2_in1
    (* keep *) gf180mcu_fd_io__bi_24t pad_CH2_in1 (
        `ifdef USE_POWER_PINS
        .DVDD (DB_DVDD),
        .DVSS (DVSS),
        .VDD  (DB_DVDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b1),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (CH2_in1)
    );
    // pad 108 (north): slot0p5x1 DB_DVDD CH2_in2
    (* keep *) gf180mcu_fd_io__bi_24t pad_CH2_in2 (
        `ifdef USE_POWER_PINS
        .DVDD (DB_DVDD),
        .DVSS (DVSS),
        .VDD  (DB_DVDD),
        .VSS  (VSS),
        `endif
        .A     (1'b0),
        .OE    (1'b0),
        .CS    (1'b0),
        .SL    (1'b0),
        .IE    (1'b1),
        .PU    (1'b0),
        .PD    (1'b0),
        .Y     (),
        .PAD   (CH2_in2)
    );
    // ring breaker after pad 7: cuts DVDD, DVSS and VDD; VSS runs through
    (* keep *) gf180mcu_fd_io__brk5 brk_after_7 (
        `ifdef USE_POWER_PINS
        .VSS (VSS)
        `endif
    );
    // ring breaker after pad 12: cuts DVDD, DVSS and VDD; VSS runs through
    (* keep *) gf180mcu_fd_io__brk5 brk_after_12 (
        `ifdef USE_POWER_PINS
        .VSS (VSS)
        `endif
    );
    // ring breaker after pad 17: cuts DVDD, DVSS and VDD; VSS runs through
    (* keep *) gf180mcu_fd_io__brk5 brk_after_17 (
        `ifdef USE_POWER_PINS
        .VSS (VSS)
        `endif
    );
    // ring breaker after pad 19: cuts DVDD, DVSS and VDD; VSS runs through
    (* keep *) gf180mcu_fd_io__brk5 brk_after_19 (
        `ifdef USE_POWER_PINS
        .VSS (VSS)
        `endif
    );
    // ring breaker after pad 24: cuts DVDD, DVSS and VDD; VSS runs through
    (* keep *) gf180mcu_fd_io__brk5 brk_after_24 (
        `ifdef USE_POWER_PINS
        .VSS (VSS)
        `endif
    );
    // ring breaker after pad 26: cuts DVDD, DVSS and VDD; VSS runs through
    (* keep *) gf180mcu_fd_io__brk5 brk_after_26 (
        `ifdef USE_POWER_PINS
        .VSS (VSS)
        `endif
    );
    // ring breaker after pad 75: cuts DVDD, DVSS and VDD; VSS runs through
    (* keep *) gf180mcu_fd_io__brk5 brk_after_75 (
        `ifdef USE_POWER_PINS
        .VSS (VSS)
        `endif
    );
    // ring breaker after pad 79: cuts DVDD, DVSS and VDD; VSS runs through
    (* keep *) gf180mcu_fd_io__brk5 brk_after_79 (
        `ifdef USE_POWER_PINS
        .VSS (VSS)
        `endif
    );
    // ring breaker after pad 85: cuts DVDD, DVSS and VDD; VSS runs through
    (* keep *) gf180mcu_fd_io__brk5 brk_after_85 (
        `ifdef USE_POWER_PINS
        .VSS (VSS)
        `endif
    );
    // ring breaker after pad 91: cuts DVDD, DVSS and VDD; VSS runs through
    (* keep *) gf180mcu_fd_io__brk5 brk_after_91 (
        `ifdef USE_POWER_PINS
        .VSS (VSS)
        `endif
    );
    // ring breaker after pad 95: cuts DVDD, DVSS and VDD; VSS runs through
    (* keep *) gf180mcu_fd_io__brk5 brk_after_95 (
        `ifdef USE_POWER_PINS
        .VSS (VSS)
        `endif
    );

    // Do not remove, necessary for tapeout
    (* keep *) gf180mcu_ws_ip__qrcode_id qrcode_id ();
    (* keep *) gf180mcu_ws_ip__shuttle_id shuttle_id ();
    (* keep *) gf180mcu_ws_ip__project_id project_id ();
    (* keep *) gf180mcu_ws_ip__marker marker ();
    (* keep *) gf180mcu_ws_ip__logo wafer_space_logo ();

endmodule

`default_nettype wire
