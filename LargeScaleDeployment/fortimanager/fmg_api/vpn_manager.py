#!/usr/bin/env python3

from fmg_api.api_base import ApiSession

class VpnManagerApi(ApiSession):

    ##############################################################
    # Add Overlay
    ##############################################################
    def addOverlay(self, overlay_name, hub_name, spoke_group, wan_intf, network_id):
        self.addVpnCommunity(overlay_name, network_id)
        self.addVpnHub(overlay_name, hub_name, wan_intf)
        self.addVpnSpokeGroup(overlay_name, spoke_group, wan_intf)

    ##############################################################
    # Update Overlay
    ##############################################################
    def updateOverlay(self, overlay_name, network_id):
        self.addVpnCommunity(overlay_name, network_id, update=True)

    ##############################################################
    # Get Overlays
    ##############################################################
    def getOverlays(self):

        overlay_list = {}

        payload = {
            "session": self._session,
            "id": 1,
            "method": "get",
            "params": [
                {
                    "url": "/pm/config/adom/" + self.adom + "/obj/vpnmgr/node",
                    "option": [ "scope member" ]
                }
            ]
        }

        content = self._run_request(payload, name="Get VPN Nodes")
        for node in content["result"][0]["data"]:
            community = node["vpntable"][0]
            if community not in overlay_list: overlay_list[community] = []
            overlay_list[community].append(node["scope member"][0]["name"])

        return overlay_list


    ##############################################################
    # Add VPN Community
    ##############################################################
    def addVpnCommunity(self, community_name, network_id, update=False):

        payload = {
            "session": self._session,
            "id": 1,
            "method": "set" if not update else "update",
            "params": [
                {
                    "url": "/pm/config/adom/" + self.adom + "/obj/vpnmgr/vpntable",
                    "data": {
                        "name": community_name,
                        "topology": 2,
                        "psk-auto-generate": 1,
                        "ike1keylifesec": 28800,
                        "ike1dpd": 1,
                        "ike1natkeepalive": 10,
                        "dpd": 3,
                        "dpd-retrycount": 3,
                        "dpd-retryinterval": 10,
                        "ike2keylifesec": 3600,
                        "ike2keylifekbs": 5120,
                        "ike2keepalive": 1,
                        "intf-mode": 0,
                        "fcc-enforcement": 0,
                        "ike-version": 2,
                        "negotiate-timeout": 30,
                        "inter-vdom": 0,
                        "auto-zone-policy": 0,
                        "npu-offload": 1,
                        "authmethod": 1,
                        "ike1dhgroup": 12,
                        "localid-type": 0,
                        "ike1mode": 1,
                        "ike1nattraversal": 1,
                        "ike1proposal": [
                            "aes256gcm-prfsha256"
                        ],
                        "ike2autonego": 0,
                        "ike2dhgroup": 12,
                        "ike2keylifetype": 1,
                        "pfs": 1,
                        "ike2proposal": [
                            "aes256gcm"
                        ],
                        "replay": 1,
                        "network-overlay": 1,
                        "network-id": network_id
                    }
                }
            ]
        }

        self._run_request(payload, name=f"Add VPN Community ({community_name})")


    ##############################################################
    # Add VPN Hub
    ##############################################################
    def addVpnHub(self, community_name, hub_name, wan_intf):

        payload = {
            "session": self._session,
            "id": 1,
            "method": "set",
            "params": [
                {
                    "url": "/pm/config/adom/" + self.adom + "/obj/vpnmgr/node",
                    "data": [
                        {
                            "protected_subnet": {
                                "addr": "all",
                                "seq": 1
                            },
                            "scope member": {
                                "name": hub_name,
                                "vdom": "root"
                            },
                            "vpntable": community_name,
                            "role": 0,
                            "iface": wan_intf,
                            "automatic_routing": 0,
                            "mode-cfg": 0,
                            "net-device": 0,
                            "tunnel-search": 1,
                            "add-route": 0,
                            "peertype": 1,
                            "auto-configuration": 0
                        }
                    ]
                }
            ]
        }

        self._run_request(payload, name=f"Add VPN Hub {hub_name} to {community_name}")

    ##############################################################
    # Add VPN Spoke Group
    ##############################################################
    def addVpnSpokeGroup(self, community_name, spoke_group, wan_intf):

        payload = {
            "session": self._session,
            "id": 1,
            "method": "set",
            "params": [
                {
                    "url": "/pm/config/adom/" + self.adom + "/obj/vpnmgr/node",
                    "data": [
                        {
                            "protected_subnet": {
                                "addr": "all",
                                "seq": 1
                            },
                            "scope member": {
                                "name": spoke_group
                            },
                            "vpntable": community_name,
                            "role": 1,
                            "iface": wan_intf,
                            "automatic_routing": 0,
                            "add-route": 0,
                            "mode-cfg": 0,
                            "assign-ip": 0,
                            "net-device": 1,
                            "peertype": 8
                        }
                    ]
                }
            ]
        }

        self._run_request(payload, name=f"Add VPN Spoke Group {spoke_group} to {community_name}")


    ##############################################################
    # Delete VPN Community
    ##############################################################
    def deleteVpnCommunity(self, community_name):

        payload = {
            "session": self._session,
            "id": 1,
            "method": "delete",
            "params": [
                {
                    "url": "/pm/config/adom/" + self.adom + "/obj/vpnmgr/vpntable/" + community_name
                }
            ]
        }

        self._run_request(payload, name=f"Delete VPN Community {community_name}")
