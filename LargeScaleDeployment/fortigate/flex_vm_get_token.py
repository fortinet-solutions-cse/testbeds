#!/usr/bin/python3

from flex_vm_session import FlexVMSession
from flex_vm_credentials import username, password
from sys import argv

fvs = FlexVMSession(username, password)
fvs.update_bearer_token()


vms = fvs.get_vms_licenses(257)
for vm in vms:
    if vm['description'] == argv[1]:
        print(fvs.regenerate_token(vm['serialNumber']))

