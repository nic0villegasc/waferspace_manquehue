#!/usr/bin/env python3
"""Write src/chip_top.sv: the AC3E padframe with croc_soc (through chip_core) on its CROC pads.

usage: scripts/gen_chip_top.py   (from the repository root)

Input: librelane/padframe/chip_top_padframe.sv, the padframe top level that the AC3E generator writes
(TO-GF180MCU-AC3E-2026_V1, 10_automation/scripts/generate_padframe.py, from padframe.yaml of the proposal
2026-10-19_croc_shared_spi). That file has one pad instance per pad and ties every core-side pad input off.
This script keeps the file as it is and only:
  - connects the pads of the CROC pins (table PINS below) to chip_core,
  - gives the unused pads of the CROC half a pull-down,
  - adds the chip_core instance.
The DC-DC pads stay tied off. Pad placement is librelane/padframe/pad_cfg.tcl from the same generator.
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "librelane" / "padframe" / "chip_top_padframe.sv"
DST = ROOT / "src" / "chip_top.sv"

# padframe pin -> (kind, core nets, pull). kind: in (in_c/in_s), bin (bi_24t input), bout (bi_24t output),
# bio (bi_24t bidirectional: out, oe, in, ie). pull: pu or pd for an input that must not float.
PINS = {
    "clk_i":        ("in",   ["clk_i"], None),
    "rst_ni":       ("in",   ["rst_ni"], None),
    "ref_clk_i":    ("in",   ["ref_clk_i"], None),
    "testmode_i":   ("in",   ["testmode_i"], "pd"),     # an open pad keeps the chip out of test mode
    "jtag_tck_i":   ("in",   ["jtag_tck_i"], None),
    "jtag_trst_ni": ("in",   ["jtag_trst_ni"], None),
    "rf_dio0_i":    ("in",   ["rf_dio0_i"], "pd"),
    "jtag_tdi_i":   ("bin",  ["jtag_tdi_i"], "pu"),
    "jtag_tms_i":   ("bin",  ["jtag_tms_i"], "pu"),
    "uart_rx_i":    ("bin",  ["uart_rx_i"], "pu"),      # UART idles high
    "afe_irq_i":    ("bin",  ["afe_irq_i"], "pu"),      # WAKE_N, active low
    "spi_sd_i":     ("bin",  ["spi_sd_i"], "pd"),       # both devices release it while their CS is high
    "scan_in_i":    ("bin",  ["scan_si_i"], "pd"),
    "scan_en_i":    ("bin",  ["scan_se_i"], "pd"),      # an open pad means scan off
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
CROC_PADS = range(23, 76)          # pads of the CROC half of the ring (padframe.yaml, Padring.Breaks)

# core nets: name -> width. In chip_top a core net is c_<port of chip_core>: the pad ports of chip_top carry the
# padframe pin names, which are often the same.
NETS = {}
for kind, nets, _ in PINS.values():
    for n in nets:
        m = re.match(r"(\w+)(?:\[(\d+)\])?$", n)
        NETS[m.group(1)] = max(NETS.get(m.group(1), 1), int(m.group(2) or 0) + 1)

def c(net):
    return "c_" + net


text = SRC.read_text()
block_re = re.compile(r"    // pad (\d+) \((\w+)\): \S+ (\S+)\n    \(\* keep \*\) (\S+) (\S+) \(\n(.*?)\n    \);\n", re.S)


def set_pin(body, pin, value):
    new, n = re.subn(r"(\n        \.%s\s+\()[^)]*(\))" % pin, lambda m: m.group(1) + value + m.group(2), "\n" + body)
    if n != 1:
        raise SystemExit("gen_chip_top.py: pin %s not found once" % pin)
    return new[1:]


done = set()


def rewrite(m):
    pad, side, name, master, inst, body = m.groups()
    pad = int(pad)
    if name in PINS:
        kind, nets, pull = PINS[name]
        pu, pd = ("1'b1" if pull == "pu" else "1'b0"), ("1'b1" if pull == "pd" else "1'b0")
        expect = "gf180mcu_fd_io__bi_24t" if kind != "in" else ("gf180mcu_fd_io__in_c", "gf180mcu_fd_io__in_s")
        if master not in (expect if isinstance(expect, tuple) else (expect,)):
            raise SystemExit("gen_chip_top.py: pad %d %s is %s, expected %s" % (pad, name, master, expect))
        nets = [c(n) for n in nets]
        if kind == "in":
            body = set_pin(body, "Y", nets[0])
        elif kind == "bin":
            body = set_pin(body, "IE", "1'b1")
            body = set_pin(body, "Y", nets[0])
        elif kind == "bout":
            body = set_pin(body, "A", nets[0])
            body = set_pin(body, "OE", "1'b1")
        else:
            body = set_pin(body, "A", nets[0])
            body = set_pin(body, "OE", nets[1])
            body = set_pin(body, "Y", nets[2])
            body = set_pin(body, "IE", nets[3])
        body = set_pin(body, "PU", pu)
        body = set_pin(body, "PD", pd)
        done.add(name)
    elif name.startswith("unused_") and pad in CROC_PADS:
        body = set_pin(body, "PD", "1'b1")      # spare pad of the CROC half: input off, pulled down
    return "    // pad %d (%s): %s\n    (* keep *) %s %s (\n%s\n    );\n" % (
        pad, side, m.group(0).split("\n")[0].split(": ", 1)[1], master, inst, body)


out = block_re.sub(rewrite, text)
missing = set(PINS) - done
if missing:
    raise SystemExit("gen_chip_top.py: pins not in the padframe: %s" % ", ".join(sorted(missing)))

decl = "\n    // core side of the CROC pads\n" + "".join(
    "    wire %s%s;\n" % ("[%d:0] " % (w - 1) if w > 1 else "", c(n)) for n, w in NETS.items())
core = "\n    // croc_soc and the pad controls\n    chip_core i_chip_core (\n        `ifdef USE_POWER_PINS\n" \
       "        .VDD (VDD),\n        .VSS (VSS),\n        `endif\n" + \
       ",\n".join("        .%-14s (%s)" % (n, c(n)) for n in NETS) + "\n    );\n"
head = ("// GENERATED by scripts/gen_chip_top.py from librelane/padframe/chip_top_padframe.sv (AC3E padframe,\n"
        "// proposal 2026-10-19_croc_shared_spi); do not edit. The CROC pads are connected to chip_core,\n"
        "// the DC-DC pads stay tied off.\n")
out = re.sub(r"\A(//[^\n]*\n)+", head, out, count=1)
first_pad = out.index("    // pad ")
out = out[:first_pad] + decl + "\n" + out[first_pad:]
out = out.replace("\nendmodule", core + "\nendmodule", 1)
DST.write_text(out)
print("wrote %s: %d CROC pins connected" % (DST.relative_to(ROOT), len(done)))
