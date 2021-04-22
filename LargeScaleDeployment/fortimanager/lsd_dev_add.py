#!/usr/bin/env python3

from fmg_api.device_manager import DeviceManagerApi
from fmg_api.sdwan import SdWanApi
from lsd_base import *

def main():

    cfg = readConfig()

    session = DeviceManagerApi(
        url = cfg['fmg_api'],
        adom = cfg['adom'],
        user = cfg['fmg_user'],
        password = cfg['fmg_password']
    )

    dev_list = []
    for region in cfg['regions']:
        for dev in region['hubs'] + region['edge']:
            dev_list.append(
                {
                    "name": dev,
                    "ip": "172.18." + dev.split('-')[1] + "." + dev.split('-')[2]
                }
            )

    managed_dev_list = session.getDevices()
    print("    Total Devices: " + str(len(dev_list)))
    print("    Currently Managed Devices: " + str(len(managed_dev_list)))

    dev_list = [ dev for dev in dev_list if dev not in managed_dev_list ]
    print("    Devices to Add: " + str(len(dev_list)))

    if 'quiet' in cfg or is_good_to_go("Shall we add devices to FMG? "):
        session.addDevices(cfg['fgt_user'], cfg['fgt_password'], dev_list)

    if 'quiet' in cfg or is_good_to_go("Shall we set device attributes? "):

        sdwan_session = SdWanApi(
            url = cfg['fmg_api'],
            adom = cfg['adom'],
            user = cfg['fmg_user'],
            password = cfg['fmg_password']
        )

        managed_dev_list = session.getDevices()

        dc_id = 0
        dev_attr_list = []
        for region in cfg['regions']:
            print("    Processing " + region['name'])

            managed_hubs = [ d['name'] for d in managed_dev_list if d['name'] in region['hubs'] ]

            group_name = f"Hubs-{region['name']}" if len(cfg['regions']) > 1 else "Hubs"
            session.createDeviceGroup(group_name)
            session.addToDeviceGroup(group_name, managed_hubs)

            template_name = region['hub-template'] if 'hub-template' in region else "Hubs-Template"
            session.createCLITemplateGroup(template_name)
            session.assignCLITemplateGroup(template_name, managed_hubs)
            for i, hub in enumerate(region['hubs']):
                if 'dc-id' not in region: dc_id += 1
                if hub in [ d['name'] for d in managed_dev_list ]:
                    dev_attr_list.append(
                        {
                            "name": hub,
                            "attrs": {
                                "N": hub.split('-')[1],
                                "M": hub.split('-')[2],
                                "H": str(i+1),
                                "dc-id": str(region['dc-id'][i]) if 'dc-id' in region else str(dc_id),
                                "region": region['shortname']
                            }
                        }
                    )

            managed_edge = [ d['name'] for d in managed_dev_list if d['name'] in region['edge'] ]

            group_name = f"Edge-{region['name']}" if len(cfg['regions']) > 1 else "Edge"
            session.createDeviceGroup(group_name)
            session.addToDeviceGroup(group_name, managed_edge)

            template_name = region['edge-template'] if 'edge-template' in region else "Edge-Template"
            session.createCLITemplateGroup(template_name)
            session.assignCLITemplateGroup(template_name, managed_edge)

            try:
                sdwan_session.assignSdWanTemplate(group_name, managed_edge)
            except:
                pass

            for i, edge in enumerate(region['edge']):
                if edge in [ e['name'] for e in managed_dev_list ]:
                    dev_attr_list.append(
                        {
                            "name": edge,
                            "attrs": {
                                "N": edge.split('-')[1],
                                "M": edge.split('-')[2],
                                "pri-dc-id": str(region['dc-id'][0]) if 'dc-id' in region else str(dc_id-1),
                                "sec-dc-id": str(region['dc-id'][1]) if 'dc-id' in region and len(region['dc-id']) > 1 else str(dc_id),
                                "region": region['shortname']
                            },
                            "location": {
                                "latitude": str(region['edge-geo'][i][0]) if 'edge-geo' in region else "",
                                "longitude": str(region['edge-geo'][i][1]) if 'edge-geo' in region else "",
                            }
                        }
                    )

        session.setDeviceAttributes(dev_attr_list)


if __name__ == "__main__":
    main()
