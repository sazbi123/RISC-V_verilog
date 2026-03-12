set -x
iverilog ./RV32IM_tb.v 
./a.out
gtkwave ./RV32IM.vcd 
rm a.out
rm RV32IM.vcd 
set +x