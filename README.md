# testbeds
This project hosts multiple test beds in different environments for Fortinet products.

It uses libvirt and kvm as the hypervisor technology. All cases are intended to run on an standard laptop, unless stated otherwise.

Select the proper folder according to the product you want to run and then choose the proper script.

Usually at the header of each script there is a ascii picture describing the setup used. E.g.

fortigate/start_fgt_VWP.sh shows:

```
                 MGMT
                   +
                   |
 +----------+   +--+--+   +----------+
 |          |   |     |   |          |
 |  Ubuntu  +---+ FGT +---+  Ubuntu  |
 |          |   |     |   |          |
 +----------+   +-----+   +----------+

```

Before running any example please install proper software by running:

```
./installation.sh
```
