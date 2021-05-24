#!/usr/bin/python3

from flex_vm_session import FlexVMSession
from flex_vm_credentials import username, password
from sys import argv


## IMPORTANT: This short file regenerates the token for a
# single VM on FlexVM program. It is intended to run inside
# bash scripting. TODO: Error handling

# Params: it receives a single args: site-N-M where N and M indicates the numbering of your site
#         e.g.   flex_vm_get_token.py site-1-25
#
# Return: It returns the new token generated if there is no error.


fvs = FlexVMSession(username, password)
fvs.update_bearer_token()


vms = fvs.get_vms_licenses(257)
for vm in vms:
    if vm['description'] == argv[1]:
        print(fvs.regenerate_token(vm['serialNumber']))

