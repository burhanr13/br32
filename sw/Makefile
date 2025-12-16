
CC := ../tools/bin/chibicc
AS := ../tools/bin/br32-as

CFLAGS := -nostdinc -Ic/include -S

ASFLAGS :=
ifeq ($(SYMS), 1)
	ASFLAGS += -s
endif
ifneq ($(NOLIB), 1)
	ASFLAGS += asm/lib.s
endif

%.bin: %.s tools
	$(AS) -o $@ $(ASFLAGS) $<

.PRECIOUS: %.s
%.s: %.c tools
	$(CC) -o $@ $(CFLAGS) $<

%.ir: %.c tools
	$(CC) -o $@ $(CFLAGS) -emit-ir $<

.PHONY: tools
tools:
	../tools/make.sh

.PHONY: clean
clean:
	rm -rf *.bin *.bin.syms asm/*.bin asm/*.bin.syms c/*.asm c/*.bin c/*.bin.syms
