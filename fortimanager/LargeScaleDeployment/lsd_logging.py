#!/usr/bin/env python3

from fmg_api.adom import AdomApi
from fmg_api.device_manager import DeviceManagerApi
from lsd_base import *

def main():

    cfg = readConfig()

    if 'quiet' in cfg or is_good_to_go("Shall we reapply system template for FAZ? "):
        session = DeviceManagerApi(
            url = cfg['fmg_api'],
            adom = cfg['adom'],
            user = cfg['fmg_user'],
            password = cfg['fmg_password']
        )

        managed_dev_list = session.getDevices()

        session.addProvisioningTemplate(
            template_name = "lsd-template",
            faz_ip = cfg['faz_ip'],
            faz_sn = cfg['faz_sn']
        )

        session.assignProvisioningTemplate("lsd-template", [ d['name'] for d in managed_dev_list ] )
        session.installConfiguration(
            dev_list = [ d['name'] for d in managed_dev_list ],
            vdom_global = True
        )

    session = AdomApi(
        url = cfg['faz_api'],
        adom = cfg['adom'],
        user = cfg['faz_user'],
        password = cfg['faz_password']
    )

    session.addAdom(cfg['adom'])

    session = DeviceManagerApi(
        url = cfg['faz_api'],
        adom = cfg['adom'],
        user = cfg['faz_user'],
        password = cfg['faz_password']
    )

    dev_list = []
    for region in cfg['regions']:
        for dev in region['hubs'] + region['edge']:
            dev_list.append(dev)

    session.authorizeDevices(dev_list)

if __name__ == "__main__":
    main()
