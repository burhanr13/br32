#!/bin/bash

cd $(dirname $0)

mkdir -p bin
make -C chibicc
(cd br32-as && cargo build --release)
cp chibicc/chibicc bin
cp br32-as/target/release/br32-as bin

