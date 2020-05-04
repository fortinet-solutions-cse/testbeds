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
if [[ $result == *"QEMU QCOW2 Image (v"* ]]; then
   echo "Supplied Fortigate image is in: $1"
   FORTIGATE_QCOW2=$1
else
   echo "Supplied Fortigate image does not look a qcow2 file"
   exit -1
fi
if [[ "$(realpath $FORTIGATE_QCOW2)" == "$(pwd)/fortios.qcow2" ]]; then
   echo "FortiGate image can not be named fortios.qcow2 in this directory. Choose different location/name"
   exit -1
fi

export FGT_NAME=fortigate
export FGT_IP_ADMIN=192.168.122.40
export FGT_MAC_ADMIN=08:00:27:4c:22:40
export FGT_IP_CLIENT=192.168.70.41
export FGT_IP_SERVER=192.168.70.42
export FGT_MAC_CLIENT=08:00:27:4c:70:41
export FGT_MAC_SERVER=08:00:27:4c:70:42

rm -f fortios.qcow2
rm -rf cfg-drv-fgt
rm -rf ${FGT_NAME}-cidata.iso

cp ${FORTIGATE_QCOW2} ./fortios.qcow2

#************************************************
#  Create Networks
#************************************************

sudo virsh net-destroy virbr_client 2> /dev/null
sudo virsh net-destroy virbr_server 2> /dev/null

sudo virsh net-undefine virbr_client 2> /dev/null
sudo virsh net-undefine virbr_server 2> /dev/null

cat >virbr_client <<EOF
<network>
  <name>virbr_client</name>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='virbr_client' stp='on' delay='0'/>
  <mac address='52:54:00:79:7c:c3'/>
  <ip address='192.168.70.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.70.2' end='192.168.70.254'/>
      <host mac='${FGT_MAC_CLIENT}' name='fgt_client_port' ip='${FGT_IP_CLIENT}'/>
    </dhcp>
  </ip>
</network>
EOF

cat >virbr_server <<EOF
<network>
  <name>virbr_server</name>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='virbr_server' stp='on' delay='0'/>
  <mac address='52:54:00:79:7c:c5'/>
  <ip address='192.168.80.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.80.2' end='192.168.80.254'/>
      <host mac='${FGT_MAC_SERVER}' name='fgt_server_port' ip='${FGT_IP_SERVER}'/>
    </dhcp>
  </ip>
</network>
EOF


sudo virsh net-create virbr_client
sudo virsh net-create virbr_server
sudo virsh net-update default delete ip-dhcp-host "<host mac='${FGT_MAC_ADMIN}'/>" --live
sudo virsh net-update default add ip-dhcp-host "<host mac='${FGT_MAC_ADMIN}' name='mgmt' ip='${FGT_IP_ADMIN}'/>" --live


mkdir -p cfg-drv-fgt/openstack/latest/
mkdir -p cfg-drv-fgt/openstack/content/

#************************************************
# Create metadata for client/server
#************************************************

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
    set ip ${FGT_IP_ADMIN}/24
    set allowaccess ping https ssh snmp http telnet fgfm radius-acct probe-response fabric ftm     
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
  set hostname FGT-VM64-KVM
end
config system admin
  edit admin
    set password m
  next
end
EOF

sudo mkisofs -publisher "OpenStack Nova 12.0.2" -J -R -V config-2 -o ${FGT_NAME}-cidata.iso cfg-drv-fgt
virt-install --connect qemu:///system --noautoconsole --filesystem ${PWD},shared_dir --import --name ${FGT_NAME} \
   --ram 1024 --vcpus 1 \
   --disk fortios.qcow2,size=3 --disk fgt-logs.qcow2,size=3 \
   --disk ${FGT_NAME}-cidata.iso,device=cdrom,bus=ide,format=raw,cache=none \
   --network bridge=virbr0,mac=${FGT_MAC_ADMIN},model=virtio \
   --network bridge=virbr_client,mac=${FGT_MAC_CLIENT},model=virtio --network bridge=virbr_server,mac=${FGT_MAC_SERVER},model=virtio 

