
.PHONY: build, clean

VERILATOR_ARGS := --exe --cc --build -Wall -Wno-unusedsignal -Wno-importstar

LDPATH :=
ifeq ($(shell uname), Darwin)
	LDPATH +=-L$(shell brew --prefix)/lib
endif

build:
	verilator $(VERILATOR_ARGS) core.sv testbench.cpp -LDFLAGS "$(LDPATH) -lSDL3"

clean:
	rm -rf obj_dir
