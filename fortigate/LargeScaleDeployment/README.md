# Large Scale Deployment 

This project goal is to have 2000/3000 VMs to test Fortinet management (FMG, FAZ, PORTAL) at large scale for MSSP usage.








Populate tokens-pool from file directly exported from portal
```bash
for t in `awk -F "," '{print $4}' LDS1-tokens.csv|grep -v "License File Token" |sed 's/"//g'`; do touch tokens-pool/$t; done
```