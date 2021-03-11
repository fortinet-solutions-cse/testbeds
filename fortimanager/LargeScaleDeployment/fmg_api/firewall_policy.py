#!/usr/bin/env python3

from fmg_api.api_base import ApiSession

class FirewallPolicyApi(ApiSession):

    ##############################################################
    # Add Normalized Interfaces
    ##############################################################
    def addNormalizedInterfaces(self, intf_list, suffix = "", color = 4):

        norm_intf_list = []

        for intf in intf_list:
            norm_intf_list.append(
                {
                    "name": intf,
                    "single-intf": 1,
                    "default-mapping": 1,
                    "defmap-intf": intf + suffix,
                    "color": color
                }
            )

        payload = {
            "session": self._session,
            "id": 1,
            "method": "set",
            "params": [
                {
                    "url": "/pm/config/adom/" + self.adom + "/obj/dynamic/interface/",
                    "data": norm_intf_list
                }
            ]
        }

        self._run_request(payload, name="Add Normalized Interfaces")


    ##############################################################
    # Add Address
    ##############################################################
    def addAddress(self, address_name, ip, mask, color = 22):

        payload = {
            "session": self._session,
            "id": 1,
            "method": "set",
            "params": [
                {
                    "url": "/pm/config/adom/" + self.adom + "/obj/firewall/address",
                    "data": [
                        {
                            "name": address_name,
                            "subnet": [
                                ip,
                                mask
                            ],
                            "type": 0,
                            "associated-interface": "any",
                            "color": color
                        }
                    ]
                }
            ]
        }

        self._run_request(payload, name=f"Add Address ({address_name})")


    ##############################################################
    # Create Firewall Policy Package
    ##############################################################
    def createFirewallPolicyPackage(self, package_name, target_group):

        payload = {
            "session": self._session,
            "id": 1,
            "method": "set",
            "params": [
                {
                    "url": "/pm/pkg/adom/" + self.adom,
                    "data": [
                        {
                            "name": package_name,
                            "package settings": {
                                "central-nat": 0,
                                "consolidated-firewall-mode": 0,
                                "fwpolicy-implicit-log": 0,
                                "fwpolicy6-implicit-log": 0,
                                "ngfw-mode": 0
                            },
                            "scope member": {
                                "name": target_group
                            },
                            "type": "pkg"
                        }
                    ]
                }
            ]
        }

        self._run_request(payload, name=f"Create Firewall Policy Package ({package_name})")

    ##############################################################
    # Set Hub Firewall Rules
    ##############################################################
    def setHubFirewallRules(self, package_name, multireg = False):

        corp_intf = [ "overlay", "port4" ]
        if multireg: corp_intf.append("hub2hub-overlay")

        rules_list = [
            {
                "name": "Corporate",
                "policyid": 1,
                "srcintf": corp_intf,
                "dstintf": corp_intf,
                "srcaddr": "CORP_LAN",
                "dstaddr": "CORP_LAN",
                "service": "ALL",
                "action": 1,
                "anti-replay": 0,
                "tcp-session-without-syn": 0,
                "utm-status": 1,
                "application-list": [
                    "default"
                ],
                "ssl-ssh-profile": [
                    "certificate-inspection"
                ],
                "profile-protocol-options": [],
                "status": 1,
                "schedule": "always",
                "logtraffic": 2
            },
            {
                "name": "Health-Check",
                "policyid": 2,
                "srcintf": [
                    "overlay"
                ],
                "dstintf": "any",
                "srcaddr": "all",
                "dstaddr": "HC",
                "service": "PING",
                "action": 1,
                "profile-protocol-options": [],
                "status": 1,
                "schedule": "always",
                "logtraffic": 3
            },
            {
                "name": "Internet (DIA)",
                "policyid": 3,
                "srcintf": [
                    "port1",
                    "port4"
                ],
                "dstintf": "underlay",
                "srcaddr": "all",
                "dstaddr": "all",
                "service": "ALL",
                "action": 1,
                "nat": 1,
                "utm-status": 1,
                "application-list": [
                    "default"
                ],
                "ssl-ssh-profile": [
                    "certificate-inspection"
                ],
                "profile-protocol-options": [],
                "status": 1,
                "schedule": "always",
                "logtraffic": 2
            },
            {
                "name": "Edge to Internet (RIA)",
                "policyid": 4,
                "srcintf": "overlay",
                "dstintf": "underlay",
                "srcaddr": "all",
                "dstaddr": "all",
                "service": "ALL",
                "action": 1,
                "nat": 1,
                "utm-status": 1,
                "application-list": [
                    "default"
                ],
                "ssl-ssh-profile": [
                    "certificate-inspection"
                ],
                "profile-protocol-options": [],
                "status": 1,
                "schedule": "always",
                "logtraffic": 2
            }
        ]

        if multireg:
            rules_list.append(
                {
                    "name": "XR-BGP",
                    "policyid": 5,
                    "srcintf": "hub2hub-overlay",
                    "dstintf": [
                        "lo-XR_T1",
                        "lo-XR_T2"
                    ],
                    "srcaddr": "all",
                    "dstaddr": "all",
                    "service": [
                        "BGP",
                        "PING"
                    ],
                    "action": 1,
                    "nat": 0,
                    "status": 1,
                    "schedule": "always",
                    "logtraffic": 2
                }
            )

        payload = {
            "session": self._session,
            "id": 1,
            "method": "set",
            "params": [
                {
                    "url": "/pm/config/adom/" + self.adom + "/pkg/" + package_name + "/firewall/policy/",
                    "data": rules_list
                }
            ]
        }

        self._run_request(payload, name="Set Hub Firewall Rules")


    ##############################################################
    # Set Edge Firewall Rules
    ##############################################################
    def setEdgeFirewallRules(self, package_name):

        payload = {
            "session": self._session,
            "id": 1,
            "method": "set",
            "params": [
                {
                    "url": "/pm/config/adom/" + self.adom + "/pkg/" + package_name + "/firewall/policy/",
                    "data": [
                        {
                            "name": "Corporate",
                            "policyid": 1,
                            "srcintf": [
                                "port4",
                                "overlay"
                            ],
                            "dstintf": [
                                "port4",
                                "overlay"
                            ],
                            "srcaddr": "CORP_LAN",
                            "dstaddr": "CORP_LAN",
                            "service": "ALL",
                            "action": 1,
                            "utm-status": 1,
                            "application-list": [
                                "default"
                            ],
                            "ssl-ssh-profile": [
                                "certificate-inspection"
                            ],
                            "profile-protocol-options": [],
                            "status": 1,
                            "schedule": "always",
                            "logtraffic": 2
                        },
                        {
                            "name": "Internet (DIA)",
                            "policyid": 2,
                            "srcintf": [
                                "port1",
                                "port4"
                            ],
                            "dstintf": "underlay",
                            "srcaddr": "all",
                            "dstaddr": "all",
                            "service": "ALL",
                            "action": 1,
                            "nat": 1,
                            "utm-status": 1,
                            "application-list": [
                                "default"
                            ],
                            "ssl-ssh-profile": [
                                "certificate-inspection"
                            ],
                            "profile-protocol-options": [],
                            "status": 1,
                            "schedule": "always",
                            "logtraffic": 2
                        },
                        {
                            "name": "Internet (RIA)",
                            "policyid": 3,
                            "srcintf": [
                                "port1",
                                "port4"
                            ],
                            "dstintf": "overlay",
                            "srcaddr": "all",
                            "dstaddr": "all",
                            "service": "ALL",
                            "action": 1,
                            "nat": 0,
                            "utm-status": 1,
                            "application-list": [
                                "default"
                            ],
                            "ssl-ssh-profile": [
                                "certificate-inspection"
                            ],
                            "profile-protocol-options": [],
                            "status": 1,
                            "schedule": "always",
                            "logtraffic": 2
                        }
                    ]
                }
            ]
        }

        self._run_request(payload, name="Set Edge Firewall Rules")
