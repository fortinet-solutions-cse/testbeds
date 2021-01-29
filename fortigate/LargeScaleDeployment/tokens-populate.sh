#!/bin/bash -e
# populate the token poll from csv extracted from FelxVM portal
#


if [[ $# -ne 1 ]]
 then
  (echo "must pass the .csv file with the tokken parameters"; exit 2)
 fi



for t in `awk -F "," '{print $4}' $1 |grep -v "License File Token" |sed 's/"//g'`; do touch ~/tokens-pool/$t; done
