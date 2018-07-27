#!/bin/bash

#************************************************
#
# Use this script to start a FortiGate VM with
# LibVirt, no VIM required.
# This has support for cloud init, see below how
# to build cdrom with proper content
#
# Miguel Angel Muñoz <magonzalez at fortinet.com>
#
# ************************************************

#************************************************
# Check Fortigate VM existence
#************************************************

if [ -z "$1" ]; then
  echo "Need location of Fortigate image"
  exit -1
fi
result=$(file $1)
if [[ $result == *"QEMU QCOW Image (v2)"* ]]; then
   echo "Supplied Fortigate image is in: $1"
   FORTIGATE_QCOW2=$1
else
   echo "Supplied Fortigate image does not look a qcow2 file"
   exit -1
fi
if [[ "$(realpath $FORTIGATE_QCOW2)" == "$(pwd)/fortios-nsh.qcow2" ]]; then
   echo "FortiGate image can not be named fortios-nsh.qcow2 in this directory. Choose different location/name"
   exit -1
fi

export SF_NAME=fortigate-nsh
export SF_IP_ADMIN=192.168.122.42
export SF_MAC_ADMIN=08:00:27:4c:22:42
export SF_MAC=08:00:27:4c:70:40
export SF_MAC2=08:00:27:4c:80:40

rm -f fortios-nsh.qcow2
rm -rf cfg-drv-fgt
rm -rf ${SF_NAME}-cidata.iso

cp ${FORTIGATE_QCOW2} ./fortios-nsh.qcow2

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
    set vdom "root"
    set mode static
    set ip ${SF_IP_ADMIN}/24
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
config system global
  set admintimeout 480
end
EOF

cat >virbr1 <<EOF
<network>
  <name>virbr1</name>
  <bridge name='virbr1' stp='off' delay='0' />
  <mac address='52:54:00:79:7c:c4'/>
</network>
EOF

cat >virbr2 <<EOF
<network>
  <name>virbr2</name>
  <bridge name='virbr2' stp='off' delay='0' />
  <mac address='52:54:00:79:7c:c5'/>
</network>
EOF

sudo virsh net-create virbr1
sudo virsh net-create virbr2

sudo mkisofs -publisher "OpenStack Nova 12.0.2" -J -R -V config-2 -o ${SF_NAME}-cidata.iso cfg-drv-fgt
virt-install --connect qemu:///system --noautoconsole --filesystem ${PWD},shared_dir --import --name ${SF_NAME} --ram 1024 --vcpus 1 --disk fortios-nsh.qcow2,size=3 --disk fgt-logs-nsh.qcow2,size=3 --disk ${SF_NAME}-cidata.iso,device=cdrom,bus=ide,format=raw,cache=none --network bridge=virbr0,mac=${SF_MAC_ADMIN},model=virtio --network bridge=virbr1,mac=${SF_MAC},model=virtio --network bridge=virbr2,mac=${SF_MAC2},model=virtio
