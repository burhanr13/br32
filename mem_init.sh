#!/bin/bash

args=

for a in $@; do
    if [[ $a == *.asm ]]; then
        customasm $a || exit 1
        args+=" ${a%.*}.bin"
    elif [[ $a == *.c ]]; then
        make -C c ../${a%.*}.bin || exit 1
        args+=" ${a%.*}.bin"
    else
        args+=" $a"
    fi
done

xxd -ps -c1 $args > rtl/init.mem
