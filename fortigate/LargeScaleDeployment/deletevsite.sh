#!/bin/bash



if [[ $# -ne 2 ]] 
 then 
  (echo "must give N and M as parameters"; exit 2)
 fi
export N=$1
export M=$2
export NN=`printf "1%02d" $N`
export VLANID=$(( ($N - $N%4 )/4*250 + $M ))

  virsh destroy site-$N-$M
  virsh undefine site-$N-$M  --remove-all-storage
  virsh net-destroy  mtap-eno4.$VLANID 
  virsh net-destroy  mtap-eno1.$VLANID 
  virsh net-undefine mtap-eno4.$VLANID 
  virsh net-undefine mtap-eno1.$VLANID 
  docker network rm c$NN-$M 
  docker network rm c$N-$M 

