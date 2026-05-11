#!/bin/bash
BASE=/home/lazagga/Arch/HW04

for i in 1 2 3 4 5 6 7; do
    TC=$BASE/testcase$i
    cp $BASE/CPU.v $BASE/CTRL.v $BASE/ALU.v $BASE/RF.v $BASE/MEM.v $BASE/GLOBAL.v $BASE/CPU_tb.v $TC/
    cd $TC
    compile_err=$(iverilog -o sim CPU_tb.v CPU.v CTRL.v ALU.v RF.v MEM.v 2>&1)
    if [ -n "$compile_err" ]; then
        echo "TC$i COMPILE ERROR: $compile_err"
    else
        out=$(timeout 10 ./sim 2>&1)
        echo "TC$i: $out"
    fi
done
