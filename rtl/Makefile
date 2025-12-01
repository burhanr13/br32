
.PHONY: build, clean

VERILATOR_ARGS := --exe --cc --build -Wall -Wno-unusedsignal -Wno-importstar --trace

LDPATH :=
ifeq ($(shell uname), Darwin)
	LDPATH +=-L$(shell brew --prefix)/lib
endif

build:
	verilator $(VERILATOR_ARGS) core.sv $(wildcard *_pkg.sv) testbench.cpp -LDFLAGS "$(LDPATH) -lSDL3"

clean:
	rm -rf obj_dir
