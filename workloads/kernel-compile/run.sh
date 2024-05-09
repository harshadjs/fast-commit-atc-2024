#!/bin/bash

MNT=$1

cp config ${MNT}/.config
cd $MNT
time wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.15.144.tar.xz
time tar -xf linux-5.15.144.tar.xz
cd linux-5.15.144
make olddefconfig
time make -j 64