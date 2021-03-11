#!/usr/bin/env python3

from fmg_api.adom import AdomApi
from fmg_api.firewall_policy import FirewallPolicyApi
from fmg_api.device_manager import DeviceManagerApi
from lsd_base import *

from os import scandir, path

def main():

    cfg = readConfig()

    session = AdomApi(
        url = cfg['fmg_api'],
        adom = cfg['adom'],
        user = cfg['fmg_user'],
        password = cfg['fmg_password']
    )

    session.addAdom(cfg['adom'])
    session.createMetaField('H')
    session.createMetaField('N')
    session.createMetaField('M')
    session.createMetaField('dc-id')
    session.createMetaField('pri-dc-id')
    session.createMetaField('sec-dc-id')
    session.createMetaField('region')

    session = FirewallPolicyApi(
        url = cfg['fmg_api'],
        adom = cfg['adom'],
        user = cfg['fmg_user'],
        password = cfg['fmg_password']
    )

    session.createFirewallPolicyPackage("default", "All_FortiGate")

    session = DeviceManagerApi(
        url = cfg['fmg_api'],
        adom = cfg['adom'],
        user = cfg['fmg_user'],
        password = cfg['fmg_password']
    )

    session.createDeviceGroup("Hubs")
    session.createDeviceGroup("Edge")
    session.createCLITemplateGroup("Hubs-Template")
    session.createCLITemplateGroup("Edge-Template")
    if (len(cfg['regions']) > 1):
        for region in cfg['regions']:
            session.createDeviceGroup(f"Hubs-{region['name']}")
            session.createDeviceGroup(f"Edge-{region['name']}")
            if 'edge-template' in region: session.createCLITemplateGroup(region['edge-template'])
            if 'hub-template' in region: session.createCLITemplateGroup(region['hub-template'])

    hubs_template = []
    edge_template = []
    for e in sorted(scandir("tenants/" + cfg['adom'] + "/cli_templates"), key=lambda e: e.name):
        with open(e.path, 'r') as f:
            session.addCLITemplate(path.splitext(e.name)[0], f.read())
            # Prepare list of CLI Templates for each group
            if 'Edge' in e.name:
                edge_template.append(path.splitext(e.name)[0])
            elif 'Hubs' in e.name:
                hubs_template.append(path.splitext(e.name)[0])
            else:
                edge_template.append(path.splitext(e.name)[0])
                hubs_template.append(path.splitext(e.name)[0])

    if 'quiet' in cfg or is_good_to_go("Shall we re-populate CLI Template Groups? "):
        session.populateCLITemplateGroup("Hubs-Template", hubs_template)
        session.populateCLITemplateGroup("Edge-Template", edge_template)

if __name__ == "__main__":
    main()
