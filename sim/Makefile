
.PHONY: build, clean

RTL := ../rtl

VERILATOR_ARGS := --exe --cc --build -Wall -Wno-unusedsignal -Wno-importstar -Wno-caseincomplete --trace -I$(RTL)

LDPATH :=
ifeq ($(shell uname), Darwin)
	LDPATH +=-L$(shell brew --prefix)/lib
endif

build:
	verilator $(VERILATOR_ARGS) $(RTL)/top.sv $(RTL)/$(wildcard $(RTL)/*_pkg.sv) sim_main.cpp -LDFLAGS "$(LDPATH) -lSDL3"

clean:
	rm -rf obj_dir
