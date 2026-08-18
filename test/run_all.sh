#!/usr/bin/env bash
# Runs every module testbench and prints a pass/fail summary.
# Usage: cd test && ./run_all.sh
set -u
SRC=../src
IV="iverilog -g2012"
FAIL=0
run () {  # $1 top tb, $2... sources
  local top=$1; shift
  $IV -o /tmp/_tb -s $top "$@" 2>/dev/null
  local line
  line=$(timeout 120 vvp /tmp/_tb 2>/dev/null | grep -E "PASS|FAIL" | tail -1)
  echo "$line"
  echo "$line" | grep -q FAIL && FAIL=1
}

echo "=== ASICirific module testbenches ==="
run tb_branch_comp   $SRC/branch_comp.sv                                   tb_branch_comp.sv
run tb_serial_alu    $SRC/asicirific_pkg.sv $SRC/serial_alu.sv             tb_serial_alu.sv
run tb_serial_rf     $SRC/serial_rf.sv                                     tb_serial_rf.sv
run tb_imm_gen       $SRC/asicirific_pkg.sv $SRC/imm_gen.sv                tb_imm_gen.sv
run tb_load_unit     $SRC/asicirific_pkg.sv $SRC/load_unit.sv             tb_load_unit.sv
run tb_store_unit    $SRC/asicirific_pkg.sv $SRC/store_unit.sv           tb_store_unit.sv
run tb_gpio          $SRC/gpio.sv                                          tb_gpio.sv
run tb_mem_bus       $SRC/mem_bus.sv                                       tb_mem_bus.sv
run tb_spi_mem       $SRC/asicirific_pkg.sv $SRC/spi_mem.sv spi_models.sv  tb_spi_mem.sv
run tb_serial_core   $SRC/asicirific_pkg.sv $SRC/serial_alu.sv $SRC/serial_rf.sv \
                     $SRC/imm_gen.sv $SRC/load_unit.sv $SRC/store_unit.sv \
                     $SRC/branch_comp.sv $SRC/serial_core.sv               tb_serial_core.sv
run tb_tt_um_asicirific $SRC/asicirific_pkg.sv $SRC/serial_alu.sv $SRC/serial_rf.sv $SRC/imm_gen.sv $SRC/load_unit.sv $SRC/store_unit.sv $SRC/branch_comp.sv $SRC/serial_core.sv $SRC/spi_mem.sv $SRC/gpio.sv $SRC/mem_bus.sv $SRC/tt_um_asicirific.sv spi_models.sv tb_tt_um_asicirific.sv
echo "====================================="
if [ $FAIL -eq 0 ]; then echo "ALL TESTBENCHES PASSED"; else echo "SOME TESTBENCHES FAILED"; fi
exit $FAIL
