#!/bin/bash -e
# Build the site VM corresponding N and M (M between 1-250)
#
#if not set use the calling folder for finding the flavor def and kvm images


if [[ $# -ne 2 ]] 
 then 
  (echo "must give N and M as parameters"; exit 2)
 fi
export N=$1
export M=$2
export NAME=site-$N-$M
## Network will be 100+N
export NN=`printf "1%02d" $N`
HOSTID=`hostname -s|sed 's/massive//g'`
export ROOT=$PWD
if [[ $(($N%4)) != "$HOSTID" ]]
 then 
  echo " with N=$N you must run this on massive$(($N%4))"
  exit 2
fi
##was export VLANID=`printf "%d%03d" $N $M`
## VLAN id is limited to 4095
## We have 4 host N is mapped to host # : N modulo 4 (N=5 goes to massive1)
## Then we try to now waste blocks of 250 on vlanid so N=5 means we want VLANID=250+M 
## VLANID=M is for N=1 
export VLANID=$(( ($N - $N%4 )/4*250 + $M ))

virsh net-start mtap-eno4.$VLANID
virsh net-start mtap-eno1.$VLANID

virsh start site-$N-$M