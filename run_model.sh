#!/bin/bash

make -C rtl

./rtl/obj_dir/Vcore $@
