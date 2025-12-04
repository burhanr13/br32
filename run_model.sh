#!/bin/bash

make -C sim || exit 1

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

./sim/obj_dir/Vtop $args
