# AC3E chip

The AC3E chip in one `chip_top.gds`: the 108-pad AC3E ring, the croc_soc hard macro and the DC-DC layouts of
S. Sanchez. Built with LibreLane from the wafer.space GF180MCU project template (Apache-2.0, see `LICENSE`).

## Start

You need `git`, `python3`, `gh` (logged in with `gh auth login --web`) and the flow tools: the AC3E IC Toolbox, or
`nix`. `make doctor` checks all of it and says how to fix what is missing.

```
make doctor     # check this machine first
make fetch      # the macros of sources.yaml into macros/, checked by SHA-256
make chip       # LibreLane: pad ring, croc_soc, wires
make merge      # DC-DC layouts into the GDS
make precheck   # wafer.space precheck
```

`make help` lists every target. Each one enters the flow environment itself and runs `make fetch` first, which only
checks the hashes when nothing changed.

## A new version of a macro

Put the files in one folder, then from this repository:

```
make publish NAME=<entry> DIR=<folder> TAG=<tag>
git add sources.yaml && git commit -m "<entry> <tag>"
```

This uploads the folder as a GitHub release of this repository and writes its hashes into `sources.yaml`.
Everyone gets it on their next `make`. With `LOCAL=1` instead of `TAG`, the entry points at your local folder, to
try a version before you publish it. For croc_soc, `make stage-croc RUN=<manquehue_chip run>` first collects the seven
files the chip uses into `out/croc`.

| Entry | What | Owner |
|---|---|---|
| `croc` | croc_soc: GDS, LEF, netlist, port stub, timing models | N. Villegas |
| `dcdc` | DC-DC layouts (`Channels_wrapper`, `DB_VCO_wrapper`), into `macros/dcdc/` | S. Sanchez |

An own pad cell gets an entry too, and its full cell name goes in `padring.txt` (see `librelane/macros.yaml`).

## Folders

| Folder | What is here |
|---|---|
| `padring.txt` | The pad ring: every pad, breaker and supply segment. `make ring` writes `src/chip_top.sv`, `librelane/pad_cfg.tcl` and the pad lists of `librelane/slot.yaml` from it. |
| `sources.yaml` | Where each macro comes from, with the SHA-256 of every file |
| `librelane/` | LibreLane: `config.yaml` (flow), `slot.yaml` (die, core, pads), `macros.yaml` (macro views and places), `pad_cfg.tcl`, `pdn_cfg.tcl` (power grid), `chip_top.sdc`, `runs/` |
| `src/` | `chip_top.sv` (generated) and `chip_core.sv` (croc_soc and its pad controls) |
| `scripts/` | `gen_chip_ring.py`, `fetch.py`, `publish.py`, `merge_dcdc.py`, `overlay.py`, `render_gds.py` |
| `ip/` | wafer.space ID cells |
| `macros/` | The fetched macros (not in Git) |
| `out/` | Logs and results (not in Git) |
