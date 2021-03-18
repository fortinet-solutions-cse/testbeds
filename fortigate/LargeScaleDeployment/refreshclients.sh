#!/bin/bash -e



if [[ $# -ne 1 ]] 
 then 
  (echo "must give N "; exit 2)
 fi
export N=$1
export RESTARTED=""
for m in {1..250}
do
echo "check client-$N-$m:"
 if docker top client-$N-$m >/dev/null
 then
 echo "restarting client-$N-$m"
 docker restart client-$N-$m 
 else
 echo "client-$N-$m was not running do nothing"
 RESTARTED="$RESTARTED $m"
 fi
done
echo "client with network issues: $RESTARTED"