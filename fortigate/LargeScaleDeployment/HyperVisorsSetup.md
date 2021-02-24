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

You must install a bind9 dns server to avoid overloading the next stage equipments.
We do it on the massive1 but you can adapt:




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

Linux bridges and macvtap do not interact well at scale (600+ VMs/Docker)
So we move all on macvtap.


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
## perf
vm.min_free_kbytes=225280
### IMPROVE SYSTEM MEMORY MANAGEMENT ###
# src: https://rtcamp.com/tutorials/linux/sysctl-conf/
# Do less swapping
vm.swappiness = 10
vm.dirty_ratio = 60
vm.dirty_background_ratio = 2
### GENERAL NETWORK SECURITY OPTIONS ###
# Number of times SYNACKs for passive TCP connection.
net.ipv4.tcp_synack_retries = 2
# Allowed local port range
net.ipv4.ip_local_port_range = 2000 65535
# Protect Against TCP Time-Wait
net.ipv4.tcp_rfc1337 = 1
# Decrease the time default value for tcp_fin_timeout connection
net.ipv4.tcp_fin_timeout = 15
# Decrease the time default value for connections to keep alive
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 15
### TUNING NETWORK PERFORMANCE ###
# Default Socket Receive Buffer
net.core.rmem_default = 31457280
# Maximum Socket Receive Buffer
net.core.rmem_max = 12582912
# Default Socket Send Buffer
net.core.wmem_default = 31457280
# Maximum Socket Send Buffer
net.core.wmem_max = 12582912
# Increase number of incoming connections
net.core.somaxconn = 4096
# Increase number of incoming connections backlog
net.core.netdev_max_backlog = 65536
# Increase the maximum amount of option memory buffers
net.core.optmem_max = 25165824
# Increase the maximum total buffer-space allocatable
# This is measured in units of pages (4096 bytes)
net.ipv4.tcp_mem = 65536 131072 262144
net.ipv4.udp_mem = 65536 131072 262144
# Increase the read-buffer space allocatable
net.ipv4.tcp_rmem = 8192 87380 16777216
net.ipv4.udp_rmem_min = 16384
# Increase the write-buffer-space allocatable
net.ipv4.tcp_wmem = 8192 65536 16777216
net.ipv4.udp_wmem_min = 16384
# Increase the tcp-time-wait buckets pool size to prevent simple DOS attacks
net.ipv4.tcp_max_tw_buckets = 1440000
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
# ARP Cache
# Force gc to clean-up quickly
net.ipv4.neigh.default.gc_interval = 3600

# Set ARP cache entry timeout
net.ipv4.neigh.default.gc_stale_time = 3600

# Setup DNS threshold for arp
net.ipv4.neigh.default.gc_thresh3 = 14096
net.ipv4.neigh.default.gc_thresh2 = 12048
net.ipv4.neigh.default.gc_thresh1 = 11024


EOF

cat << EOF | sudo tee -a  /etc/sysctl.conf
fs.inotify.max_user_instances=1048576
fs.inotify.max_user_watches=1048576
EOF

#To see what is going on
sudo sysctl --system

```
## Hugepages cloud archives
in /etc/default/grub:
GRUB_CMDLINE_LINUX="default_hugepagesz=1G hugepagesz=1G hugepages=760"

Add cloud archive to ensure having the last kvm/qemu patches
```shell
sudo add-apt-repository cloud-archive:victoria
sudo update-grub
sudo apt update
sudo apt upgrade
```

# REBOOT 

Populate tokens-pool from file directly exported from portal
```bash
for t in `awk -F "," '{print $4}' LDS1-tokens.csv|grep -v "License File Token" |sed 's/"//g'`; do touch tokens-pool/$t; done
```