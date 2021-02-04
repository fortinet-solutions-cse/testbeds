#!/bin/bash -e

HOSTID=`hostname -s|sed 's/massive//g'`

for N in 0 1 2 3
do
 NN=$((N*4+HOSTID))
 echo "### For N=$NN ###"
 echo "sites: $(virsh list | grep "site-$NN"|wc -l)/250"
 echo "clients port4: $(docker ps | grep "client-$NN-"|wc -l)/250"
 export N100=`printf "1%02d" $N`
 echo "clients port5: $(docker ps | grep "client-$N100^X-"|wc -l)/250"
done


