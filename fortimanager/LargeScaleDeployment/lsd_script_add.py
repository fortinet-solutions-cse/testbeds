#!/usr/bin/env python3

from fmg_api.cli_script import CliScriptApi
from lsd_base import *

def main():

    cfg = readConfig()

    session = CliScriptApi(
        url = cfg['fmg_api'],
        adom = cfg['adom'],
        user = cfg['fmg_user'],
        password = cfg['fmg_password']
    )

    tenantdir = "tenants/" + environ.get("LSD_TENANT") + "/"

    for region in cfg['regions']:
        for i in [1, 2]:
            script_name = "XR-" + region['name'] + "-H" + str(i)
            print("     Adding CLI Script " + script_name)
            with open(tenantdir + "/cli_scripts/" + script_name + ".conf", 'r') as f:
                session.addCliScript(script_name, f.read())

    for region in cfg['regions']:
        for i in [1, 2]:
            script_name = "XR-" + region['name'] + "-H" + str(i)
            print("     Executing CLI Script " + script_name)
            session.executeCliScript(script_name, region['hubs'][i-1])


if __name__ == "__main__":
    main()
