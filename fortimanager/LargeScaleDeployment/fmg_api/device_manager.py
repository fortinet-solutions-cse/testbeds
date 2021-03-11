#!/usr/bin/env python3

from fmg_api.api_base import ApiSession

class DeviceManagerApi(ApiSession):

    ##############################################################
    # Get Devices
    ##############################################################
    def getDevices(self):

        dev_list = []

        payload = {
            "session": self._session,
            "id": 1,
            "method": "get",
            "params": [
                {
                    "url": "/dvmdb/adom/" + self.adom + "/device",
                }
            ]
        }

        content = self._run_request(payload, name="Get Devices")
        for dev in content["result"][0]["data"]:
            dev_list.append({ 'ip': dev['ip'], 'name': dev['name']})

        return dev_list


    ##############################################################
    # Add Devices
    ##############################################################
    def addDevices(self, user, password, dev_list):

        add_dev_list = []
        for dev in dev_list:
            add_dev_list.append({
                "adm_pass": password,
                "adm_usr": user,
                "ip": dev['ip'],
                "name": dev['name'],
                "mgmt_mode": "fmgfaz"
            })

        payload = {
            "session": self._session,
            "id": 1,
            "method": "exec",
            "params": [
                {
                    "url": "/dvm/cmd/add/dev-list",
                    "data": {
                        "adom": self.adom,
                        "flags": ["create_task", "nonblocking"],
                        "add-dev-list": add_dev_list
                    }
                }
            ]
        }

        self._run_request_async(payload, name="Add Devices")

    ##############################################################
    # Get Interfaces
    ##############################################################
    def getInterfaces(self, dev_name):

        intf_list = []

        payload = {
            "session": self._session,
            "id": 1,
            "method": "get",
            "params": [
                {
                    "url": "pm/config/device/" + dev_name + "/global/system/interface"
                }
            ]
        }

        content = self._run_request(payload, name=f"Get Interfaces ({dev_name})")
        for intf in content["result"][0]["data"]:
            intf_list.append(intf['name'])

        return intf_list


    ##############################################################
    # Get Zones
    ##############################################################
    def getZones(self, dev_name):

        zone_list = []

        payload = {
            "session": self._session,
            "id": 1,
            "method": "get",
            "params": [
                {
                    "url": "pm/config/device/" + dev_name + "/vdom/root/system/zone"
                }
            ]
        }

        content = self._run_request(payload, name=f"Get Zones ({dev_name})")
        for zone in content["result"][0]["data"]:
            zone_list.append({ 'name': zone['name'], 'intf_list': zone['interface']})

        return zone_list


    ##############################################################
    # Create Zone
    ##############################################################
    def createZone(self, dev_name, zone_name, intf_list):

        payload = {
            "session": self._session,
            "id": 1,
            "method": "set",
            "params": [
                {
                    "url": "pm/config/device/" + dev_name + "/vdom/root/system/zone",
                    "data": {
                        "name": zone_name,
                        "intrazone": 0,
                        "interface": intf_list
                    }
                }
            ]
        }

        self._run_request(payload, name=f"Create Zone {zone_name} on {dev_name}")


    ##############################################################
    # Set Device Attributes
    ##############################################################
    def setDeviceAttributes(self, dev_attr_list):

        set_dev_list = []
        for dev in dev_attr_list:
            set_dev_list.append({
                "name": dev['name'],
                "latitude": str(dev['location']['latitude']) if 'location' in dev else "",
                "longitude": str(dev['location']['longitude'] if 'location' in dev else ""),
                "meta fields": dev['attrs']
            })

        payload = {
            "session": self._session,
            "id": 1,
            "method": "set",
            "params": [
                {
                    "url": "/dvmdb/adom/" + self.adom + "/device",
                    "data": set_dev_list
                }
            ]
        }

        self._run_request(payload, name="Set Device Attributes")


    ##############################################################
    # Add CLI Template
    ##############################################################
    def addCLITemplate(self, template_name, content):

        payload = {
            "session": self._session,
            "id": 1,
            "method": "set",
            "params": [
                {
                    "url": "/pm/config/adom/" + self.adom + "/obj/cli/template",
                    "data": [
                        {
                            "name": template_name,
                            "script": content
                        }
                    ]
                }
            ]
        }

        self._run_request(payload, name=f"Add CLI Template ({template_name})")


    ##############################################################
    # Create CLI Template Group
    ##############################################################
    def createCLITemplateGroup(self, group_name):

        payload = {
            "session": self._session,
            "id": 1,
            "method": "set",
            "params": [
                {
                    "url": "/pm/config/adom/" + self.adom + "/obj/cli/template-group",
                    "data": {
                        "name": group_name
                    }
                }
            ]
        }

        self._run_request(payload, name=f"Create CLI Template Group ({group_name})")


    ##############################################################
    # Populate CLI Template Group
    ##############################################################
    def populateCLITemplateGroup(self, group_name, template_list):

        payload = {
            "session": self._session,
            "id": 1,
            "method": "set",
            "params": [
                {
                    "url": "/pm/config/adom/" + self.adom + "/obj/cli/template-group",
                    "data": {
                        "name": group_name,
                        "member": template_list
                    }
                }
            ]
        }

        self._run_request(payload, name=f"Populate CLI Template Group ({group_name})")


    ##############################################################
    # Assign CLI Template Group
    ##############################################################
    def assignCLITemplateGroup(self, group_name, dev_list):

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
                    "url": "/pm/config/adom/" + self.adom + "/obj/cli/template-group/" + group_name + "/scope member",
                    "data": assigned_dev_list
                }
            ]
        }

        self._run_request(payload, name=f"Assign CLI Template Group ({group_name})")


    ##############################################################
    # Create Device Group
    ##############################################################
    def createDeviceGroup(self, group_name):

        payload = {
            "session": self._session,
            "id": 1,
            "method": "set",
            "params": [
                {
                    "url": "/dvmdb/adom/" + self.adom + "/group",
                    "data": [
                        {
                            "name": group_name,
                            "os_type": "1"
                        }
                    ]
                }
            ]
        }

        self._run_request(payload, name=f"Create Device Group ({group_name})")


    ##############################################################
    # Add to Device Group
    ##############################################################
    def addToDeviceGroup(self, group_name, dev_list):

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
                    "url": "/dvmdb/adom/" + self.adom + "/group/" + group_name + "/object member",
                    "data": assigned_dev_list
                }
            ]
        }

        self._run_request(payload, name=f"Add to Device Group ({group_name})")


    ##############################################################
    # Install Policy
    ##############################################################
    def installPolicy(self, package_name, target_group):

        payload = {
            "session": self._session,
            "id": 1,
            "method": "exec",
            "params": [
                {
                    "url": "/securityconsole/install/package",
                    "data": {
                        "adom": self.adom,
                        "pkg": package_name,
                        "scope": [
                            {
                                "name": target_group
                            }
                        ],
                        "flags": "none"
                    }
                }
            ]
        }

        self._run_request_async(payload, name=f"Install Policy ({package_name})")


    ##############################################################
    # Install Configuration
    ##############################################################
    def installConfiguration(self, dev_name):

        payload = {
            "session": self._session,
            "id": 1,
            "method": "exec",
            "params": [
                {
                    "url": "/securityconsole/install/device",
                    "data": {
                        "adom": self.adom,
                        "scope": [
                            {
                                "name": dev_name,
                                "vdom": "root"
                            }
                        ],
                        "flags": "none"
                    }
                }
            ]
        }

        self._run_request_async(payload, name=f"Install Configuration on {dev_name}")
