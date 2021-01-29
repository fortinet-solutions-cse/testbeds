# Notes about Large Scale Deployment

# Host setup

Ubuntu 20.04.
Docker: 
```shell
echo "$USER ALL=(ALL) NOPASSWD:ALL" |  sudo tee /etc/sudoers.d/99-nopasswd
sudo apt install -y virtinst unzip byobu zile libvirt-clients virt-manager
## landscape-sysinfo was blocking the re-login under load (probably due to huge number of nics)
 
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
sudo usermod -a -G libvirt $(whoami)
mkdir ~/configs ~/images ~/tokens-pool
## use all the disk
sudo lvextend -L 433G -r /dev/ubuntu-vg/ubuntu-lv
sudo apt purge -y landscape-common
```
need to reset session for usermod to be taken into account.

Setup eno2/eno3 for KVM:

Create a file in: /etc/netplan/01-wans.yaml example is for massive2 you must adapt the last digit.
Need those to be up for macvtap to work
```shell
# This is the network config written by 'subiquity'
network:
  ethernets:
    eno2:
      addresses:
      - 172.18.0.2/16
      nameservers:
        addresses:
        - 8.8.8.8
    eno3:
      addresses:
      - 172.19.0.2/16
      nameservers:
        addresses:
        - 8.8.8.8
    eno4:
      addresses:
      - 10.0.0.2/8
      nameservers:
        addresses:
        - 8.8.8.8

  version: 2
```

Destroy default (to extend to a /16 instead of /8)
```bash
virsh net-destroy default
virsh net-undefine default
```
```xml
<network>
  <name>default</name>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='virbr0' stp='on' delay='0'/>
  <ip address='192.168.0.1' netmask='255.255.0.0'>
    <dhcp>
      <range start='192.168.0.2' end='192.168.254.254'/>
    </dhcp>
  </ip>
</network>
```
```shell
virsh net-define --file default.xml 
virsh net-autostart default
```



```shell

for i in {2..4}
do
 cat <<EOF > macvtap-$i.xml
 <network>
  <name>mtap-eno$i</name>
  <forward mode="bridge">
    <interface dev="eno$i"/>
  </forward>
</network>
EOF
virsh net-define macvtap-$i.xml
virsh net-autostart mtap-eno$i
done
```

## prepare for massive number of proc/files etc..

```shell
  cat << EOF | sudo tee -a  /etc/security/limits.conf 
#Add    rules to allow massive VMs in production type of setups
*  soft  nofile  1048576 #  unset  maximum number of open files
*  hard  nofile  1048576  #unset  maximum number of open files
root  soft  nofile  1048576  #unset  maximum number of open files
root  hard  nofile  1048576  #unset  maximum number of open files
*  soft  memlock  unlimited  #unset  maximum locked-in-memory address space (KB)
*  hard  memlock  unlimited #unset  maximum locked-in-memory address space (KB)
EOF

cat << EOF  | sudo tee /etc/sysctl.d/90-lsd.conf 
fs.inotify.max_queued_events=1048576
fs.inotify.max_user_instances=1048576
fs.inotify.max_user_watches=1048576
vm.max_map_count=262144
net.core.netdev_max_backlog=182757
EOF

cat << EOF | sudo tee -a  /etc/sysctl.conf
fs.inotify.max_user_instances=1048576
fs.inotify.max_user_watches=1048576
EOF

sudo rm /usr/lib/sysctl.d/juju-2.0.conf
#To see what is going on
sudo sysctl --system
```

# REBOOT 

Populate tokens-pool from file directly exported from portal
```bash
for t in `awk -F "," '{print $4}' LDS1-tokens.csv|grep -v "License File Token" |sed 's/"//g'`; do touch tokens-pool/$t; done
```