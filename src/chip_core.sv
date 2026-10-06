// SPDX-FileCopyrightText: © 2025 XXX Authors
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

module chip_core #(
    parameter NUM_INPUT_PADS,
    parameter NUM_BIDIR_PADS,
    parameter NUM_ANALOG_PADS
    )(
    `ifdef USE_POWER_PINS
    inout  wire VDD,
    inout  wire VSS,
    `endif

    input  wire clk,       // clock
    input  wire rst_n,     // reset (active low)

    input  wire [NUM_INPUT_PADS-1:0] input_in,   // Input value
    output wire [NUM_INPUT_PADS-1:0] input_pu,   // Pull-up
    output wire [NUM_INPUT_PADS-1:0] input_pd,   // Pull-down

    input  wire [NUM_BIDIR_PADS-1:0] bidir_in,   // Input value
    output wire [NUM_BIDIR_PADS-1:0] bidir_out,  // Output value
    output wire [NUM_BIDIR_PADS-1:0] bidir_oe,   // Output enable
    output wire [NUM_BIDIR_PADS-1:0] bidir_cs,   // Input type (0=CMOS Buffer, 1=Schmitt Trigger)
    output wire [NUM_BIDIR_PADS-1:0] bidir_sl,   // Slew rate (0=fast, 1=slow)
    output wire [NUM_BIDIR_PADS-1:0] bidir_ie,   // Input enable
    output wire [NUM_BIDIR_PADS-1:0] bidir_pu,   // Pull-up
    output wire [NUM_BIDIR_PADS-1:0] bidir_pd,   // Pull-down

    inout  wire [NUM_ANALOG_PADS-1:0] analog  // Analog
);

    // See here for usage: https://gf180mcu-pdk.readthedocs.io/en/latest/IPs/IO/gf180mcu_fd_io/digital.html

    // -------------------------------------------------------------------
    // Pad-to-croc_soc wiring plan
    // -------------------------------------------------------------------
    // Reworked to fit the 0p5x1 slot, which only defines 4 true
    // input-type pads (vs. 1x1's 12) -- only 4 of croc_soc's 7 input
    // signals stay on true input pads; the other 3 (jtag_tdi_i,
    // jtag_trst_ni, uart_rx_i) move to bidir pads permanently tied to
    // input mode (oe=0). Electrically identical to a true input pad --
    // a bidir pad with oe=0 just reads through the same CMOS buffer.
    // This costs 3 extra bidir pads (13 -> 16 total) but both slots have
    // plenty of headroom (0p5x1: 44 bidir; 1x1: 40 bidir).
    //
    // input_in[0] = ref_clk_i        input_in[1] = testmode_i
    // input_in[2] = jtag_tck_i       input_in[3] = jtag_tms_i
    //
    // bidir[0]  = status_o           bidir[1]  = jtag_tdo_o
    // bidir[2]  = uart_tx_o          bidir[3]  = qspi_clk_o
    // bidir[4]  = qspi_csn_o[0]      bidir[5]  = qspi_csn_o[1]
    // bidir[6]  = qspi_csn_o[2]
    // bidir[7]  = qspi_sd[0]  (real bidir, oe = qspi_sd_en_o[0])
    // bidir[8]  = qspi_sd[1]  (real bidir, oe = qspi_sd_en_o[1])
    // bidir[9]  = qspi_sd[2]  (real bidir, oe = qspi_sd_en_o[2])
    // bidir[10] = qspi_sd[3]  (real bidir, oe = qspi_sd_en_o[3])
    // bidir[11] = gpio[0]     (real bidir, oe = gpio_out_en_o[0])
    // bidir[12] = gpio[1]     (real bidir, oe = gpio_out_en_o[1])
    // bidir[13] = jtag_tdi_i   (input-only, oe=0 always)
    // bidir[14] = jtag_trst_ni (input-only, oe=0 always)
    // bidir[15] = uart_rx_i    (input-only, oe=0 always)
    //
    // Everything beyond these is left as a spare input-mode pad
    // (oe=0) with a pull-down enabled, to avoid a floating node.
    //
    // Hard requirement: NUM_INPUT_PADS >= 4 and NUM_BIDIR_PADS >= 16.
    // True for both slot 1x1 (12 input / 40 bidir) and slot 0p5x1
    // (4 input / 44 bidir).

    localparam int NUM_BIDIR_USED = 16;

    logic status_o, jtag_tdo_o, uart_tx_o, qspi_clk_o;
    logic [2:0] qspi_csn_o;
    logic [3:0] qspi_sd_o, qspi_sd_i, qspi_sd_en_o;
    logic [1:0] gpio_i, gpio_o, gpio_out_en_o;
    logic jtag_tdi_i, jtag_trst_ni, uart_rx_i;

    croc_soc i_croc_soc (
        `ifdef USE_POWER_PINS
        .VDD (VDD),
        .VSS (VSS),
        `endif

        .clk_i          (clk),
        .rst_ni         (rst_n),
        .ref_clk_i      (input_in[0]),
        .testmode_i     (input_in[1]),
        .status_o       (status_o),

        .jtag_tck_i     (input_in[2]),
        .jtag_tdi_i     (jtag_tdi_i),
        .jtag_tdo_o     (jtag_tdo_o),
        .jtag_tms_i     (input_in[3]),
        .jtag_trst_ni   (jtag_trst_ni),

        .uart_rx_i      (uart_rx_i),
        .uart_tx_o      (uart_tx_o),

        .qspi_clk_o     (qspi_clk_o),
        .qspi_sd_o      (qspi_sd_o),
        .qspi_sd_i      (qspi_sd_i),
        .qspi_sd_en_o   (qspi_sd_en_o),
        .qspi_csn_o     (qspi_csn_o),

        .gpio_i         (gpio_i),
        .gpio_o         (gpio_o),
        .gpio_out_en_o  (gpio_out_en_o)
    );

    // Pure input pads
    assign input_pu = '0;
    assign input_pd = '0;

    logic _unused_input_in;
    assign _unused_input_in = &input_in[NUM_INPUT_PADS-1:4];

    // Bidir pads used by croc_soc
    wire [NUM_BIDIR_USED-1:0] bidir_out_used = {
        1'b0, 1'b0, 1'b0,                       // bidir[15:13] input-only, no output drive
        gpio_o[1], gpio_o[0],
        qspi_sd_o[3], qspi_sd_o[2], qspi_sd_o[1], qspi_sd_o[0],
        qspi_csn_o[2], qspi_csn_o[1], qspi_csn_o[0],
        qspi_clk_o, uart_tx_o, jtag_tdo_o, status_o
    };
    wire [NUM_BIDIR_USED-1:0] bidir_oe_used = {
        1'b0, 1'b0, 1'b0,                       // bidir[15:13]: jtag_tdi_i, jtag_trst_ni, uart_rx_i -- input-only
        gpio_out_en_o[1], gpio_out_en_o[0],
        qspi_sd_en_o[3], qspi_sd_en_o[2], qspi_sd_en_o[1], qspi_sd_en_o[0],
        1'b1, 1'b1, 1'b1,   // qspi_csn_o[2:0], always output
        1'b1, 1'b1, 1'b1, 1'b1  // qspi_clk_o, uart_tx_o, jtag_tdo_o, status_o
    };

    assign qspi_sd_i = {bidir_in[10], bidir_in[9], bidir_in[8], bidir_in[7]};
    assign gpio_i     = {bidir_in[12], bidir_in[11]};
    assign jtag_tdi_i   = bidir_in[13];
    assign jtag_trst_ni = bidir_in[14];
    assign uart_rx_i    = bidir_in[15];

    logic _unused_bidir_in;
    assign _unused_bidir_in = &{bidir_in[6:0], bidir_in[NUM_BIDIR_PADS-1:NUM_BIDIR_USED]};

    assign bidir_out[NUM_BIDIR_USED-1:0] = bidir_out_used;
    assign bidir_oe [NUM_BIDIR_USED-1:0] = bidir_oe_used;
    assign bidir_out[NUM_BIDIR_PADS-1:NUM_BIDIR_USED] = '0;
    assign bidir_oe [NUM_BIDIR_PADS-1:NUM_BIDIR_USED] = '0;  // spare pads: input mode

    assign bidir_cs = '0;              // CMOS buffer for all bidir pads
    assign bidir_sl = '0;              // fast slew for all bidir pads
    assign bidir_ie = ~bidir_oe;       // input path enabled exactly when not driving

    assign bidir_pu = '0;
    // Pull down spare (unused) bidir pads only, to avoid a floating node
    // while they sit in input mode; pads actually driven by croc_soc don't
    // need one.
    assign bidir_pd[NUM_BIDIR_USED-1:0] = '0;
    assign bidir_pd[NUM_BIDIR_PADS-1:NUM_BIDIR_USED] = '1;

    // Analog pads: unused by croc_soc, left floating/unconnected as the
    // template default.
    logic _unused_analog;
    assign _unused_analog = &analog;

endmodule

`default_nettype wire
