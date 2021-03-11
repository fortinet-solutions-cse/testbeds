#!/bin/bash

# LSD-Customer1,2,26 were done manually

for i in {3..19}
do
  cat > tenants/LSD-Customer$i/tenant.yaml.j2 << EOF
---
fgt_user: admin
fgt_password: fortinet
fmg_user: admin
fmg_password: fortinet
adom: LSD-Customer$i

regions:
  - name: OneRegion
    shortname: OL
    dc-id:
      - $(( 8*(i-2) ))
    hubs:
      - site-1-$(( 8*(i-2) ))
    edge:
      {% for M in range($(( 8*(i-2)+1 )), $(( 8*(i-2)+8 ))) %}
      - site-1-{{ M }}
      {% endfor %}
EOF
done

for i in {20..25}
do
  cat > tenants/LSD-Customer$i/tenant.yaml.j2 << EOF
---
fgt_user: admin
fgt_password: fortinet
fmg_user: admin
fmg_password: fortinet
adom: LSD-Customer$i

regions:
  - name: OneRegion
    shortname: OL
    dc-id:
      - $(( 16*(i-11) ))
      - $(( 16*(i-11)+1 ))
    hubs:
      - site-1-$(( 16*(i-11) ))
      - site-1-$(( 16*(i-11)+1 ))
    edge:
      {% for M in range($(( 16*(i-11)+2 )), $(( 16*(i-11)+16 ))) %}
      - site-1-{{ M }}
      {% endfor %}
EOF
done
