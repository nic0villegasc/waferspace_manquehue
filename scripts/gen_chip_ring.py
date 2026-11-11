#!/usr/bin/env python3
"""Write the AC3E pad ring for LibreLane from padring.txt.

usage: python3 scripts/gen_chip_ring.py [padring.txt]     (make ring; default: padring.txt in the repository root)

Writes three files. Do not edit them by hand:
  src/chip_top.sv         every pad and breaker, the wafer.space IPs, and chip_core (croc_soc) on the CROC pads
  librelane/pad_cfg.tcl   the position of every pad and breaker (PAD_CFG of slot.yaml)
  librelane/slot.yaml     the PAD_SOUTH/EAST/NORTH/WEST lists (the rest of the file is kept)

padring.txt lines:
  pad <n> <signal> <cell>     <cell> is a gf180mcu_fd_io cell without its prefix (bi_24t, in_s, dvdd, asig_5p0...),
                              or the name of an own pad cell (its views in macros.yaml and sources.yaml)
  brk <name> <after pad>      a brk5 ring breaker in the gap after that pad
  seg <net> <pads> ...        supply segment: DVDD and VDD of these pads on <net>. VDD is the CROC segment.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "padring.txt"
TOP = ROOT / "src" / "chip_top.sv"
PADCFG = ROOT / "librelane" / "pad_cfg.tcl"
SLOT = ROOT / "librelane" / "slot.yaml"

# CROC pins: pad signal -> (kind, chip_core nets, pull). Kinds: in (in_c/in_s input pad), bin (bi_24t as input),
# bout (bi_24t as output), bio (bi_24t both ways: out, out enable, in, in enable).
PINS = {
    "clk_i":        ("in",   ["clk_i"], None),
    "rst_ni":       ("in",   ["rst_ni"], None),
    "ref_clk_i":    ("in",   ["ref_clk_i"], None),
    "testmode_i":   ("in",   ["testmode_i"], "pd"),
    "jtag_tck_i":   ("in",   ["jtag_tck_i"], None),
    "jtag_trst_ni": ("in",   ["jtag_trst_ni"], None),
    "rf_dio0_i":    ("in",   ["rf_dio0_i"], "pd"),
    "jtag_tdi_i":   ("bin",  ["jtag_tdi_i"], "pu"),
    "jtag_tms_i":   ("bin",  ["jtag_tms_i"], "pu"),
    "uart_rx_i":    ("bin",  ["uart_rx_i"], "pu"),
    "afe_irq_i":    ("bin",  ["afe_irq_i"], "pu"),
    "spi_sd_i":     ("bin",  ["spi_sd_i"], "pd"),
    "scan_in_i":    ("bin",  ["scan_si_i"], "pd"),
    "scan_en_i":    ("bin",  ["scan_se_i"], "pd"),
    "status_o":     ("bout", ["status_o"], None),
    "jtag_tdo_o":   ("bout", ["jtag_tdo_o"], None),
    "uart_tx_o":    ("bout", ["uart_tx_o"], None),
    "qspi_clk_o":   ("bout", ["qspi_clk_o"], None),
    "qspi_cs0_o":   ("bout", ["qspi_csn_o[0]"], None),
    "qspi_cs1_o":   ("bout", ["qspi_csn_o[1]"], None),
    "qspi_cs2_o":   ("bout", ["qspi_csn_o[2]"], None),
    "spi_sck_o":    ("bout", ["spi_sck_o"], None),
    "spi_sd_o":     ("bout", ["spi_sd_o"], None),
    "spi_cs0_o":    ("bout", ["spi_cs0_o"], None),
    "spi_cs1_o":    ("bout", ["spi_cs1_o"], None),
    "rf_rstn_o":    ("bout", ["rf_rstn_o"], None),
    "scan_out_o":   ("bout", ["scan_so_o"], None),
    "qspi_sd0_io":  ("bio",  ["qspi_sd_o[0]", "qspi_sd_en_o[0]", "qspi_sd_i[0]", "qspi_sd_ie[0]"], None),
    "qspi_sd1_io":  ("bio",  ["qspi_sd_o[1]", "qspi_sd_en_o[1]", "qspi_sd_i[1]", "qspi_sd_ie[1]"], None),
    "qspi_sd2_io":  ("bio",  ["qspi_sd_o[2]", "qspi_sd_en_o[2]", "qspi_sd_i[2]", "qspi_sd_ie[2]"], None),
    "qspi_sd3_io":  ("bio",  ["qspi_sd_o[3]", "qspi_sd_en_o[3]", "qspi_sd_i[3]", "qspi_sd_ie[3]"], None),
    "gpio0_io":     ("bio",  ["gpio_o[0]", "gpio_out_en_o[0]", "gpio_i[0]", "gpio_ie[0]"], None),
    "gpio1_io":     ("bio",  ["gpio_o[1]", "gpio_out_en_o[1]", "gpio_i[1]", "gpio_ie[1]"], None),
}
SUPPLY = {"dvdd", "dvss"}       # supply pads: no signal pin


# gf180mcu_fd_io cells by their short name. Any other name in padring.txt is an own pad cell, used as it is.
PDK_PADS = {"bi_24t", "bi_t", "in_c", "in_s", "asig_5p0", "dvdd", "dvss", "brk2", "brk5", "cor",
            "fill1", "fill5", "fill10", "fillnc"}


def master(cell):
    """Cell name in the layout: gf180mcu_fd_io__<cell> for a PDK pad, the name itself for an own pad cell."""
    return "gf180mcu_fd_io__" + cell if cell in PDK_PADS else cell


# 1. Read the table
pads, brks, seg_of = [], [], {}
for line in SRC.read_text().splitlines():
    f = line.split()
    if not f or f[0].startswith("#"):
        continue
    if f[0] == "pad":
        pads.append((int(f[1]), f[2], f[3]))
    elif f[0] == "brk":
        brks.append((f[1], int(f[2])))
    elif f[0] == "seg":
        for r in f[2:]:
            lo, _, hi = r.partition("-")
            for n in range(int(lo), int(hi or lo) + 1):
                seg_of[n] = f[1]
croc_pads = {n for n, net in seg_of.items() if net == "VDD"}


# 2. Position of a pad number: side and lower-left coordinate along it (y on west/east, x on south/north).
#    43 pads per long side at 100 um, 11 per short side at 104 um, numbered counterclockwise from the top left.
def side_loc(n):
    if n <= 43:
        return "WEST", 4623.5 - 100.0 * (n - 1)
    if n <= 54:
        return "SOUTH", 410.5 + 104.0 * (n - 44)
    if n <= 97:
        return "EAST", 423.5 + 100.0 * (n - 55)
    return "NORTH", 1450.5 - 104.0 * (n - 98)


def brk_loc(side, loc):
    """A breaker sits centred in the 25 um gap after its pad."""
    return loc - 15.0 if side == "WEST" else loc + 85.0


# 3. src/chip_top.sv
def c(net):
    return "c_" + net


NETS = {}       # chip_core bus widths, from the PINS table
for kind, nets, _ in PINS.values():
    for n in nets:
        m = re.match(r"(\w+)(?:\[(\d+)\])?$", n)
        NETS[m.group(1)] = max(NETS.get(m.group(1), 1), int(m.group(2) or 0) + 1)


def pg(seg, cell):
    """Supply pins: DVDD and VDD on the segment net, DVSS and VSS on the common VSS."""
    conn = {"DVDD": seg, "DVSS": "VSS", "VDD": seg, "VSS": "VSS"}
    return "        `ifdef USE_POWER_PINS\n" + ",\n".join("        .%-4s (%s)" % (p, conn[p]) for p in conn) + \
           ("\n        `endif" if cell in SUPPLY else ",\n        `endif")


def bi(sig, a, oe, ie, pu, pd, y):
    """Pins of a bi_24t pad."""
    return ("        .A     (%s),\n        .OE    (%s),\n        .CS    (1'b0),\n        .SL    (1'b0),\n"
            "        .IE    (%s),\n        .PU    (%s),\n        .PD    (%s),\n        .Y     (%s),\n"
            "        .PAD   (%s)" % (a, oe, ie, pu, pd, y, sig))


ports, body, done = [], [], set()
for n, sig, cell in pads:
    seg = seg_of[n]
    head = "    // pad %d: %s (segment %s)\n    (* keep *) %s pad_%s (\n" % (n, sig, seg, master(cell), sig)
    if cell in SUPPLY:
        body.append(head + pg(seg, cell) + "\n    );\n")
        continue
    ports.append("    %s wire %s" % ("input " if cell in ("in_c", "in_s") else "inout ", sig))
    if sig in PINS:                                     # CROC pad: core side to chip_core
        kind, nets, pull = PINS[sig]
        pu = "1'b1" if pull == "pu" else "1'b0"
        pd = "1'b1" if pull == "pd" else "1'b0"
        nets = [c(x) for x in nets]
        if kind == "in":
            conn = "        .PU    (%s),\n        .PD    (%s),\n        .Y     (%s),\n        .PAD   (%s)" % (pu, pd, nets[0], sig)
        elif kind == "bin":
            conn = bi(sig, "1'b0", "1'b0", "1'b1", pu, pd, nets[0])
        elif kind == "bout":
            conn = bi(sig, nets[0], "1'b1", "1'b0", pu, pd, "")
        else:
            conn = bi(sig, nets[0], nets[1], nets[3], pu, pd, nets[2])
        done.add(sig)
    elif n in croc_pads:                                # spare pad of the CROC segment: off, pulled down
        conn = bi(sig, "1'b0", "1'b0", "1'b0", "1'b0", "1'b1", "")
    else:                                               # DC-DC pad: its core side is driven by the DC-DC layout
        conn = "        .%s (%s)" % ("ASIG5V" if cell == "asig_5p0" else "PAD   ", sig)
    body.append(head + pg(seg, cell) + "\n" + conn + "\n    );\n")
missing = set(PINS) - done
if missing:
    raise SystemExit("gen_chip_ring.py: croc pins without a pad: %s" % ", ".join(sorted(missing)))

for brk, n in brks:
    body.append("    // ring breaker after pad %d: cuts DVDD, DVSS and VDD, VSS runs through\n"
                "    (* keep *) gf180mcu_fd_io__brk5 %s (\n        `ifdef USE_POWER_PINS\n        .VSS (VSS)\n"
                "        `endif\n    );\n" % (n, brk))
# The DC-DC layouts are not in the netlist: scripts/merge_dcdc.py copies them into the final GDS.

# wafer.space IPs (positions in librelane/macros.yaml)
body.append("    // wafer.space IPs\n" + "".join("    (* keep *) gf180mcu_ws_ip__%s %s ();\n" % (r, i) for r, i in (
    ("qrcode_id", "qrcode_id"), ("shuttle_id", "shuttle_id"), ("project_id", "project_id"), ("marker", "marker"),
    ("logo", "wafer_space_logo"))))

segs = sorted(set(seg_of.values()) - {"VDD"})
decl = "".join("    wire %s%s;\n" % ("[%d:0] " % (w - 1) if w > 1 else "", c(n)) for n, w in NETS.items())
core = ("    // croc_soc and the pad controls\n    chip_core i_chip_core (\n        `ifdef USE_POWER_PINS\n"
        "        .VDD (VDD),\n        .VSS (VSS),\n        `endif\n" +
        ",\n".join("        .%-14s (%s)" % (n, c(n)) for n in NETS) + "\n    );\n")
TOP.write_text(
    "// GENERATED by scripts/gen_chip_ring.py from %s; do not edit.\n"
    "// AC3E pad ring of the croc chip: croc_soc (chip_core) on the CROC pads, the DC-DC wrappers on the others.\n\n"
    "`default_nettype none\n\nmodule chip_top (\n    `ifdef USE_POWER_PINS\n    inout  wire VDD,\n    inout  wire VSS,\n"
    "    // supplies of the DC-DC ring segments\n%s    `endif\n%s\n);\n\n    // core side of the CROC pads\n%s\n%s\n%s\n"
    "endmodule\n\n`default_nettype wire\n" % (
        SRC.name, "".join("    inout  wire %s,\n" % s for s in segs), ",\n".join(ports), decl, "".join(body), core))

# 4. librelane/pad_cfg.tcl: LibreLane's pad placement script with every pad and breaker at its table position
lines = []
for n, sig, cell in pads:
    side, loc = side_loc(n)
    lines.append("place_pad -row IO_%s -location %.1f pad_%s -master %s  ;# pad %d" % (side, loc, sig, master(cell), n))
for brk, n in brks:
    side, loc = side_loc(n)
    lines.append("place_pad -row IO_%s -location %.1f %s -master gf180mcu_fd_io__brk5  ;# after pad %d" % (side, brk_loc(side, loc), brk, n))
signal = " ".join("pad_" + s for _, s, cell in pads if cell not in SUPPLY)
PADCFG.write_text("""# GENERATED by scripts/gen_chip_ring.py from %s; do not edit.
# Pad placement for the OpenROAD.PadRing step (PAD_CFG). Based on LibreLane's
# scripts/openroad/common/pad_cfg.tcl (Apache-2.0, LibreLane Contributors), with every pad and
# ring breaker placed at its table position instead of spread automatically.

make_io_sites \\
    -horizontal_site $::env(PAD_SITE_NAME) \\
    -vertical_site $::env(PAD_SITE_NAME) \\
    -corner_site $::env(PAD_CORNER_SITE_NAME) \\
    -offset $::env(PAD_EDGE_SPACING) \\
    -rotation_horizontal $::env(PAD_ROTATION_HORIZONTAL) \\
    -rotation_vertical $::env(PAD_ROTATION_VERTICAL) \\
    -rotation_corner $::env(PAD_ROTATION_CORNER)

# place_pad -row <row> -location <lower-left coordinate along the side, um> <instance>
%s

place_corners $::env(PAD_CORNER)
place_io_fill -row IO_NORTH {*}$::env(PAD_FILLERS)
place_io_fill -row IO_SOUTH {*}$::env(PAD_FILLERS)
place_io_fill -row IO_WEST {*}$::env(PAD_FILLERS)
place_io_fill -row IO_EAST {*}$::env(PAD_FILLERS)
connect_by_abutment

# I/O terminals on the pad pins (PAD_PLACE_IO_TERMINALS, as in LibreLane's script)
if { [info exists ::env(PAD_PLACE_IO_TERMINALS)] } {
    set block [ord::get_db_block]
    foreach inst_name {%s} {
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
""" % (SRC.name, "\n".join(lines), signal))

# 5. librelane/slot.yaml: the four pad lists, each sorted along its side
by_side = {"SOUTH": [], "EAST": [], "NORTH": [], "WEST": []}
for n, sig, cell in pads:
    side, loc = side_loc(n)
    by_side[side].append((loc, "pad_" + sig))
for brk, n in brks:
    side, loc = side_loc(n)
    by_side[side].append((brk_loc(side, loc), brk))
slot = SLOT.read_text()
slot = slot[:slot.index("PAD_SOUTH:")].rstrip() + "\n\n" + "\n\n".join(
    "PAD_%s: [\n%s\n]" % (s, ",\n".join("    " + i for _, i in sorted(by_side[s]))) for s in ("SOUTH", "EAST", "NORTH", "WEST")) + "\n"
SLOT.write_text(slot)
print("wrote %s, %s, %s: %d pads, %d breakers" % (
    TOP.relative_to(ROOT), PADCFG.relative_to(ROOT), SLOT.relative_to(ROOT), len(pads), len(brks)))
