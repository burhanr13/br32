
%.bin: %.asm
	echo '#include "defs.asm"' > ../asm/.tmp.asm
	cat $< >> ../asm/.tmp.asm
	cd ../asm && customasm .tmp.asm -o $(abspath $@) && rm -rf .tmp.asm

.PRECIOUS: %.asm
%.asm: %.c
	./chibicc/chibicc -o $@ -Iinclude -S $<

.PHONY: clean
clean:
	rm -rf *.asm *.bin
