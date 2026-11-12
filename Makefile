# AC3E chip: the AC3E pad ring, the croc_soc macro and the DC-DC layouts in one chip_top.gds.
# Run every target from this folder in a normal shell. Each one enters the nix-shell of this repository.
#
#   make doctor                 check this machine: tools, GitHub access, macros (start here)
#   make fetch                  get the macros of sources.yaml into macros/, or check them (the targets run it)
#   make publish NAME= DIR= TAG=   a new version of a macro, as a release of this repository (LOCAL=1: no upload)
#   make stage-croc RUN=<run>   the files of a croc_soc run that the chip uses, into out/croc
#   make ring                   src/chip_top.sv, librelane/pad_cfg.tcl and slot.yaml from padring.txt
#   make ringcheck              quick check of the pad ring (a few minutes): placed as padring.txt says
#   make chip                   LibreLane: pad ring, croc_soc, wires (30 to 60 min)
#   make merge                  DC-DC layouts (DCDC) into the chip GDS: chip_top_dcdc.gds
#   make gls                    chip GLS: JTAG boot, flash + ADC read, flash + radio (gls-jtag, gls-adc, gls-radio)
#   make precheck               wafer.space precheck of the merged GDS
#   make lvs                    chip LVS without the DC-DC layouts: pads, ties, croc_soc pins (out/lvs/)
#   make lvs-full               full-chip transistor LVS with the DC-DC, croc_soc as pin abstract (out/lvs_full_abstract/)
#   make lvs-croc               croc_soc alone at transistor level, SRAMs as black boxes (out/lvs_croc/)
#   make image                  PNG of the chip GDS (out/chip_top.png)
#   make overlay                CROC macro + DC-DC layouts only, to check how they meet (out/overlay.gds)
#   make labels                 pad numbers and names as a GDS (out/pad_labels.gds) and colours (out/view.lyp)
#   make view [CHIP=<gds>]      a chip GDS in KLayout with the pad labels over it
#   make klayout | openroad     open the last chip run
#   make summary                results of the last chip run
#   make all                    chip, merge, gls, precheck, summary
#
# Variables: CROC (manquehue_chip checkout, only for gls, stage-croc and the ring check), CHIP_RUN (run under
# librelane/runs, default the newest), DCDC (folder of DC-DC layouts, default macros/dcdc). Logs go to out/.
# The flow tools come from the AC3E IC Toolbox when it is there, otherwise from this repository's nix-shell.

T          := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
CROC       ?= $(HOME)/Documents/manquehue_chip
MACRO      := $(T)/macros/croc
CHIP_RUN   ?= $(shell ls -t $(T)/librelane/runs 2>/dev/null | head -1)
CR         := $(T)/librelane/runs/$(CHIP_RUN)
DCDC       ?= $(T)/macros/dcdc
CHIP_GDS    = $(if $(wildcard $(CR)/final/gds/chip_top_dcdc.gds),$(CR)/final/gds/chip_top_dcdc.gds,$(CR)/final/gds/chip_top.gds)
O          := $(T)/out
PRECHECK   ?= $(T)/.tools/gf180mcu-precheck
PRECHECK_REV := 8d58ff7
# GitHub repository for make publish: this repository's own origin
REPO       ?= $(shell git -C $(T) remote get-url origin 2>/dev/null | sed -E 's|.*github.com[:/]||; s|[.]git$$||')
TOOLBOX    := /opt/librelane-templates/activate/gf.sh
NIX        := $(if $(wildcard $(TOOLBOX)),cd $(T) && bash -c '. $(TOOLBOX) >/dev/null 2>&1; eval "$$0"',cd $(T) && nix-shell --run)

# PDK and LibreLane
PDK_ROOT   ?= $(T)/gf180mcu
PDK        ?= gf180mcuD
PDK_COMMIT ?= f6eeac7dad085ffcc829ccfd721f7b4ce39edcf7
LL_CONFIGS := librelane/slot.yaml librelane/macros.yaml librelane/config.yaml
LL_OPTS    := --pdk $(PDK) --pdk-root $(PDK_ROOT) --manual-pdk --scl gf180mcu_fd_sc_mcu7t5v0 --pad gf180mcu_fd_io
CHIP_GLS   := TB=tb_chip_ac3e bash $(CROC)/scripts/sim/run_chip_gls.sh $(CR)/final/pnl/chip_top.pnl.v $(MACRO)/croc_soc.v

.PHONY: lvs lvs-full lvs-croc help all pdk doctor fetch publish stage-croc ring ringcheck chip merge gls gls-jtag gls-adc gls-radio precheck image overlay labels view klayout openroad summary
.DEFAULT_GOAL := help
help:
	@grep "^#   make" $(T)/Makefile | sed "s/^#   /  /"

all: chip merge gls precheck summary

pdk: $(PDK_ROOT)/ciel/gf180mcu/versions/$(PDK_COMMIT)/$(PDK)
$(PDK_ROOT)/ciel/gf180mcu/versions/$(PDK_COMMIT)/$(PDK):
	$(NIX) "ciel enable $(PDK_COMMIT) --pdk-root $(PDK_ROOT) --pdk-family $(PDK) --include-libraries all"

doctor:
	@bash $(T)/scripts/doctor.sh

# Every target that reads a macro runs fetch first. With nothing changed it only checks the SHA-256.
fetch:
	python3 $(T)/scripts/fetch.py

# A new version of a macro: make publish NAME=<entry> DIR=<folder> TAG=<tag>. It becomes a release of this
# repository (REPO), and everyone gets it on the next make. LOCAL=1: point the entry at DIR, no upload.
publish:
	@test -n "$(NAME)" -a -n "$(DIR)" || { echo "give NAME=<entry> DIR=<folder> TAG=<tag>"; exit 1; }
	python3 $(T)/scripts/publish.py $(NAME) $(DIR) $(if $(LOCAL),,--repo $(REPO) --tag $(TAG))
	python3 $(T)/scripts/fetch.py $(NAME)

# The files of a croc_soc run that the chip uses, in out/croc, ready for make publish NAME=croc DIR=out/croc.
stage-croc:
	@test -d "$(RUN)" || { echo "give RUN=<manquehue_chip run folder>"; exit 1; }
	ls $(RUN)/etm/croc_soc_slow.lib >/dev/null 2>&1 || bash $(CROC)/scripts/signoff/sta/extract_models.sh $(RUN)
	mkdir -p $(O)/croc/etm
	cp $(RUN)/croc_soc.gds $(RUN)/croc_soc.lef $(RUN)/croc_soc.v $(RUN)/croc_soc_bb.v $(O)/croc/
	cp $(RUN)/etm/croc_soc_slow.lib $(RUN)/etm/croc_soc_typical.lib $(RUN)/etm/croc_soc_fast.lib $(O)/croc/etm/

# The ring comes from padring.txt here. manquehue_chip keeps a copy to place the croc_soc pins: warn if the CROC
# pads (27 to 72) of the two copies differ, because then the macro pins no longer face their pads.
ring:
	python3 $(T)/scripts/gen_chip_ring.py $(T)/padring.txt
	@mkdir -p $(O)
	@awk '$$1=="pad" && $$2>=27 && $$2<=72' $(T)/padring.txt > $(O)/croc_pads.here
	@awk '$$1=="pad" && $$2>=27 && $$2<=72' $(CROC)/scripts/chip/padring.txt > $(O)/croc_pads.croc 2>/dev/null || true
	@cmp -s $(O)/croc_pads.here $(O)/croc_pads.croc || echo "WARNING: CROC pads differ from $(CROC)/scripts/chip/padring.txt: build the macro again"

# LibreLane up to the pad ring and croc_soc placement only, in out/ringcheck (not a chip run), then every pad and
# breaker checked against padring.txt. Run make ring first when padring.txt changed.
ringcheck: pdk fetch
	@mkdir -p $(O)
	$(NIX) "librelane $(LL_CONFIGS) $(LL_OPTS) --run-tag $(O)/ringcheck --overwrite --to Odb.ManualMacroPlacement" \
	  > $(O)/ringcheck.log 2>&1 || { tail -20 $(O)/ringcheck.log; exit 1; }
	python3 $(T)/scripts/ringcheck.py $(T)/padring.txt $(O)/ringcheck/18-odb-manualmacroplacement/chip_top.def

# The antenna check and repair after global routing are skipped: with the no-clamp pads (POWER pins on the Vc
# outputs) the OpenROAD antenna checker does not load the global route guides and stops with ANT-0008. The antenna
# check after detailed routing still runs.
CHIP_SKIP := --skip OpenROAD.CheckAntennas --skip OpenROAD.RepairAntennas
chip: pdk fetch
	@mkdir -p $(O)
	$(NIX) "librelane $(LL_CONFIGS) $(LL_OPTS) $(CHIP_SKIP)" 2>&1 | tee $(O)/chip_run.log

# DB_VCO_wrapper 0.5 um up to meet the pad pins (see scripts/merge_dcdc.py)
DCDC_SHIFT ?= DB_VCO_wrapper:0,0.5
merge: fetch
	@mkdir -p $(O)
	$(NIX) "klayout -b -r $(T)/scripts/merge_dcdc.py -rd input=$(CR)/final/gds/chip_top.gds \
	  -rd output=$(CR)/final/gds/chip_top_dcdc.gds -rd gds_dir=$(DCDC) -rd shift=$(DCDC_SHIFT)" 2>&1 | tee $(O)/merge.log

# The chip GLS uses manquehue_chip's test bench: skipped without a checkout (CROC=<checkout>).
gls: fetch
	@if [ -d $(CROC)/scripts/sim ]; then $(MAKE) gls-jtag gls-adc gls-radio; \
	 else echo "gls: skipped, no manquehue_chip checkout at $(CROC)"; fi
gls-jtag:
	@mkdir -p $(O)
	$(NIX) "$(CHIP_GLS) $(O)/gls_jtag" 2>&1 | tee $(O)/gls_jtag.log
gls-adc:   GLS_SRC = ../spi/spi_adc.c
gls-radio: GLS_SRC = spi_radio.c
gls-adc gls-radio: gls-%:
	@mkdir -p $(O)
	$(NIX) "cd $(CROC)/sim/sw/flash && bash build.sh $(GLS_SRC) > /dev/null && \
	  VVP_ARGS=+flash=$(CROC)/sim/sw/flash/bin/spi_$*.flash.hex $(CHIP_GLS) $(O)/gls_$*" 2>&1 | tee $(O)/gls_$*.log

# The wafer.space precheck, cloned at PRECHECK_REV into .tools/ with the PDK revision it pins (its make clone-pdk).
$(PRECHECK)/precheck.py:
	git clone -q https://github.com/wafer-space/gf180mcu-precheck.git $(PRECHECK)
	git -C $(PRECHECK) checkout -q $(PRECHECK_REV)

precheck: $(PRECHECK)/precheck.py
	@mkdir -p $(O)/precheck
	$(NIX) "make -C $(PRECHECK) clone-pdk && cd $(PRECHECK) && PDK_ROOT=$(PRECHECK)/gf180mcu PDK=gf180mcuD \
	  python3 precheck.py --input $(CHIP_GDS) --top chip_top --slot 0p5x1 --workers 2 --threads 5 \
	  --output $(O)/precheck/chip_top.oas" 2>&1 | tee $(O)/precheck/precheck.log || true
	@grep -q "Precheck successfully completed" $(O)/precheck/precheck.log && echo "precheck: PASS" \
	  || { echo "precheck: FAIL, see $(O)/precheck/precheck.log"; exit 1; }

# Chip LVS of the last chip run (KLayout, tools/lvs/): see scripts/lvs.sh. THR=<workers> (default every CPU).
# Full-chip transistor LVS with the DC-DC (scripts/lvs_full.sh): CROC=abstract (default, minutes) or
# CROC=flat (croc_soc at transistor level, SRAMs as black boxes, flat mode, hours). Needs the block netlists
# of out/blk (tools/lvs/block_lvs.sh, extract_cells.py, struct.sh) and make merge.
CROC ?= abstract
# croc_soc on its own at transistor level (scripts/lvs_croc.sh), minutes. Together with lvs-full: every transistor.
lvs-croc: fetch
	$(NIX) "bash $(T)/scripts/lvs_croc.sh $(O)/lvs_croc" 2>&1 | tee $(O)/lvs_croc.log

lvs-full: fetch
	$(NIX) "CROC=$(CROC) bash $(T)/scripts/lvs_full.sh $(CR) $(O)/lvs_full_$(CROC)" 2>&1 | tee $(O)/lvs_full_$(CROC).log

lvs: fetch
	$(NIX) "bash $(T)/scripts/lvs.sh $(CR) $(O)/lvs" 2>&1 | tee $(O)/lvs.log

image:
	@mkdir -p $(O)
	$(NIX) "klayout -zz -r $(T)/scripts/render_gds.py -rd gds=$(CHIP_GDS) \
	  -rd lyp=$(T)/librelane/gf180mcu_render.lyp -rd out=$(O)/chip_top.png -rd width=4000"

overlay: fetch
	@mkdir -p $(O)
	$(NIX) "klayout -b -r $(T)/scripts/overlay.py -rd croc=$(T)/macros/croc/croc_soc.gds -rd dcdc=$(DCDC) \
	  -rd out=$(O)/overlay.gds"

# Pad labels as a GDS (out/pad_labels.gds) and the layer colours to see them over a chip (out/view.lyp).
labels:
	@mkdir -p $(O)
	$(NIX) "klayout -b -r $(T)/scripts/pad_labels.py -rd ring=$(T)/padring.txt -rd cfg=$(T)/librelane/pad_cfg.tcl \
	  -rd out=$(O)/pad_labels.gds"
	python3 $(T)/scripts/labels_lyp.py $(T)/librelane/gf180mcu_render.lyp $(O)/view.lyp

# A chip GDS with the pad labels over it, in KLayout: make view [CHIP=<gds>] (default: the last chip run)
view: labels
	$(NIX) "klayout -s $(or $(CHIP),$(CHIP_GDS)) $(O)/pad_labels.gds -l $(O)/view.lyp"

klayout:
	$(NIX) "librelane $(LL_CONFIGS) $(LL_OPTS) --last-run --flow OpenInKLayout"
openroad:
	$(NIX) "librelane $(LL_CONFIGS) $(LL_OPTS) --last-run --flow OpenInOpenROAD"

summary:
	@echo "chip run : $(CR)"
	@grep -A1 "^croc:" $(T)/sources.yaml | tail -1 | sed "s/^ */macro    : /"
	@grep -a -E "Flow complete|LibreLane will now quit" $(CR)/flow.log 2>/dev/null | tail -1 || true
	@cat $(CR)/*-misc-reportmanufacturability/manufacturability.rpt 2>/dev/null | grep -v "^$$" || true
	@grep -h "\[TB\] PASS\|\[TB\] FAIL" $(O)/gls_*.log 2>/dev/null | sed "s/^/gls: /" || true
	@grep -h "Precheck successfully completed" $(O)/precheck/precheck.log 2>/dev/null | head -1 | sed "s/^.*/precheck: PASS/" || true
