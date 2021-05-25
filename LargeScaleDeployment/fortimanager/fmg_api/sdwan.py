#!/usr/bin/env python3

from fmg_api.api_base import ApiSession

class SdWanApi(ApiSession):

    ##############################################################
    # Add SD-WAN Members
    ##############################################################
    def addSdWanMembers(self, overlay_list):

        member_list = []

        for overlay in overlay_list:
            member_list.append(
                {
                    "name": overlay,
                    "interface": overlay,
                    "cost": 0,
                    "weight": 1,
                    "priority": 10,
                    "status": 1
                }
            )

        payload = {
            "session": self._session,
            "id": 1,
            "method": "set",
            "params": [
                {
                    "url": "/pm/config/adom/" + self.adom + "/obj/dynamic/virtual-wan-link/members",
                    "data": member_list
                }
            ]
        }

        self._run_request(payload, name="Add SD-WAN Members")


    ##############################################################
    # Add SD-WAN Health Check
    ##############################################################
    def addSdWanHealthCheck(self, name, ip):

        payload = {
            "session": self._session,
            "id": 1,
            "method": "set",
            "params": [
                {
                    "url": "/pm/config/adom/" + self.adom + "/obj/dynamic/virtual-wan-link/server",
                    "data": {
                        "name": name,
                        "server": [ ip ]
                    }
                }
            ]
        }

        self._run_request(payload, name=f"Add SD-WAN Health Check ({name})")


    ##############################################################
    # Add SD-WAN Template
    ##############################################################
    def addSdWanTemplate(self, template_name):

        payload = {
            "session": self._session,
            "id": 1,
            "method": "set",
            "params": [
                {
                    "url": "/pm/wanprof/adom/" + self.adom,
                    "data": {
                        "name": template_name,
                        "type": "wanprof"
                    }
                }
            ]
        }

        self._run_request(payload, name=f"Add SD-WAN Template ({template_name})")


    ##############################################################
    # Populate SD-WAN Template
    ##############################################################
    def populateSdWanTemplate(self, template_name, overlay_list):

        overlay_members = []
        overlay_members.append(
            {
                "_dynamic-member": "port2",
                "zone": "underlay"
            }
        )
        overlay_members.append(
            {
                "_dynamic-member": "port3",
                "zone": "underlay"
            }
        )
        for overlay in overlay_list:
            overlay_members.append(
                {
                    "_dynamic-member": overlay,
                    "zone": "overlay"
                }
            )

        service_list = []
        for i, x in enumerate(range(3, len(overlay_list)+3, 2)):
            service_list.append(
                    {
                        "id": i+1,
                        "name": f"Corporate-H{i+1}",
                        "src": "CORP_LAN",
                        "dst": "CORP_LAN",
                        "dst-negate": 0,
                        "protocol": 0,
                        "role": 3,
                        "mode": 4,
                        "sla": [
                            {
                                "health-check": "DC",
                                "id": 1
                            }
                        ],
                        "priority-members": [
                            str(x),
                            str(x+1)
                        ],
                        "route-tag": 0,
                        "gateway": 0,
                        "groups": [],
                        "addr-mode": 7,
                        "default": 0,
                        "hold-down-time": 0,
                        "input-device": [],
                        "internet-service": 0,
                        "link-cost-threshold": 10,
                        "sla-compare-method": 0,
                        "src-negate": 0,
                        "standalone-action": 0,
                        "status": 1
                    }
            )

        service_list.append(
            {
                "id": 3,
                "name": "Internet-DIA",
                "src": [],
                "dst": "all",
                "internet-service": 0,
                "dst-negate": 0,
                "protocol": 0,
                "role": 3,
                "mode": 5,
                "sla": [
                    {
                        "health-check": "Internet",
                        "id": 1
                    }
                ],
                "priority-members": [
                    "1",
                    "2"
                ],
                "route-tag": 0,
                "gateway": 0,
                "groups": [],
                "addr-mode": 7,
                "default": 0,
                "hold-down-time": 0,
                "input-device": [],
                "link-cost-threshold": 10,
                "sla-compare-method": 0,
                "src-negate": 0,
                "standalone-action": 0,
                "status": 1
            }
        )

        payload = {
            "session": self._session,
            "id": 1,
            "method": "replace",
            "params": [
                {
                    "url": "/pm/config/adom/" + self.adom + "/wanprof/" + template_name + "/system/sdwan",
                    "data": {
                        "status": 1,
                        "load-balance-mode": 1,
                        "fail-detect": "disable",
                        "zone": [
                            {
                                "name": "virtual-wan-link"
                            },
                            {
                                "name": "underlay"
                            },
                            {
                                "name": "overlay"
                            }
                        ],
                        "members": overlay_members,
                        "health-check": [
                            {
                                "name": "DC",
                                "_dynamic-server": [
                                    "DC"
                                ],
                                "protocol": 1,
                                "members": [ *range(3, len(overlay_list)+3) ],
                                "sla-fail-log-period": 30,
                                "sla-pass-log-period": 60,
                                "failtime": 5,
                                "recoverytime": 5,
                                "update-cascade-interface": 1,
                                "update-static-route": 1,
                                "sla": [
                                    {
                                        "id": 1,
                                        "latency-threshold": 100,
                                        "link-cost-factor": 1
                                    }
                                ]
                            },
                            {
                                "name": "Internet",
                                "_dynamic-server": [
                                    "Internet"
                                ],
                                "protocol": 1,
                                "members": [
                                    1,
                                    2
                                ],
                                "sla-fail-log-period": 30,
                                "sla-pass-log-period": 60,
                                "failtime": 5,
                                "recoverytime": 5,
                                "update-cascade-interface": 1,
                                "update-static-route": 1,
                                "sla": [
                                    {
                                        "id": 1,
                                        "latency-threshold": 200,
                                        "link-cost-factor": 1
                                    },
                                    {
                                        "id": 2,
                                        "latency-threshold": 300,
                                        "link-cost-factor": 1
                                    }
                                ]
                            }
                        ],
                        "service": service_list
                    }
                }
            ]
        }

        self._run_request(payload, name=f"Populate SD-WAN Template ({template_name})")


    ##############################################################
    # Assign SD-WAN Template
    ##############################################################
    def assignSdWanTemplate(self, template_name, dev_list):

        assigned_dev_list = []
        for dev in dev_list:
            assigned_dev_list.append(
                {
                    "name": dev,
                    "vdom": "root"
                }
            )

        payload = {
            "session": self._session,
            "id": 1,
            "method": "add",
            "params": [
                {
                    "url": "/pm/wanprof/adom/" + self.adom + "/" + template_name + "/scope member",
                    "data": assigned_dev_list
                }
            ]
        }

        self._run_request(payload, name=f"Assign SD-WAN Template ({template_name})")
