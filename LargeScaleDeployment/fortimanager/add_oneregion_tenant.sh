#!/bin/bash

if [ $# -ne 1 ]; then echo ERROR: Must provide tenant name in args; exit; fi

export LSD_TENANT=$1
export QUIET=1
set -o xtrace

./lsd_adom_add.py
./lsd_dev_add.py
./lsd_vpn_add.py
./lsd_sdwan_add.py
./lsd_install_policy.py
