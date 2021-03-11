#!/usr/bin/env python3

from fmg_api.device_manager import DeviceManagerApi
from fmg_api.vpn_manager import VpnManagerApi
from lsd_base import *

def main():

    cfg = readConfig()

    dev_session = DeviceManagerApi(
        url = cfg['fmg_api'],
        adom = cfg['adom'],
        user = cfg['fmg_user'],
        password = cfg['fmg_password']
    )

    session = VpnManagerApi(
        url = cfg['fmg_api'],
        adom = cfg['adom'],
        user = cfg['fmg_user'],
        password = cfg['fmg_password']
    )

    overlay_list = session.getOverlays()

    for region in cfg['regions']:
        for i, hub in enumerate(region['hubs']):
            overlay_intfs = []
            edge_group_name = f"Edge-{region['name']}" if len(cfg['regions']) > 1 else "Edge"
            print("     Hub = " + hub + ", Edge Group = " + edge_group_name)
            for t in [1, 2]:
                overlay_name = region['shortname'] + "_H" + str(i+1) + "T" + str(t) + "V1"
                overlay_intfs.append(overlay_name + "_0")
                if overlay_name not in overlay_list:
                    print("     Adding " + overlay_name)
                    session.addOverlay(
                        overlay_name = overlay_name,
                        hub_name = hub,
                        spoke_group = edge_group_name,
                        wan_intf = "port" + str(t+1),
                        network_id = str(i+1) + str(t) + "1"
                    )
                else:
                    print("     Updating " + overlay_name)
                    session.updateOverlay(
                        overlay_name = overlay_name,
                        network_id = str(i+1) + str(t) + "1"
                    )
                    if hub not in overlay_list[overlay_name]:
                        session.addVpnHub(
                            community_name = overlay_name,
                            hub_name = hub,
                            wan_intf = "port" + str(t+1)
                        )
                    if edge_group_name not in overlay_list[overlay_name]:
                        session.addVpnSpokeGroup(
                            community_name = overlay_name,
                            spoke_group = edge_group_name,
                            wan_intf = "port" + str(t+1)
                        )

            # Create interface zones on Hubs (SD-WAN will take care of zones on Edge)
            if not set(overlay_intfs).issubset(set(dev_session.getInterfaces(hub))):
                dev_session.installPolicy("default", "Hubs")
            dev_session.createZone(
                dev_name = hub,
                zone_name = "underlay",
                intf_list = [ "port2", "port3" ]
            )
            dev_session.createZone(
                dev_name = hub,
                zone_name = "overlay",
                intf_list = overlay_intfs
            )


if __name__ == "__main__":
    main()
