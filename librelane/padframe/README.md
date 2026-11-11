# librelane/padframe

The AC3E pad ring of the croc chip.

| File | What it is |
|---|---|
| `pad_cfg.tcl` | Pad placement for the OpenROAD.PadRing step (`PAD_CFG` of `slots/slot_ac3e.yaml`): every pad and ring breaker at its table position. Generated. |

The ring has one source: the pad table `scripts/chip/padring.txt` of manquehue_chip, the same table that the croc
macro flow uses to place its pins in front of their pads. `scripts/gen_chip_ring.py` reads it and writes three files:

- `src/chip_top.sv`: every pad and breaker, the wafer.space IPs, and `chip_core` (croc_soc) on the CROC pads;
- `librelane/padframe/pad_cfg.tcl`: the pad positions;
- the `PAD_SOUTH`, `PAD_EAST`, `PAD_NORTH` and `PAD_WEST` lists of `librelane/slots/slot_ac3e.yaml`.

To change the ring: edit `padring.txt` in manquehue_chip, then from the root of this repository run
`python3 scripts/gen_chip_ring.py` (or give the table path as its argument). Do not edit the three generated files
by hand. A change to a CROC pad also moves a croc_soc pin, so the croc macro must be built again.

Supplies: each ring segment between breakers has its own supply net (`seg` lines of `padring.txt`). The CROC
segment (pads 27 to 72) is `VDD`, the core supply. `VSS` runs around the whole ring.
