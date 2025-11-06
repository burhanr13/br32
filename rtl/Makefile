
.PHONY: build, clean

VERILATOR_ARGS := --exe --cc --build -Wall -Wno-unusedsignal

build:
	verilator $(VERILATOR_ARGS) core.sv testbench.cpp

clean:
	rm -rf obj_dir
