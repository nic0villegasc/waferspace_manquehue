# Chip level of croc_soc on the AC3E padframe (slot ac3e). Every target runs the tools in this template's nix-shell.
#
#   make -f chip.mk macro      RUN=<croc run>  timing models of a croc_soc run, then point croc_macro at it
#   make -f chip.mk chip                       LibreLane chip flow (SLOT=ac3e), 30 to 60 min
#   make -f chip.mk merge                      DC-DC layouts (DCDC) into the chip GDS: chip_top_dcdc.gds
#   make -f chip.mk gls                        the three chip GLS: JTAG boot, flash + ADC read, flash + radio
#   make -f chip.mk gls-jtag | gls-adc | gls-radio
#   make -f chip.mk precheck                   wafer.space precheck without --cob, of chip_top_dcdc.gds if it exists
#   make -f chip.mk image                      PNG of the chip GDS (_ac3e/chip_top.png)
#   make -f chip.mk summary                    results of the chip run in one screen
#   make -f chip.mk all        RUN=<croc run>  macro, chip, merge, gls, precheck, summary
#
# Variables:
#   CROC      manquehue_chip checkout (default ~/Documents/manquehue_chip)
#   RUN       croc_soc run folder name under $(CROC)/outputs (default: the run croc_macro points at)
#   CHIP_RUN  LibreLane run folder under librelane/runs (default: the newest)
#   DCDC      folder with the DC-DC layouts for merge (default dcdc_macro)
# Logs and results go to _ac3e/.

T          := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
CROC       ?= $(HOME)/Documents/manquehue_chip
RUN        ?= $(notdir $(realpath $(T)/croc_macro))
MACRO      := $(CROC)/outputs/$(RUN)
CHIP_RUN   ?= $(shell ls -t $(T)/librelane/runs | head -1)
CR         := $(T)/librelane/runs/$(CHIP_RUN)
DCDC       ?= $(T)/dcdc_macro
CHIP_GDS    = $(if $(wildcard $(CR)/final/gds/chip_top_dcdc.gds),$(CR)/final/gds/chip_top_dcdc.gds,$(CR)/final/gds/chip_top.gds)
O          := $(T)/_ac3e
PRECHECK   ?= $(HOME)/Documents/gf180mcu-precheck
PRECHECK_PYTHONPATH ?= /nix/store/mxgvi3js4wjqh7azybkj4zx3fixh2cvb-python3.13-qrcode-8.2/lib/python3.13/site-packages
NIX        := cd $(T) && nix-shell --run
GLS        := TB=tb_chip_ac3e bash $(CROC)/scripts/sim/run_chip_gls.sh $(CR)/final/pnl/chip_top.pnl.v $(MACRO)/croc_soc.v

.PHONY: all macro chip merge gls gls-jtag gls-adc gls-radio precheck image summary
all: macro chip merge gls precheck summary

macro:
	@test -d $(MACRO) || { echo "no run $(MACRO)"; exit 1; }
	@test -d $(CROC)/outputs/.cache || cp -a $(HOME)/Documents/manquehue_chip/outputs/.cache $(CROC)/outputs/
	ls $(MACRO)/etm/croc_soc_slow.lib >/dev/null 2>&1 || bash $(CROC)/scripts/signoff/sta/extract_models.sh $(MACRO)
	ln -sfn $(MACRO) $(T)/croc_macro
	@echo "croc_macro -> $$(readlink $(T)/croc_macro)"

chip:
	@mkdir -p $(O)
	$(NIX) "make librelane SLOT=ac3e" 2>&1 | tee $(O)/chip_run.log

merge:
	@mkdir -p $(O)
	$(NIX) "klayout -b -r $(T)/scripts/merge_dcdc.py -rd input=$(CR)/final/gds/chip_top.gds \
	  -rd output=$(CR)/final/gds/chip_top_dcdc.gds -rd gds_dir=$(DCDC)" 2>&1 | tee $(O)/merge.log

gls: gls-jtag gls-adc gls-radio

gls-jtag:
	@mkdir -p $(O)
	$(NIX) "$(GLS) $(O)/gls_jtag" 2>&1 | tee $(O)/gls_jtag.log

gls-adc gls-radio: gls-%:
	@mkdir -p $(O)
	$(NIX) "cd $(CROC)/sim/sw/flash && bash build.sh $(GLS_SRC) > /dev/null && $(GLS_FLASH)" 2>&1 \
	  | tee $(O)/gls_$*.log
gls-adc:   GLS_SRC = ../spi/spi_adc.c
gls-radio: GLS_SRC = spi_radio.c
gls-adc:   GLS_FLASH = TB=tb_chip_ac3e VVP_ARGS=+flash=$(CROC)/sim/sw/flash/bin/spi_adc.flash.hex bash $(CROC)/scripts/sim/run_chip_gls.sh $(CR)/final/pnl/chip_top.pnl.v $(MACRO)/croc_soc.v $(O)/gls_adc
gls-radio: GLS_FLASH = TB=tb_chip_ac3e VVP_ARGS=+flash=$(CROC)/sim/sw/flash/bin/spi_radio.flash.hex bash $(CROC)/scripts/sim/run_chip_gls.sh $(CR)/final/pnl/chip_top.pnl.v $(MACRO)/croc_soc.v $(O)/gls_radio

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

summary:
	@echo "chip run : $(CR)"
	@echo "macro    : $$(readlink $(T)/croc_macro)"
	@grep -a -E "Flow complete|LibreLane will now quit" $(CR)/flow.log 2>/dev/null | tail -1 || true
	@cat $(CR)/*-misc-reportmanufacturability/manufacturability.rpt 2>/dev/null | grep -v "^$$"
	@grep -h "COUNT" $(CR)/*-magic-drc/reports/drc.magic.rpt 2>/dev/null | sed 's/^/magic: /'
	@grep -a "Overall" $(CR)/*-openroad-stapostpnr/summary.rpt 2>/dev/null | awk -F'│' '{print "hold WNS", $$3, " setup WNS", $$8, " max cap", $$13, " max slew", $$14}'
	@grep -h "\[TB\] PASS\|\[TB\] FAIL" $(O)/gls_*.log 2>/dev/null | sed 's/^/gls: /' || true
	@grep -h "Precheck successfully completed" $(O)/precheck/precheck.log 2>/dev/null | head -1 | sed 's/^.*/precheck: PASS/' || true
