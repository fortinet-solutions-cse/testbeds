#!/bin/bash

#************************************************
#
# Use this script to start a Fortiadc VM with
# LibVirt, no VIM required.
# This has support for cloud init, see below how
# to build cdrom with proper content
#
# Miguel Angel Muñoz <magonzalez at fortinet.com>
#
# ************************************************

#************************************************
# Check Fortiadc VM existence
#************************************************

if [ -z "$1" ]; then
  echo "Need location of FortiAdc image"
  exit -1
fi
if [ -z "$2" ]; then
  echo "Need location of FortiAdc data image"
  exit -1
fi
result=$(file $1)
if [[ $result == *"QEMU QCOW Image (v3)"* ]]; then
   echo "Supplied Fortiadc image is in: $1"
   FORTIADC_QCOW2=$1
else
   echo "Supplied Fortiadc image does not look a qcow2 file"
   exit -1
fi
result=$(file $2)
if [[ $result == *"QEMU QCOW Image (v3)"* ]]; then
   echo "Supplied Fortiadc data image is in: $2"
   FORTIADC_DATA_QCOW2=$2
else
   echo "Supplied Fortiadc data image does not look a qcow2 file"
   exit -1
fi
if [[ "$(realpath $FORTIADC_QCOW2)" == "$(pwd)/fortiadc.qcow2" ]]; then
   echo "Fortiadc image can not be named fortiadc.qcow2 in this directory. Choose different location/name"
   exit -1
fi

export FAD_NAME=fortiadc
export FAD_IP_ADMIN=192.168.122.40
export FAD_IP=192.168.70.40
export FAD_IP2=192.168.80.40
export FAD_MAC_ADMIN=08:00:27:4c:22:40
export FAD_MAC=08:00:27:4c:70:40
export FAD_MAC2=08:00:27:4c:80:40


virsh destroy ${FAD_NAME}
virsh undefine ${FAD_NAME}

rm -f fortiadc.qcow2
rm -f fortiadc-data.qcow2
rm -rf cfg-drv-fgt
rm -rf ${FAD_NAME}-cidata.iso


cp ${FORTIADC_QCOW2} ./fortiadc.qcow2
cp ${FORTIADC_DATA_QCOW2} ./fortiadc-data.qcow2

mkdir -p cfg-drv-fgt/openstack/latest/
mkdir -p cfg-drv-fgt/openstack/content/

cat >cfg-drv-fgt/openstack/content/0000 <<EOF
-----BEGIN FGT VM LICENSE-----
<empty> Put your license here
-----END FGT VM LICENSE-----
EOF

cat >cfg-drv-fgt/openstack/latest/user_data <<EOF
config system interface
  edit "port1"
    set mode static
    set ip 192.168.122.40/24
    set allowaccess https ping ssh snmp http telnet fgfm radius-acct probe-response capwap ftm
  next
end
config system dns
  set primary 8.8.8.8
  set secondary 8.8.4.4
end
config router static
  edit 2
    set gateway 192.168.122.1
    set device "port1"
  next
end
EOF

sudo mkisofs -publisher "OpenStack Nova 12.0.2" -J -R -V config-2 -o ${FAD_NAME}-cidata.iso cfg-drv-fgt
virt-install --connect qemu:///system --noautoconsole --filesystem ${PWD},shared_dir --import --name ${FAD_NAME} \
--ram 4096 --vcpus 1 --disk fortiadc.qcow2,size=3,bus=virtio --disk ${FORTIADC_DATA_QCOW2},bus=virtio \
--network bridge=virbr0,mac=${FAD_MAC_ADMIN},model=virtio \
--network bridge=virbr0,mac=${FAD_MAC},model=virtio \
--network bridge=virbr0,mac=${FAD_MAC2},model=virtio \
--disk ${FAD_NAME}-cidata.iso,device=cdrom,bus=ide,format=raw,cache=none