#!/usr/bin/env python3

from fmg_api.sdwan import SdWanApi
from fmg_api.device_manager import DeviceManagerApi
from fmg_api.firewall_policy import FirewallPolicyApi
from lsd_base import *

def main():

    cfg = readConfig()

    dev_session = DeviceManagerApi(
        url = cfg['fmg_api'],
        adom = cfg['adom'],
        user = cfg['fmg_user'],
        password = cfg['fmg_password']
    )

    managed_dev_list = [ dev['name'] for dev in dev_session.getDevices() ]

    fw_session = FirewallPolicyApi(
        url = cfg['fmg_api'],
        adom = cfg['adom'],
        user = cfg['fmg_user'],
        password = cfg['fmg_password']
    )

    session = SdWanApi(
        url = cfg['fmg_api'],
        adom = cfg['adom'],
        user = cfg['fmg_user'],
        password = cfg['fmg_password']
    )

    for region in cfg['regions']:
        print("     Processing " + region['name'])
        overlay_list = []
        for i, hub in enumerate(region['hubs']):
            for t in [1, 2]:
                overlay_list.append(region['shortname'] + "_H" + str(i+1) + "T" + str(t) + "V1")

        fw_session.addAddress("CORP_LAN", "10.0.0.0", "255.0.0.0")
        fw_session.addAddress("HC", "10.200.99.1", "255.255.255.255")
        fw_session.addNormalizedInterfaces(overlay_list, suffix = "_0")
        session.addSdWanMembers(["port2", "port3"] + overlay_list)
        session.addSdWanHealthCheck("DC", "10.200.99.1")
        session.addSdWanHealthCheck("Internet", "www.fortinet.com")

        tempalte_name = "Edge-" + region['name'] if len(cfg['regions']) > 1 else "Edge"
        session.addSdWanTemplate(tempalte_name)
        session.populateSdWanTemplate(tempalte_name, overlay_list)

        managed_edge_list = [ dev for dev in region['edge'] if dev in managed_dev_list ]
        session.assignSdWanTemplate(tempalte_name, managed_edge_list)

    if len(cfg['regions']) > 1:
        fw_session.addNormalizedInterfaces(["lo-XR_T1", "lo-XR_T2"])

    if 'quiet' in cfg or is_good_to_go("Shall we reconfigure firewall policies? "):
        fw_session.createFirewallPolicyPackage("Edge-Policy", "Edge")
        fw_session.createFirewallPolicyPackage("Hubs-Policy", "Hubs")
        fw_session.setHubFirewallRules("Hubs-Policy", multireg = len(cfg['regions']) > 1)
        fw_session.setEdgeFirewallRules("Edge-Policy")


if __name__ == "__main__":
    main()
