#!/bin/sh

export LC_ALL=C.UTF-8
export LANG=C.UTF-8

cd fit

while [ 1 ] ; do
    python3 ./fit.py appctrl
done
