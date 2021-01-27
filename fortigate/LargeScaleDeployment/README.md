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

Create 1 to verify:
cd testbeds/fortigate/LargeScaleDeployment/

