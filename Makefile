# AC3E chip: the AC3E pad ring, the croc_soc macro and the DC-DC layouts in one chip_top.gds.
# Run every target from this folder in a normal shell. Each one enters the nix-shell of this repository.
#
#   make macro RUN=<croc run>   timing models of a manquehue_chip run, then point macros/croc at it
#   make ring                   src/chip_top.sv, librelane/pad_cfg.tcl and slot.yaml from padring.txt
#   make chip                   LibreLane: pad ring, croc_soc, wires (30 to 60 min)
#   make merge                  DC-DC layouts (DCDC) into the chip GDS: chip_top_dcdc.gds
#   make gls                    chip GLS: JTAG boot, flash + ADC read, flash + radio (gls-jtag, gls-adc, gls-radio)
#   make precheck               wafer.space precheck of the merged GDS
#   make image                  PNG of the chip GDS (out/chip_top.png)
#   make overlay                CROC macro + DC-DC layouts only, to check how they meet (out/overlay.gds)
#   make klayout | openroad     open the last chip run
#   make summary                results of the last chip run
#   make all RUN=<croc run>     macro, chip, merge, gls, precheck, summary
#
# Variables: CROC (manquehue_chip checkout), RUN (croc run under $(CROC)/outputs), CHIP_RUN (run under
# librelane/runs, default the newest), DCDC (folder of DC-DC layouts, default macros/dcdc_v0). Logs go to out/.

T          := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
CROC       ?= $(HOME)/Documents/manquehue_chip
RUN        ?= $(notdir $(realpath $(T)/macros/croc))
MACRO      := $(CROC)/outputs/$(RUN)
CHIP_RUN   ?= $(shell ls -t $(T)/librelane/runs 2>/dev/null | head -1)
CR         := $(T)/librelane/runs/$(CHIP_RUN)
DCDC       ?= $(T)/macros/dcdc_v0
CHIP_GDS    = $(if $(wildcard $(CR)/final/gds/chip_top_dcdc.gds),$(CR)/final/gds/chip_top_dcdc.gds,$(CR)/final/gds/chip_top.gds)
O          := $(T)/out
PRECHECK   ?= $(HOME)/Documents/gf180mcu-precheck
PRECHECK_PYTHONPATH ?= /nix/store/mxgvi3js4wjqh7azybkj4zx3fixh2cvb-python3.13-qrcode-8.2/lib/python3.13/site-packages
NIX        := cd $(T) && nix-shell --run

# PDK and LibreLane
PDK_ROOT   ?= $(T)/gf180mcu
PDK        ?= gf180mcuD
PDK_COMMIT ?= f6eeac7dad085ffcc829ccfd721f7b4ce39edcf7
LL_CONFIGS := librelane/slots/slot_ac3e.yaml librelane/macros/macros.yaml librelane/config.yaml
LL_OPTS    := --pdk $(PDK) --pdk-root $(PDK_ROOT) --manual-pdk --scl gf180mcu_fd_sc_mcu7t5v0 --pad gf180mcu_fd_io
CHIP_GLS   := TB=tb_chip_ac3e bash $(CROC)/scripts/sim/run_chip_gls.sh $(CR)/final/pnl/chip_top.pnl.v $(MACRO)/croc_soc.v

.PHONY: help all pdk macro ring chip merge gls gls-jtag gls-adc gls-radio precheck image overlay klayout openroad summary
.DEFAULT_GOAL := help
help:
	@sed -n "3,13p" $(T)/Makefile | sed "s/^# //"

all: macro chip merge gls precheck summary

pdk: $(PDK_ROOT)/ciel/gf180mcu/versions/$(PDK_COMMIT)/$(PDK)
$(PDK_ROOT)/ciel/gf180mcu/versions/$(PDK_COMMIT)/$(PDK):
	$(NIX) "ciel enable $(PDK_COMMIT) --pdk-root $(PDK_ROOT) --pdk-family $(PDK) --include-libraries all"

macro:
	@test -d $(MACRO) || { echo "no run $(MACRO)"; exit 1; }
	ls $(MACRO)/etm/croc_soc_slow.lib >/dev/null 2>&1 || bash $(CROC)/scripts/signoff/sta/extract_models.sh $(MACRO)
	@mkdir -p $(T)/macros
	ln -sfn $(MACRO) $(T)/macros/croc
	@echo "macros/croc -> $$(readlink $(T)/macros/croc)"

# The ring comes from padring.txt here. manquehue_chip keeps a copy to place the croc_soc pins: warn if the CROC
# pads (27 to 72) of the two copies differ, because then the macro pins no longer face their pads.
ring:
	python3 $(T)/scripts/gen_chip_ring.py $(T)/padring.txt
	@mkdir -p $(O)
	@awk '$$1=="pad" && $$2>=27 && $$2<=72' $(T)/padring.txt > $(O)/croc_pads.here
	@awk '$$1=="pad" && $$2>=27 && $$2<=72' $(CROC)/scripts/chip/padring.txt > $(O)/croc_pads.croc 2>/dev/null || true
	@cmp -s $(O)/croc_pads.here $(O)/croc_pads.croc || echo "WARNING: CROC pads differ from $(CROC)/scripts/chip/padring.txt: build the macro again"

chip: pdk
	@mkdir -p $(O)
	$(NIX) "librelane $(LL_CONFIGS) $(LL_OPTS)" 2>&1 | tee $(O)/chip_run.log

merge:
	@mkdir -p $(O)
	$(NIX) "klayout -b -r $(T)/scripts/merge_dcdc.py -rd input=$(CR)/final/gds/chip_top.gds \
	  -rd output=$(CR)/final/gds/chip_top_dcdc.gds -rd gds_dir=$(DCDC)" 2>&1 | tee $(O)/merge.log

gls: gls-jtag gls-adc gls-radio
gls-jtag:
	@mkdir -p $(O)
	$(NIX) "$(CHIP_GLS) $(O)/gls_jtag" 2>&1 | tee $(O)/gls_jtag.log
gls-adc:   GLS_SRC = ../spi/spi_adc.c
gls-radio: GLS_SRC = spi_radio.c
gls-adc gls-radio: gls-%:
	@mkdir -p $(O)
	$(NIX) "cd $(CROC)/sim/sw/flash && bash build.sh $(GLS_SRC) > /dev/null && \
	  VVP_ARGS=+flash=$(CROC)/sim/sw/flash/bin/spi_$*.flash.hex $(CHIP_GLS) $(O)/gls_$*" 2>&1 | tee $(O)/gls_$*.log

precheck:
	@mkdir -p $(O)/precheck
	$(NIX) "export PDK_ROOT=$(HOME)/.ciel PDK=gf180mcuD PYTHONPATH=$(PRECHECK_PYTHONPATH); cd $(PRECHECK) && \
	  python3 precheck.py --input $(CHIP_GDS) --slot 0p5x1 --workers 2 --threads 5 \
	  --output $(O)/precheck/chip_top.oas" 2>&1 | tee $(O)/precheck/precheck.log || true
	@grep -q "Precheck successfully completed" $(O)/precheck/precheck.log && echo "precheck: PASS" \
	  || { echo "precheck: FAIL, see $(O)/precheck/precheck.log"; exit 1; }

image:
	@mkdir -p $(O)
	$(NIX) "klayout -zz -r $(T)/scripts/render_gds.py -rd gds=$(CHIP_GDS) \
	  -rd lyp=$(T)/librelane/gf180mcu_render.lyp -rd out=$(O)/chip_top.png -rd width=4000"

overlay:
	@mkdir -p $(O)
	$(NIX) "klayout -b -r $(T)/scripts/overlay.py -rd croc=$(T)/macros/croc/croc_soc.gds -rd dcdc=$(DCDC) \
	  -rd out=$(O)/overlay.gds"

klayout:
	$(NIX) "librelane $(LL_CONFIGS) $(LL_OPTS) --last-run --flow OpenInKLayout"
openroad:
	$(NIX) "librelane $(LL_CONFIGS) $(LL_OPTS) --last-run --flow OpenInOpenROAD"

summary:
	@echo "chip run : $(CR)"
	@echo "macro    : $$(readlink $(T)/macros/croc)"
	@grep -a -E "Flow complete|LibreLane will now quit" $(CR)/flow.log 2>/dev/null | tail -1 || true
	@cat $(CR)/*-misc-reportmanufacturability/manufacturability.rpt 2>/dev/null | grep -v "^$$" || true
	@grep -h "\[TB\] PASS\|\[TB\] FAIL" $(O)/gls_*.log 2>/dev/null | sed "s/^/gls: /" || true
	@grep -h "Precheck successfully completed" $(O)/precheck/precheck.log 2>/dev/null | head -1 | sed "s/^.*/precheck: PASS/" || true
