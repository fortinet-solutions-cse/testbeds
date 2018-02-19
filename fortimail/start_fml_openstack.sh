#!/usr/bin/env bash
#!/bin/bash
#************************************************
#
# Use this example to start a FortiMail VM in Openstack
# This has support for cloud init
#
# Miguel Angel Muñoz <magonzalez at fortinet.com>
#
# ************************************************

cat >cfg-drv-fgt/openstack/latest/user_data <<EOF
EOF

cat >cfg-drv-fgt/openstack/latest/meta_data.json <<EOF
{
    "files": [
        {"path": "mode", "content_path": "/content/0000"},
        {"path": "config", "content_path": "/content/0001"},
        {"path": "license", "content_path": "/content/0002"}
    ]
}
EOF

cat >mode <<EOF
config system global
  set operation-mode server
end
EOF

cat >config <<EOF
config system interface
  edit "port1"
    set ip 192.168.122.50/24
    set allowaccess ping ssh snmp http https telnet
  next
end
config system global
   set rest-api enable
end
config system global
   set pki-mode enable
end
config system route
  edit 1
    set gateway 192.168.122.1
  next
end
config system dns
    set primary 8.8.8.8
    set secondary 8.8.4.4
end
EOF

cat >license <<EOF
-----BEGIN FE VM LICENSE-----
Put your license here
-----END FE VM LICENSE-----
EOF

#Deploy FortiMail in openstack: Note mode, config and license files (take examples from above)
openstack server create --image "fortimail" --key-name t1 --flavor fortimail-flv \
 --nic net-id=mgmt  --block-device-mapping sdb=t1 --block-device-mapping sdc=t2  \
 --file mode=./mode --file config=./config --file license=./license   --config-drive True FortiMailVM