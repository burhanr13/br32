#!/bin/bash

make -C rtl || exit 1

if [[ ${1#*.} == asm ]]; then
    customasm $1 || exit 1
    filename=${1%.*}.bin
else
    filename=$1
fi


./rtl/obj_dir/Vcore $filename
