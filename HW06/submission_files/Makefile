VFILES = GLOBAL.v ALU.v CTRL.v RF.v MEM.v HAZARD.v FORWARD.v BP.v CPU.v CPU_tb.v

sim: $(VFILES)
	iverilog -o sim $(VFILES)

run: sim
	vvp sim

clean:
	rm -f sim a.out
