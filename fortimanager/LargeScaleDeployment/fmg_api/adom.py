#!/usr/bin/env python3

from fmg_api.api_base import ApiSession

class AdomApi(ApiSession):

    ##############################################################
    # Add ADOM
    ##############################################################
    def addAdom(self, adom_name):

        payload = {
            "session": self._session,
            "id": 1,
            "method": "set",
            "params": [
                {
                    "url": "/dvmdb/adom",
                    "data": [
                        {
                            "name": adom_name,
                            "state": 1,
                            "mode": 1,
                            "os_ver": 6,
                            "mr": 4,
                            "flags": 68864,
                            "mig_os_ver": 0,
                            "mig_mr": 0,
                            "obj_customize": "",
                            "tab_status": "",
                            "logview_customize": "",
                            "restricted_prds": 1,
                            "log_db_retention_hours": 1440,
                            "log_file_retention_hours": 8760,
                            "log_disk_quota": 0,
                            "log_disk_quota_split_ratio": 70,
                            "log_disk_quota_alert_thres": 90,
                            "workspace_mode": 0
                        }
                    ]
                }
            ]
        }

        self._run_request(payload, name="Add ADOM")

    ##############################################################
    # Create Meta Field
    ##############################################################
    def createMetaField(self, var):

        payload = {
            "session": self._session,
            "id": 1,
            "method": "set",
            "params": [
                {
                    "url": "/dvmdb/adom/" + self.adom + "/_meta_fields/device",
                    "data": [
                        {
                            "importance": 0,
                            "length": 20,
                            "name": var,
                            "status": 1
                        }
                    ]
                }
            ]
        }

        self._run_request(payload, name="Create Meta Field " + var)
