#!/bin/bash

# LSD-Customer1,2,26 were done manually

# LSD-Customer2
cat > tenants/LSD-Customer2/tenant.yaml.j2 << EOF
---
fgt_user: admin
fgt_password: fortinet
fmg_user: admin
fmg_password: fortinet
faz_user: admin
faz_password: fortinet
adom: LSD-Customer2

regions:
  - name: OneRegion
    shortname: OL
    dc-id:
      - 1
    hubs:
      - site-1-1
    edge:
      {% for M in range(2, 8) %}
      - site-1-{{ M }}
      {% endfor %}
EOF

# LSD-Customer3-19
for i in {3..19}
do
  cat > tenants/LSD-Customer$i/tenant.yaml.j2 << EOF
---
fgt_user: admin
fgt_password: fortinet
fmg_user: admin
fmg_password: fortinet
faz_user: admin
faz_password: fortinet
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

# LSD-Customer20-25
for i in {20..25}
do
  cat > tenants/LSD-Customer$i/tenant.yaml.j2 << EOF
---
fgt_user: admin
fgt_password: fortinet
fmg_user: admin
fmg_password: fortinet
faz_user: admin
faz_password: fortinet
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

# LSD-Customer26
cat > tenants/LSD-Customer26/tenant.yaml.j2 << EOF
---
fgt_user: admin
fgt_password: fortinet
fmg_user: admin
fmg_password: fortinet
faz_user: admin
faz_password: fortinet
adom: LSD-Customer26

regions:
  - name: OneRegion
    shortname: OL
    dc-id:
      - 240
      - 241
    hubs:
      - site-1-240
      - site-1-241
    edge:
      {% for M in range(242, 251) %}
      - site-1-{{ M }}
      {% endfor %}
EOF
