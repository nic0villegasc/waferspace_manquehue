# librelane/padframe

The AC3E padframe (TO-GF180MCU-AC3E-2026_V1, `04_chip_top/padframe/`), proposal `2026-10-19_croc_shared_spi`.

| File | What it is |
|---|---|
| `padframe.yaml` | The proposal's pin list and pad ring. Copy, for reference. |
| `pad_cfg.tcl` | Pad placement script (PAD_CFG of `slots/slot_ac3e.yaml`). Written by the AC3E generator `10_automation/scripts/generate_padframe.py` from `padframe.yaml`. Unchanged. |
| `chip_top_padframe.sv` | Padframe-only top level from the same generator: one pad per pad number, ring breakers, ID macros, core-side inputs tied off. Unchanged. Input of `scripts/gen_chip_top.py`. |

`scripts/gen_chip_top.py` writes `src/chip_top.sv` from `chip_top_padframe.sv`: it connects the CROC pads to
`chip_core` and keeps the DC-DC pads tied off.

To take a new padframe: run the AC3E generator on the new `padframe.yaml`, copy the three files here, then
run `python3 scripts/gen_chip_top.py`.

Supply: the ring breakers after pads 22 and 75 cut DVDD, DVSS and VDD of the ring. In this chip run the core ring
(`config.yaml`, `PDN_CORE_RING_CONNECT_TO_PADS`) connects to the pads of both halves, so the chip has one supply:
the netlist has the single set VDD, VSS, DVDD, DVSS, the same as the AC3E padframe netlist. A separate DC-DC supply
is for the AC3E integration.
