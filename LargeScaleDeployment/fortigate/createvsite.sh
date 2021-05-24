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

## remove any running VM and associated networks with the targeted name
l=`virsh list --all|grep "site-$N-$M " ; true`
if [ -n "$l" ]
 then
  virsh destroy site-$N-$M || true
  virsh undefine site-$N-$M  --remove-all-storage
  virsh net-destroy  mtap-eno4.$VLANID || true
  virsh net-destroy  mtap-eno1.$VLANID || true
  virsh net-undefine mtap-eno4.$VLANID || true
  virsh net-undefine mtap-eno1.$VLANID || true
  docker network rm c$NN-$M || true
  docker network rm c$N-$M || true
 fi

## destroy running VM
fuser -vk ~/images/${NAME}.qcow2 || echo "no ${NAME}.qcow2 probably cleaned" # should kill VM using it
##erase and recreate the qcow2
rm -f  ~/images/${NAME}.qcow2 /var/lib/libvirt/images/${NAME}-logs.qcow2
cd ~/images/
## use cp instead of unzip to allow parallel runs.
cp fortios.qcow2 ${NAME}.qcow2
# clean then create the config drive
cd ~/configs/
rm -rf cfg-$N-$M
rm -rf day0-$N-$M.iso
mkdir -p cfg-$N-$M/openstack/latest/
mkdir -p cfg-$N-$M/openstack/content/

export ROUTER_IP=192.168.0.1
export SSHKEY=`cat ~/.ssh/id_rsa.pub`

## create a sub eno4.NM macvtap capable network (due to the way docker handle macvtap)
NETFILE=`mktemp`
cat > $NETFILE <<EOF
 <network>
  <name>mtap-eno4.$VLANID</name>
  <forward mode="bridge">
    <interface dev="eno4.$VLANID"/>
  </forward>
</network>
EOF

docker network create -d macvlan --subnet=10.$N.$M.0/24 --gateway=10.$N.$M.1 -o parent=eno4.$VLANID c$N-$M

virsh net-define $NETFILE
virsh net-start mtap-eno4.$VLANID

## create a sub eno1.NM macvtap capable network (due to the way docker handle macvtap)
## Network will be 100+N

NETFILE=`mktemp`
cat > $NETFILE <<EOF
 <network>
  <name>mtap-eno1.$VLANID</name>
  <forward mode="bridge">
    <interface dev="eno1.$VLANID"/>
  </forward>
</network>
EOF

docker network create -d macvlan --subnet=10.$NN.$M.0/24 --gateway=10.$NN.$M.1 -o parent=eno1.$VLANID c$NN-$M

virsh net-define $NETFILE
virsh net-start mtap-eno1.$VLANID

# Calculate vcpu based on site being a hub or spoke
hub_sites=(site-5-1 site-5-2 site-5-3 site-5-4 site-5-5 \
    site-5-6 site-5-7 site-5-8 site-5-9 site-5-10 \
    site-2-1 site-3-1)
    
if [[ " ${hub_sites[@]} " =~ " site-$N-$M " ]]; then
    VCPUS=4
    RAM=8192
else
    VCPUS=1
    RAM=2048
fi

# A new token is generated for each site. Note license is still the same
# belonging to site-N-M but the token is regenerated on each call.
export TOKEN=$(flex_vm_get_token site-$N-$M)
[ -z $TOKEN ] && (echo "FAILED to FIND a TOKEN"; exit -2)

cd $ROOT
envsubst < ./site-conf.tmpl > ~/configs/cfg-$N-$M/openstack/latest/user_data
cd ~/configs/
genisoimage -publisher "OpenStack Nova 12.0.2" -J -R -V config-2 -o day0-$N-$M.iso cfg-$N-$M
virt-install --name ${NAME} --os-variant generic --ram ${RAM}  \
--disk path=~/images/${NAME}.qcow2,bus=virtio --disk ~/configs/day0-$N-$M.iso,device=cdrom,bus=ide,format=raw \
--vcpus=${VCPUS} --os-type=linux --cpu=host --import --noautoconsole --keymap=en-us \
--network network:mtap-eno1.$VLANID,model=virtio --network network:mtap-eno2,model=virtio \
--network network:mtap-eno3,model=virtio --network network:mtap-eno4.$VLANID,model=virtio
##optionnal add a log disk for long running tests --disk path=/var/lib/libvirt/images/foslogs.qcow2,size=10,bus=virtio \



echo "site-$N.$M created"

## following if when you want to ensure the VM is up before next step (like API/ssh)
## won't use to speed up the process.

###wait to have enough ping to avoid testing in the middle of the VM reboots for license
#echo "waiting the vm to be up"
#until (ping -c 18 $IP|grep ' 0% packet loss,')
#do
# sleep 5
# echo "waiting the vm to be up"
#done
#
#ssh -o StrictHostKeyChecking=no admin@$IP "diag debug vm-print-license"
#
## TODO add a check license to avoid wasting TOKENS

