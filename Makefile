# Basys 3 build, see TN20K-DonkeyKong/basys3/README.md.

PRJ_DIR   := TN20K-DonkeyKong/basys3
PRJ       := dkong_basys3
VIVADO    ?= /tools/Xilinx/Vivado/2020.2/bin/vivado
WORK      := /tmp/$(PRJ)_bitstream
PROMS     := TN20K-DonkeyKong/proms/.done
GEN_PROMS := $(addprefix TN20K-DonkeyKong/proms/,dkong_prog ROM3N ROM3P ROM7C ROM7D ROM7E ROM7F \
             pal1_rom pal2_rom col_rom snd/dkong_cpu1 snd/dkong_cpu2)
BIT       := $(PRJ_DIR)/$(PRJ).runs/impl_1/$(PRJ).bit
# bitstream inputs: project, build script, project sources, core sources, PROM VHDL
DEPS      := $(PRJ_DIR)/$(PRJ).xpr $(PRJ_DIR)/build.tcl $(PROMS) \
             $(shell find $(PRJ_DIR)/$(PRJ).srcs TN20K-DonkeyKong/src -type f) \
             $(wildcard TN20K-DonkeyKong/proms/*.vhd TN20K-DonkeyKong/proms/snd/*.vhd)

define BUILD
	mkdir -p $(WORK)
	cd $(WORK) && $(VIVADO) -mode batch -nolog -nojournal \
	    -source $(CURDIR)/$(PRJ_DIR)/build.tcl -tclargs $(CURDIR)/$(PRJ_DIR)/$(PRJ).xpr
	rm -rf $(WORK)
	@echo "Bitstream: $(BIT)"
endef

.PHONY: help roms bitstream load clean

help:
	@echo "roms       compile make_vhdl_prom, unzip dkong.zip and samples/dkong.zip from ROMDIR (default ~/roms), generate PROM VHDL"
	@echo "bitstream  Vivado batch build of $(PRJ_DIR)/$(PRJ).xpr (runs roms if PROM VHDL is missing)"
	@echo "load       program the Basys 3 SRAM (openFPGALoader); builds first if the bitstream is missing or older than its inputs"
	@echo "clean      remove roms, generated PROM VHDL and Vivado outputs (all regenerated)"

roms $(PROMS):
	TN20K-DonkeyKong/tools/make_dkong_proms.sh

bitstream: $(PROMS)
	$(BUILD)

$(BIT): $(DEPS)
	$(BUILD)

load: $(BIT)
	openFPGALoader -b basys3 $(BIT)

clean:
	rm -f $(addsuffix .vhd,$(GEN_PROMS)) $(PROMS)
	rm -rf TN20K-DonkeyKong/tools/unzip TN20K-DonkeyKong/tools/tools_prom_src/bin
	rm -rf $(addprefix $(PRJ_DIR)/$(PRJ).,cache gen hw ip_user_files runs sim)
