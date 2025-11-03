#!/bin/bash

make -C rtl || exit 1

args=

for a in $@; do
    if [[ ${a#*.} == asm ]]; then
        customasm $a || exit 1
        args+=" ${a%.*}.bin"
    else
        args+=" $a"
    fi
done

./rtl/obj_dir/Vcore $args
