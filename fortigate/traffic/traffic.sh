#!/bin/bash

conf="traffic.conf"
server_id=$(hostname|grep -o [0-9])
declare -A flows

while read flow
do
  if [ "${flow:0:1}" == "$server_id" ]
  then
    flows[$(echo "$flow" | awk '{print $2}')]=$(echo "$flow" | awk '{print $1}')
  fi
done < $conf

for flow in "${!flows[@]}"
do
  src_srv=$server_id
  src_site=$(echo "${flows[$flow]}" | awk -F ':' '{print $2}')
  src_vrf=$(echo "${flows[$flow]}" | awk -F ':' '{print $3}')
  dst_srv=$(echo "$flow" | awk -F ':' '{print $1}')
  dst_site=$(echo "$flow" | awk -F ':' '{print $2}')
  dst_vrf=$(echo "$flow" | awk -F ':' '{print $3}')

  echo Generating traffic from SRV-"$src_srv"/SITE-"$src_site"/VRF-"$src_vrf" to SRV-"$dst_srv"/SITE-"$dst_site"/VRF-"$dst_vrf"...
  set -x
  sudo ip addr add 10."$src_srv"0"$src_vrf"."$src_site".2/24 dev lan
  sudo  ip route add 10."$dst_srv"0"$dst_vrf"."$dst_site".0/24 via 10."$src_srv"0"$src_vrf"."$src_site".1 dev lan
  ping -I 10."$src_srv"0"$src_vrf"."$src_site".2 10."$dst_srv"0"$dst_vrf"."$dst_site".1 -c 10 > out-"$src_srv"_"$src_site"_"$src_vrf"-"$dst_srv"_"$dst_site"_"$dst_vrf" &
  set +x
done

sleep 1
echo Waiting for traffic completion...
wait

for flow in "${!flows[@]}"
do
  src_srv=$server_id
  src_site=$(echo "${flows[$flow]}" | awk -F ':' '{print $2}')
  src_vrf=$(echo "${flows[$flow]}" | awk -F ':' '{print $3}')
  dst_srv=$(echo "$flow" | awk -F ':' '{print $1}')
  dst_site=$(echo "$flow" | awk -F ':' '{print $2}')
  dst_vrf=$(echo "$flow" | awk -F ':' '{print $3}')

  echo Cleaning up traffic from SRV-"$src_srv"/SITE-"$src_site"/VRF-"$src_vrf"	to SRV-"$dst_srv"/SITE-"$dst_site"/VRF-"$dst_vrf"...
  set -x
  sudo ip route del 10."$dst_srv"0"$dst_vrf"."$dst_site".0/24 via 10."$src_srv"0"$src_vrf"."$src_site".1 dev lan
  sudo ip addr del 10."$src_srv"0"$src_vrf"."$src_site".2/24 dev lan
  set +x
done 

