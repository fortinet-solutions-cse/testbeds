#!/bin/bash -e
# DEPRECATED - not needed with new token mapping in tokens.csv file:
#  serialNumber, token, site-id
#
# Old: populate the token poll from csv extracted from FelxVM portal
#


if [[ $# -ne 1 ]]
 then
  (echo "must pass the .csv file with the tokken parameters"; exit 2)
 fi



for t in `awk -F "," '{print $2}' $1 |grep -v "License File Token" |sed 's/"//g'`; do touch ~/tokens-pool/$t; done
echo "You know have "`ls -l ~/tokens-pool/ |wc -l`" tokens"
