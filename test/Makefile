# Makefile — cocotb test runner for the ASICirific TinyTapeout subset.
# Default simulator is Icarus; uart_boot.sv is listed FIRST as a defensive
# ordering choice for the Icarus vvp backend.

SIM ?= icarus
TOPLEVEL_LANG ?= verilog
SRC = ../src

VERILOG_SOURCES += $(SRC)/uart_boot.sv
VERILOG_SOURCES += $(SRC)/asicirific_pkg.sv
VERILOG_SOURCES += $(SRC)/alu.sv
VERILOG_SOURCES += $(SRC)/reg_file.sv
VERILOG_SOURCES += $(SRC)/imm_gen.sv
VERILOG_SOURCES += $(SRC)/branch_comp.sv
VERILOG_SOURCES += $(SRC)/control_unit.sv
VERILOG_SOURCES += $(SRC)/forwarding_unit.sv
VERILOG_SOURCES += $(SRC)/hazard_unit.sv
VERILOG_SOURCES += $(SRC)/load_unit.sv
VERILOG_SOURCES += $(SRC)/store_unit.sv
VERILOG_SOURCES += $(SRC)/mul_unit.sv
VERILOG_SOURCES += $(SRC)/div_unit.sv
VERILOG_SOURCES += $(SRC)/csr_file.sv
VERILOG_SOURCES += $(SRC)/core_top.sv
VERILOG_SOURCES += $(SRC)/gshare_predictor.sv
VERILOG_SOURCES += $(SRC)/btb.sv
VERILOG_SOURCES += $(SRC)/ras.sv
VERILOG_SOURCES += $(SRC)/bp_top.sv
VERILOG_SOURCES += $(SRC)/jtag_tap.sv
VERILOG_SOURCES += $(SRC)/riscv_dtm.sv
VERILOG_SOURCES += $(SRC)/riscv_dm.sv
VERILOG_SOURCES += $(SRC)/debug_top.sv
VERILOG_SOURCES += $(SRC)/uart_tx.sv
VERILOG_SOURCES += $(SRC)/uart_rx.sv
VERILOG_SOURCES += $(SRC)/uart.sv
VERILOG_SOURCES += $(SRC)/gpio.sv
VERILOG_SOURCES += $(SRC)/spram.sv
VERILOG_SOURCES += $(SRC)/bus_fabric.sv
VERILOG_SOURCES += $(SRC)/main_soc.sv
VERILOG_SOURCES += $(SRC)/tt_um_asicirific.sv
VERILOG_SOURCES += tb.v

# Icarus needs -g2012 for SystemVerilog
COMPILE_ARGS += -g2012

TOPLEVEL = tb
MODULE   = test

include $(shell cocotb-config --makefiles)/Makefile.sim
