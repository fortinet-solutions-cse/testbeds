#!/bin/bash

#************************************************
#
# Use this script to start a FortiManager VM with
# LibVirt, no VIM required.
# This has support for cloud init, see below how
# to build cdrom with proper content
#
# Miguel Angel Muñoz <magonzalez at fortinet.com>
#
# ************************************************

#************************************************
# Check FortiManager VM existence
#************************************************

if [ -z "$1" ]; then
  echo "Need location of FortiManager image"
  exit -1
fi
result=$(file $1)
if [[ "$result" == *"QEMU QCOW2 Image (v"* ]]; then
   echo "Supplied FortiManager image is in: $1"
   FORTIMANAGER_QCOW2=$1
else
   echo "Supplied FortiManager image does not look a qcow2 file"
   exit -1
fi
if [[ "$(realpath $FORTIMANAGER_QCOW2)" == "$(pwd)/fortimanager.qcow2" ]]; then
   echo "Fortimanager image can not be copied to fortimanager.qcow2 in this directory. Choose different location/name"
   exit -1
fi

export SF_NAME=fortimanager
export SF_IP_ADMIN=192.168.122.41
export SF_MAC_ADMIN=08:00:27:4c:22:41
export SF_MAC=08:00:27:4c:70:40
export SF_MAC2=08:00:27:4c:80:40

rm -f fortimanager.qcow2
rm -rf cfg-drv-fmg
rm -rf ${SF_NAME}-cidata.iso

cp ${FORTIMANAGER_QCOW2} ./fortimanager.qcow2

cp ${FORTIGATE_QCOW2} ./fortios.qcow2

mkdir -p cfg-drv-fgt/openstack/latest/
mkdir -p cfg-drv-fgt/openstack/content/

cat >cfg-drv-fgt/openstack/content/0000 <<EOF
-----BEGIN FMG VM LICENSE-----
<empty> Put your license here
-----END FMG VM LICENSE-----
EOF

#v FGT 6.2.3

cat >cfg-drv-fgt/openstack/latest/user_data <<EOF
config system interface
  edit "port1"
    set ip ${SF_IP_ADMIN}/24
    set allowaccess http https ping snmp ssh webservice
  next
end
config system admin user
  edit admin
    set password m
  next
end
config system global
    set hostname FMG-VM64-KVM
end
EOF

sudo mkisofs -publisher "OpenStack Nova 12.0.2" -J -R -V config-2 -o ${SF_NAME}-cidata.iso cfg-drv-fgt

virt-install --connect qemu:///system --noautoconsole --filesystem ${PWD},shared_dir --import \
  --cpu host,-vmx \
  --name ${SF_NAME} --ram 4096 --vcpus 2 --disk fortimanager.qcow2,size=3 \
  --disk ${SF_NAME}-cidata.iso,device=cdrom,bus=ide,format=raw,cache=none \
  --network bridge=virbr0,mac=${SF_MAC_ADMIN},model=virtio \
  --disk fmg-logs.qcow2,size=3


# config system admin setting
# set shell-access enable
# execute shell
