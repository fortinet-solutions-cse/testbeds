#!/bin/bash

#************************************************
# Check Fortigate VM existence
#************************************************
set -x

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
if [[ "$(realpath $FORTIGATE_QCOW2)" == "$(pwd)/fortios.qcow2" ]]; then
   echo "FortiGate image can not be named fortios.qcow2 in this directory. Choose different location/name"
   exit -1
fi

#************************************************
#
#************************************************

export FGT_NAME=fortigate_for_cenx
export FGT_IP_ADMIN=192.168.122.40
export FGT_IP_CLIENT=192.168.70.40
export FGT_IP_SERVER=192.168.80.40
export FGT_MAC_ADMIN=08:00:27:4c:22:40
export FGT_MAC_CLIENT=08:00:27:4c:70:40
export FGT_MAC_SERVER=08:00:27:4c:80:40

export CLIENT_IP=192.168.70.41
export CLIENT_MAC=08:00:27:4c:70:41

export SERVER_IP=192.168.80.41
export SERVER_MAC=08:00:27:4c:80:41

#************************************************
#
#************************************************


rm -f fortios.qcow2
rm -f client.img
rm -f server.img
rm -rf cfg-drv-fgt
rm -rf ${FGT_NAME}-cidata.iso
rm -f client-cidata.iso
rm -f server-cidata.iso
rm user-data
rm meta-data



sudo virsh net-destroy virbr_client
sudo virsh net-destroy virbr_server

sudo virsh net-undefine virbr_client
sudo virsh net-undefine virbr_server

sudo virsh destroy  ${FGT_NAME}
sudo virsh undefine ${FGT_NAME}

sudo virsh destroy  client
sudo virsh undefine client

sudo virsh destroy  server
sudo virsh undefine server

#************************************************
#  Get OS image
#************************************************


if [ ! -e xenial-server-cloudimg-amd64-disk1.img ]; then
# wget http://download.cirros-cloud.net/0.4.0/xenial-server-cloudimg-amd64-disk1.img
 wget https://cloud-images.ubuntu.com/xenial/20180215/xenial-server-cloudimg-amd64-disk1.img
fi

cp ${FORTIGATE_QCOW2} ./fortios.qcow2
cp xenial-server-cloudimg-amd64-disk1.img ./client.img
cp xenial-server-cloudimg-amd64-disk1.img ./server.img


#************************************************
#  Create Networks
#************************************************

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
      <host mac='${CLIENT_MAC}' name='client' ip='${CLIENT_IP}'/>
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
      <host mac='${SERVER_MAC}' name='server' ip='${SERVER_IP}'/>
      <host mac='${FGT_MAC_SERVER}' name='fgt_server_port' ip='${FGT_IP_SERVER}'/>
    </dhcp>
  </ip>
</network>
EOF


sudo virsh net-create virbr_client
sudo virsh net-create virbr_server
sudo virsh net-update default delete ip-dhcp-host "<host mac='${FGT_MAC_ADMIN}' name='mgmt' ip='${FGT_IP_ADMIN}'/>" --live
sudo virsh net-update default add ip-dhcp-host "<host mac='${FGT_MAC_ADMIN}' name='mgmt' ip='${FGT_IP_ADMIN}'/>" --live
#************************************************
# Create metadata for client/server
#************************************************

cat >meta-data <<EOF
instance-id: client
local-hostname: client
EOF

cat >user-data <<EOF
#cloud-config
ssh_pwauth: true           <--allows password based ssh login
disable_root: false        <--enables root
manage_etc_hosts: true
users:
  - name: user
    gecos: Host User Replicated
    passwd: \$1\$xyz\$Ilzr7fdQW.frxCgmgIgVL0
    ssh-authorized-keys:
      - $(cat ${HOME}/.ssh/id_rsa.pub)
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    inactive: false
    lock_passwd: false
  - name: sfc
    gecos: sfc additional user
    ssh-authorized-keys:
      - $(cat ${HOME}/.ssh/id_rsa.pub)
    passwd: \$1\$xyz\$Ilzr7fdQW.frxCgmgIgVL0
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    inactive: false
    lock_passwd: false
EOF

genisoimage -output client-cidata.iso -volid cidata -joliet -rock user-data meta-data

cat >meta-data <<EOF
instance-id: server
local-hostname: server
EOF

genisoimage -output server-cidata.iso -volid cidata -joliet -rock user-data meta-data

#************************************************
# Prepare cloudinit
#************************************************

sudo virt-sysprep -a client.img --root-password password:m \
    --delete /var/lib/cloud/* \
    --firstboot-command 'useradd -m -p "" user ; ssh-keygen -A; rm -rf /var/lib/cloud/*;  cloud-init init'


#************************************************
# Create metadata for Fortigate
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
    set vdom root
    set mode dhcp
    set allowaccess https ping ssh snmp http telnet fgfm radius-acct probe-response capwap ftm
  next
  edit "port2"
    set vdom root
    set mode dhcp
  next
  edit "port3"
    set vdom root
    set mode dhcp
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
config firewall policy
    edit 1
        set name "Policy1"
        set srcintf "port2"
        set dstintf "port3"
        set srcaddr "all"
        set dstaddr "all"
        set action accept
        set schedule "always"
        set service "ALL"
        set utm-status enable
        set av-profile "default"
        set webfilter-profile "default"
        set dnsfilter-profile "default"
        set ips-sensor "default"
        set application-list "default"
        set profile-protocol-options "default"
        set ssl-ssh-profile "certificate-inspection"
        set nat enable
    next
end



EOF


#************************************************
# Start VMs
#************************************************

sudo mkisofs -publisher "OpenStack Nova 12.0.2" -J -R -V config-2 -o ${FGT_NAME}-cidata.iso cfg-drv-fgt
virt-install --connect qemu:///system --noautoconsole --filesystem ${PWD},shared_dir --import --name ${FGT_NAME} \
 --ram 1024 --vcpus 1 --disk fortios.qcow2,size=3 --disk fgt-logs.qcow2,size=2 \
 --disk ${FGT_NAME}-cidata.iso,device=cdrom,bus=ide,format=raw,cache=none \
 --network bridge=virbr0,mac=${FGT_MAC_ADMIN},model=virtio \
 --network bridge=virbr_client,mac=${FGT_MAC_CLIENT},model=virtio \
 --network bridge=virbr_server,mac=${FGT_MAC_SERVER},model=virtio \


virt-install --connect qemu:///system --noautoconsole --filesystem ${PWD},shared_dir --import --name client \
 --ram 1024 --vcpus 1 --disk client.img,size=1 \
 --disk ./client-cidata.iso,device=cdrom,bus=ide,format=raw,cache=none\
 --network bridge=virbr_client,mac=${CLIENT_MAC},model=virtio

virt-install --connect qemu:///system --noautoconsole --filesystem ${PWD},shared_dir --import --name server \
 --ram 1024 --vcpus 1 --disk server.img,size=1 \
 --disk ./server-cidata.iso,device=cdrom,bus=ide,format=raw,cache=none \
 --network bridge=virbr_server,mac=${SERVER_MAC},model=virtio


#************************************************
# Additional commands
#************************************************
retries=30
while [ $retries -gt 0 ]
do
    result=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null user@192.168.70.41  'sudo ip route | grep 192.168.80')
    if [ $? -eq 0 ] ; then
        break
    fi
    echo "Installing route in client..."
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null user@192.168.70.41  sudo ip route add 192.168.80.0/24 dev ens4 via 192.168.70.40
    sleep 5
    retries=$((retries-1))
done

retries=30
while [ $retries -gt 0 ]
do
    result=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null user@192.168.80.41  'sudo apt -f install python')
    if [ $? -eq 0 ] ; then
        break
    fi
    echo "Installing route in client..."
    sleep 5
    retries=$((retries-1))
done

ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null user@192.168.80.41  sudo python -m SimpleHTTPServer 80 &

echo "*******************************************************************"
echo "* FINISHED!!!                                                     *"
echo "* Use root/m, user/m or sfc/m as possible user/password logins    *"
echo "*******************************************************************"
