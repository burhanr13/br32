#!/bin/bash

make -C sim || exit 1

tools/make.sh || exit 1

args=

for a in $@; do
    if [[ $a == *.c || $a == *.s ]]; then
        make -C sw ../${a%.*}.bin || exit 1
        args+=" ${a%.*}.bin"
    else
        args+=" $a"
    fi
done

./sim/obj_dir/Vtop $args
