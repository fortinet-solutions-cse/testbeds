#!/usr/bin/env python3

from fmg_api.adom import AdomApi
from fmg_api.device_manager import DeviceManagerApi
from lsd_base import *

from os import scandir, path

def main():

    cfg = readConfig()

    session = DeviceManagerApi(
        url = cfg['fmg_api'],
        adom = cfg['adom'],
        user = cfg['fmg_user'],
        password = cfg['fmg_password']
    )

    session.deleteDevices(session.getDevices())

    session = AdomApi(
        url = cfg['fmg_api'],
        adom = cfg['adom'],
        user = cfg['fmg_user'],
        password = cfg['fmg_password']
    )

    session.deleteAdom()

    session = DeviceManagerApi(
        url = cfg['faz_api'],
        adom = cfg['adom'],
        user = cfg['faz_user'],
        password = cfg['faz_password']
    )

    session.deleteDevices(session.getDevices())

    session = AdomApi(
        url = cfg['faz_api'],
        adom = cfg['adom'],
        user = cfg['faz_user'],
        password = cfg['faz_password']
    )

    session.deleteAdom()


if __name__ == "__main__":
    main()
