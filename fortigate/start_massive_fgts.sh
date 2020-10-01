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
if [[ $result == *"QEMU QCOW Image (v"* ]]; then
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

export SF_NAME=fortigate
export SF_IP_BASE=192.168.122
export SF_MAC_ADMIN=08:00:27:4c:22:40

rm -f fortios.qcow2
rm -rf cfg-drv-fgt
rm -rf ${SF_NAME}-cidata.iso

cp ${FORTIGATE_QCOW2} ./fortios.qcow2


server_id=$(hostname|grep -o [0-9])


################################
# Network: mpls_a
################################

sudo virsh net-destroy mpls_a
sudo virsh net-undefine mpls_a

sudo ip link add name mpls_a type bridge
sudo ip link set mpls_a up

cat >mpls_a <<EOF
<network>
  <name>mpls_a</name>
  <forward mode='bridge'/>
  <bridge name='mpls_a'/>
</network>
EOF
sudo virsh net-define mpls_a
sudo virsh net-start mpls_a
sudo virsh net-autostart mpls_a
sudo ip link set em1 master mpls_a


################################
# Network: mpls_b
################################

sudo virsh net-destroy mpls_b
sudo virsh net-undefine mpls_b

sudo ip link add name mpls_b type bridge
sudo ip link set mpls_b up

cat >mpls_b <<EOF
<network>
  <name>mpls_b</name>
  <forward mode='bridge'/>
  <bridge name='mpls_b'/>
</network>
EOF
sudo virsh net-define mpls_b
sudo virsh net-start mpls_b
sudo virsh net-autostart mpls_b
sudo ip link set em2 master mpls_b

################################
# Network: lan
################################

sudo virsh net-destroy lan
sudo virsh net-undefine lan
cat >lan <<EOF
<network>
  <name>lan</name>
  <forward mode='route'>
  </forward>
  <bridge name='lan' stp='off' delay='0'/>
  <mac address='52:54:00:79:7c:c3'/>
  <ip address='10.${server_id}.2.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='10.${server_id}.2.2' end='10.${server_id}.2.254'/>
    </dhcp>
  </ip>
</network>
EOF
sudo virsh net-create lan
sudo virsh net-autostart lan

mkdir -p cfg-drv-fgt/openstack/latest/
mkdir -p cfg-drv-fgt/openstack/content/

install()
{
    for i in {2..251}
#    for i in 242 249 250 251
    do
        echo $i

        cat >cfg-drv-fgt/openstack/content/0000 <<EOF
-----BEGIN FGT VM LICENSE-----
<empty> Put your license here
-----END FGT VM LICENSE-----
EOF

        #v FGT 6.2.3

        cat >cfg-drv-fgt/openstack/latest/user_data <<EOF
config system interface
  edit "port1"
    set vdom "root"
    set mode static
    set ip ${SF_IP_BASE}.${i}/24
    set allowaccess ping https ssh snmp http telnet fgfm radius-acct probe-response fabric ftm 
    set mtu-override enable
    set mtu 1460
  next
  edit "m1v1"
      set vdom "root"
      set type vlan
      set ip 172.11.1.${i} 255.255.0.0
      set allowaccess ping https ssh http fgfm      
      set interface "port2"
      set vlanid 11
  next
  edit "m1v2"
      set vdom "root"
      set type vlan
      set ip 172.12.1.${i} 255.255.0.0
      set allowaccess ping
      set interface "port2"
      set vlanid 12
  next
  edit "m1v3"
      set vdom "root"
      set type vlan
      set ip 172.13.1.${i} 255.255.0.0
      set allowaccess ping
      set interface "port2"
      set vlanid 13
  next
  edit "m1v4"
      set vdom "root"
      set type vlan
      set ip 172.14.1.${i} 255.255.0.0
      set allowaccess ping
      set interface "port2"
      set vlanid 14
  next
  edit "m1v5"
      set vdom "root"
      set type vlan
      set ip 172.15.1.${i} 255.255.0.0
      set allowaccess ping
      set interface "port2"
      set vlanid 15
  next
  edit "m1v6"
      set vdom "root"
      set type vlan
      set ip 172.16.1.${i} 255.255.0.0
      set allowaccess ping
      set interface "port2"
      set vlanid 16
  next
  edit "m1v7"
      set vdom "root"
      set type vlan
      set ip 172.17.1.${i} 255.255.0.0
      set allowaccess ping
      set interface "port2"
      set vlanid 17
  next
  edit "m1v8"
      set vdom "root"
      set type vlan
      set ip 172.18.1.${i} 255.255.0.0
      set allowaccess ping
      set interface "port2"
      set vlanid 18
  next 
  edit "m2v1"
      set vdom "root"
      set type vlan
      set ip 172.21.1.${i} 255.255.0.0
      set interface "port3"
      set vlanid 21
  next
  edit "m2v2"
      set vdom "root"
      set type vlan
      set ip 172.22.1.${i} 255.255.0.0
      set allowaccess ping
      set interface "port3"
      set vlanid 22
  next
  edit "m2v3"
      set vdom "root"
      set type vlan
      set ip 172.23.1.${i} 255.255.0.0
      set allowaccess ping
      set interface "port3"
      set vlanid 23
  next
  edit "m2v4"
      set vdom "root"
      set type vlan
      set ip 172.24.1.${i} 255.255.0.0
      set allowaccess ping
      set interface "port3"
      set vlanid 24
  next
  edit "m2v5"
      set vdom "root"
      set type vlan
      set ip 172.25.1.${i} 255.255.0.0
      set allowaccess ping
      set interface "port3"
      set vlanid 25
  next 
  edit "m2v6"
      set vdom "root"
      set type vlan
      set ip 172.26.1.${i} 255.255.0.0
      set allowaccess ping
      set interface "port3"
      set vlanid 26
  next
  edit "m2v7"
      set vdom "root"
      set type vlan
      set ip 172.27.1.${i} 255.255.0.0
      set allowaccess ping
      set interface "port3"
      set vlanid 27
  next
  edit "m2v8"
      set vdom "root"
      set type vlan
      set ip 172.28.1.${i} 255.255.0.0
      set allowaccess ping
      set interface "port3"
      set vlanid 28
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
  set hostname fgt${i}
end
config system admin
 edit admin
  set password m
 next
end
EOF


        mkisofs -publisher "OpenStack Nova 12.0.2" -J -R -V config-2 -o ${SF_NAME}${i}-cidata.iso cfg-drv-fgt

        cp ${FORTIGATE_QCOW2} ./fortios${i}.qcow2
        virt-install --connect qemu:///system --noautoconsole \
        --cpu host,-vmx \
        --import --name ${SF_NAME}${i} \
        --ram 2048 --vcpus 1 --disk fortios${i}.qcow2,size=2 \
        --disk ${SF_NAME}${i}-cidata.iso,device=cdrom,bus=ide,format=raw,cache=none \
        --network bridge=virbr0,model=virtio \
        --network bridge=mpls_a,model=virtio \
        --network bridge=mpls_b,model=virtio \
        --network bridge=lan,model=virtio
    done
}

start()
{
    for i in {2..251}
    do
        echo $i
        sudo virsh  start fortigate${i}
    done

}

destroy()
{
    for i in {2..251}
    do
        echo $i
        sudo virsh  destroy fortigate${i}
        sudo virsh  undefine fortigate${i}
    done

}

check_license()
{
    for i in {2..251}
    do
        echo $i
        sshpass -pm ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null admin@192.168.122.${i} get system status|grep License
        
    done

}


run_ssh_massively()
{
server_id=$(hostname|grep -o [0-9])
SF_IP_BASE=192.168.122
for i in {2..251}
do
echo $i
sshpass -pm ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null admin@192.168.122.${i} "config system interface
edit port1
set vdom root
set mode static
set ip ${SF_IP_BASE}.${i}/24
set allowaccess ping https ssh snmp http telnet fgfm radius-acct probe-response fabric ftm 
set mtu-override enable
set mtu 1460
next
edit m1v1
set vdom root
set type vlan
set ip 172.11.${server_id}.${i} 255.255.0.0
set allowaccess ping https ssh http fgfm      
set interface port2
set vlanid 11
next
edit m1v2
set vdom root
set type vlan
set ip 172.12.${server_id}.${i} 255.255.0.0
set allowaccess ping
set interface port2
set vlanid 12
next
edit m1v3
set vdom root
set type vlan
set ip 172.13.${server_id}.${i} 255.255.0.0
set allowaccess ping
set interface port2
set vlanid 13
next
edit m1v4
set vdom root
set type vlan
set ip 172.14.${server_id}.${i} 255.255.0.0
set allowaccess ping
set interface port2
set vlanid 14
next
edit m1v5
set vdom root
set type vlan
set ip 172.15.${server_id}.${i} 255.255.0.0
set allowaccess ping
set interface port2
set vlanid 15
next
edit m1v6
set vdom root
set type vlan
set ip 172.16.${server_id}.${i} 255.255.0.0
set allowaccess ping
set interface port2
set vlanid 16
next
edit m1v7
set vdom root
set type vlan
set ip 172.17.${server_id}.${i} 255.255.0.0
set allowaccess ping
set interface port2
set vlanid 17
next
edit m1v8
set vdom root
set type vlan
set ip 172.18.${server_id}.${i} 255.255.0.0
set allowaccess ping
set interface port2
set vlanid 18
next 
edit m2v1
set vdom root
set type vlan
set ip 172.21.${server_id}.${i} 255.255.0.0
set interface port3
set vlanid 21
next
edit m2v2
set vdom root
set type vlan
set ip 172.22.${server_id}.${i} 255.255.0.0
set allowaccess ping
set interface port3
set vlanid 22
next
edit m2v3
set vdom root
set type vlan
set ip 172.23.${server_id}.${i} 255.255.0.0
set allowaccess ping
set interface port3
set vlanid 23
next
edit m2v4
set vdom root
set type vlan
set ip 172.24.${server_id}.${i} 255.255.0.0
set allowaccess ping
set interface port3
set vlanid 24
next
edit m2v5
set vdom root
set type vlan
set ip 172.25.${server_id}.${i} 255.255.0.0
set allowaccess ping
set interface port3
set vlanid 25
next 
edit m2v6
set vdom root
set type vlan
set ip 172.26.${server_id}.${i} 255.255.0.0
set allowaccess ping
set interface port3
set vlanid 26
next
edit m2v7
set vdom root
set type vlan
set ip 172.27.${server_id}.${i} 255.255.0.0
set allowaccess ping
set interface port3
set vlanid 27
next
edit m2v8
set vdom root
set type vlan
set ip 172.28.${server_id}.${i} 255.255.0.0
set allowaccess ping
set interface port3
set vlanid 28
next  
edit vl_v1
set vdom root
set type emac-vlan
set vrf 1
set ip 10.${server_id}01.${i}.1 255.255.255.0
set allowaccess ping
set interface port4
next
edit vl_v2
set vdom root
set type emac-vlan
set vrf 2
set ip 10.${server_id}02.${i}.1 255.255.255.0
set allowaccess ping
set interface port4
next
edit vl_v3
set vdom root
set type emac-vlan
set vrf 3
set ip 10.${server_id}03.${i}.1 255.255.255.0
set allowaccess ping
set interface port4
next
edit vl_v4
set vdom root
set type emac-vlan
set vrf 4
set ip 10.${server_id}04.${i}.1 255.255.255.0
set allowaccess ping
set interface port4
next
edit vl_v5
set vdom root
set type emac-vlan
set vrf 5
set ip 10.${server_id}05.${i}.1 255.255.255.0
set allowaccess ping
set interface port4
next
edit vl_v6
set vdom root
set type emac-vlan
set vrf 6
set ip 10.${server_id}06.${i}.1 255.255.255.0
set allowaccess ping
set interface port4
next
edit vl_v7
set vdom root
set type emac-vlan
set vrf 7
set ip 10.${server_id}07.${i}.1 255.255.255.0
set allowaccess ping
set interface port4
next
edit vl_v8
set vdom root
set type emac-vlan
set vrf 8
set ip 10.${server_id}08.${i}.1 255.255.255.0
set allowaccess ping
set interface port4
next  
end
config system dns
set primary 8.8.8.8
set secondary 8.8.4.4
end
config router static
edit 2
set gateway 192.168.122.1
set device port1
next
end
config system global
set admintimeout 480
set hostname fgt${i}
end
config system admin
edit admin
set password m
next
end
"
        
done

}


install
#destroy