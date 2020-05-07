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
if [[ $result == *"QEMU QCOW2 Image (v"* ]]; then
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
export SF_IP_INCOMING=192.168.100.40
export SF_MAC_INCOMING=08:00:27:4c:00:40
export SF_IP_OUTGOING=10.192.0.150
export SF_MAC_OUTGOING=08:00:27:4c:00:50

sudo virsh destroy ${SF_NAME}
sudo virsh undefine ${SF_NAME}

rm -f fortiweb.qcow2
rm -rf cfg-drv-fgt
rm -rf ${SF_NAME}-cidata.iso
rm virbr1

sudo virsh net-destroy virbr1
sudo virsh net-undefine virbr1

cp ${FORTIWEB_QCOW2} ./fortiweb.qcow2

#************************************************
#  Create Networks
#************************************************

cat >virbr1 <<EOF
<network>
  <name>virbr1</name>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='virbr1' stp='on' delay='0'/>
  <mac address='52:54:00:79:7c:c3'/>
  <ip address='192.168.100.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.100.2' end='192.168.100.254'/>
      <host mac='${SF_MAC_INCOMING}' name='fortiweb' ip='${SF_IP_INCOMING}'/>
    </dhcp>
  </ip>
</network>
EOF

sudo virsh net-define virbr1
sudo virsh net-start virbr1

#************************************************
#  Create ISO for CloudInit
#************************************************

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
  edit "port2"
    set mode static
    set ip ${SF_IP_INCOMING}/24
  next
  edit "port3"
    set mode static
    set ip ${SF_IP_OUTGOING}/16
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

#************************************************
#  Start FortiWeb
#************************************************

virt-install --connect qemu:///system --noautoconsole --filesystem ${PWD},shared_dir --import --name ${SF_NAME} --ram 4096 --vcpus 2 --disk fortiweb.qcow2,size=3 --disk fwb-logs.qcow2,size=3 --disk ${SF_NAME}-cidata.iso,device=cdrom,bus=ide,format=raw,cache=none --network bridge=virbr0,mac=${SF_MAC_ADMIN},model=virtio  --network bridge=virbr1,mac=${SF_MAC_INCOMING},model=virtio --network bridge=br-b05a2f1d507a,mac=${SF_MAC_OUTGOING},model=virtio
