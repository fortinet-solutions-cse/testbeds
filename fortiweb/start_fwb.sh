#!/bin/bash

#************************************************
#
# Use this script to start a FortiWeb VM with
# LibVirt, no VIM required.
# This has support for cloud init, see below how
# to build cdrom with proper content
#
# Miguel Angel Muñoz <magonzalez at fortinet.com>
#
# ************************************************

#************************************************
# Check FortiWeb VM existence
#************************************************

if [ -z "$1" ]; then
  echo "Need location of FortiWeb image"
  exit -1
fi
result=$(file $1)
if [[ $result == *"QEMU QCOW2 Image (v2)"* ]]; then
   echo "Supplied FortiWeb image is in: $1"
   FORTIWEB_QCOW2=$1
else
   echo "Supplied FortiWeb image does not look a qcow2 file"
   exit -1
fi
if [[ "$(realpath $FORTIWEB_QCOW2)" == "$(pwd)/fortios.qcow2" ]]; then
   echo "FortiWeb image can not be named fortios.qcow2 in this directory. Choose different location/name"
   exit -1
fi

export SF_NAME=fortiweb
export SF_IP_ADMIN=192.168.122.40
export SF_MAC_ADMIN=08:00:27:4c:22:40


rm -f fortiweb.qcow2
rm -rf cfg-drv-fgt
rm -rf ${SF_NAME}-cidata.iso

cp ${FORTIWEB_QCOW2} ./fortiweb.qcow2

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
    set ip ${SF_IP_ADMIN}/24
    set allowaccess https http FWB-manager ping snmp ssh telnet
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
config system global
  set admintimeout 480
end
config system admin
  edit admin
    set password m
    set force-password-change disable
  next
end

EOF

sudo mkisofs -publisher "OpenStack Nova 12.0.2" -J -R -V config-2 -o ${SF_NAME}-cidata.iso cfg-drv-fgt

virt-install --connect qemu:///system --noautoconsole --filesystem ${PWD},shared_dir \
--import --name ${SF_NAME} --ram 4096 --vcpus 2 \
--disk fortiweb.qcow2,size=3,bus=virtio --disk fwb-logs.qcow2,size=3,bus=virtio \
--disk ${SF_NAME}-cidata.iso,device=cdrom,bus=ide,format=raw,cache=none \
--network bridge=virbr0,mac=${SF_MAC_ADMIN},model=virtio
