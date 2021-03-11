#!/usr/bin/env python3

from fmg_api.device_manager import DeviceManagerApi
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

    session.addCliScript(
        cli_script = "EnableTcpWithoutSyn",
        content = "config system settings\n   set tcp-session-without-syn enable\nend"
    )
    session.executeCliScript("EnableTcpWithoutSyn", "Hubs", group=True)

    session = DeviceManagerApi(
        url = cfg['fmg_api'],
        adom = cfg['adom'],
        user = cfg['fmg_user'],
        password = cfg['fmg_password']
    )

    session.installPolicy("Hubs-Policy", "Hubs")
    session.installPolicy("Edge-Policy", "Edge")


if __name__ == "__main__":
    main()
