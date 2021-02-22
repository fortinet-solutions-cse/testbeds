# Large Scale Deployment 

This project goal is to have 2000/3000 VMs to test Fortinet management (FMG, FAZ, PORTAL) at large scale for MSSP usage.

Assumptions:
 hosts called massive<N> where N is 1 to 4

Limitations:
 1000 VMs per server (limit on the libvirt bridge)

See HyperVisorsSetup.md to set the hypervisor.

```shell
git clone https://github.com/fortinet-solutions-cse/testbeds.git -b LargeScaleDeployment
```

On FlexVM portal create a config (2cpu) and add as many entitlement as you need for 1 host.

Populate tokens-pool from file directly exported from portal
```bash
for t in `awk -F "," '{print $4}' LSD-tokens.csv|grep -v "License File Token" |sed 's/"//g'`; do touch tokens-pool/$t; done
```

# sites
Naming schema and access:
every VM is called branch-N-M where M<250

We have 4 hypervisors 10.210.15.[1-4] the VM is on machine N modulo 4, for example N=6 is on massive2 (10.210.15.2)

To access:
log on host: ssh fortinet@10.210.15.1 (passwd fortinet)

To ssh to console:
ssh admin@192.168.N.M
Or go to console:
virsh console branch-N-M

Network setup:
port2: 172.18.N.M/24

port3: 172.19.N.M/24

port4: 10.N.M.1/24
port5: 10.(100+N).M.1/24

Running a client on port4:
docker run --net=cn-m --ip=10.n.m.22 -it alpine /bin/sh

.22 is arbitrary you have /24 and will be the client ip
Running a client on port5:
docker run --net=c(100+n)-m --ip=10.(100+n).m.22 -it alpine /bin/sh

Create 1 to verify:
cd testbeds/fortigate/LargeScaleDeployment/

# FMG :
```shell
virt-install --name FMG6.4.4  --os-variant generic --ram 16000 --disk path=~/images/fmg.qcow2,bus=virtio --vcpus=4 --os-type=linux --cpu=host --import --noautoconsole --keymap=en-us --network network:mtap-eno2,model=virtio \
 --network network:mtap-eno3,model=virtio --disk path=/var/lib/libvirt/images/fmgdata1.qcow2,size=100,bus=virtio
```

Find non running VM: for m in {1..250}; do virsh domid site-5-$m >/dev/null ; done