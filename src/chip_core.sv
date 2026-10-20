// SPDX-FileCopyrightText: © 2025 XXX Authors
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

// Core of chip_top for the AC3E padframe: croc_soc as a hard macro, and the input enables of the bidirectional
// pads. src/chip_top.sv (scripts/gen_chip_top.py) connects every port here to the pad of the same pin, and sets the
// other pad controls (output enable of the output pads, pull-ups and pull-downs) with constants.
// Pad map: librelane/padframe/padframe.yaml (pads 35 to 75, the CROC half of the ring).

module chip_core (
    `ifdef USE_POWER_PINS
    inout  wire VDD,
    inout  wire VSS,
    `endif

    input  wire       clk_i,
    input  wire       rst_ni,
    input  wire       ref_clk_i,
    input  wire       testmode_i,

    input  wire       jtag_tck_i,
    input  wire       jtag_trst_ni,
    input  wire       jtag_tdi_i,
    input  wire       jtag_tms_i,
    output wire       jtag_tdo_o,

    input  wire       uart_rx_i,
    output wire       uart_tx_o,
    output wire       status_o,

    // QSPI flash
    output wire       qspi_clk_o,
    output wire [2:0] qspi_csn_o,
    output wire [3:0] qspi_sd_o,
    output wire [3:0] qspi_sd_en_o,
    input  wire [3:0] qspi_sd_i,
    output wire [3:0] qspi_sd_ie,

    // shared SPI bus: ADS7057 on CS0, SX1276 on CS1
    output wire       spi_sck_o,
    output wire       spi_sd_o,
    input  wire       spi_sd_i,
    output wire       spi_cs0_o,
    output wire       spi_cs1_o,
    input  wire       afe_irq_i,
    input  wire       rf_dio0_i,
    output wire       rf_rstn_o,

    output wire [1:0] gpio_o,
    output wire [1:0] gpio_out_en_o,
    input  wire [1:0] gpio_i,
    output wire [1:0] gpio_ie,

    // scan chain
    input  wire       scan_si_i,
    input  wire       scan_se_i,
    output wire       scan_so_o
);

    // input path of a bidirectional pad enabled exactly when it does not drive
    assign qspi_sd_ie = ~qspi_sd_en_o;
    assign gpio_ie    = ~gpio_out_en_o;

    croc_soc i_croc_soc (
        `ifdef USE_POWER_PINS
        .VDD (VDD),
        .VSS (VSS),
        `endif

        .clk_i         (clk_i),
        .rst_ni        (rst_ni),
        .ref_clk_i     (ref_clk_i),
        .testmode_i    (testmode_i),
        .status_o      (status_o),

        .jtag_tck_i    (jtag_tck_i),
        .jtag_tdi_i    (jtag_tdi_i),
        .jtag_tdo_o    (jtag_tdo_o),
        .jtag_tms_i    (jtag_tms_i),
        .jtag_trst_ni  (jtag_trst_ni),

        .uart_rx_i     (uart_rx_i),
        .uart_tx_o     (uart_tx_o),

        .qspi_clk_o    (qspi_clk_o),
        .qspi_sd_o     (qspi_sd_o),
        .qspi_sd_i     (qspi_sd_i),
        .qspi_sd_en_o  (qspi_sd_en_o),
        .qspi_csn_o    (qspi_csn_o),

        .spi_sck_o     (spi_sck_o),
        .spi_sd_o      (spi_sd_o),
        .spi_sd_i      (spi_sd_i),
        .spi_cs0_o     (spi_cs0_o),
        .spi_cs1_o     (spi_cs1_o),
        .afe_irq_i     (afe_irq_i),
        .rf_dio0_i     (rf_dio0_i),
        .rf_rstn_o     (rf_rstn_o),

        .gpio_i        (gpio_i),
        .gpio_o        (gpio_o),
        .gpio_out_en_o (gpio_out_en_o),

        .scan_si_i     (scan_si_i),
        .scan_se_i     (scan_se_i),
        .scan_so_o     (scan_so_o)
    );

endmodule

`default_nettype wire
