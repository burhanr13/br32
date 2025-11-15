
.PHONY: build, clean

VERILATOR_ARGS := --exe --cc --build -Wall -Wno-unusedsignal -Wno-importstar

build:
	verilator $(VERILATOR_ARGS) core.sv *_pkg.sv testbench.cpp -LDFLAGS -lSDL3

clean:
	rm -rf obj_dir
