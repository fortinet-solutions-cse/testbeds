#!/usr/bin/env python3

from fmg_api.api_base import ApiSession

class CliScriptApi(ApiSession):
    ##############################################################
    # Add CLI Script
    ##############################################################
    def addCliScript(self, cli_script, content):

        payload = {
            "session": self._session,
            "id": 1,
            "method": "set",
            "params": [
                {
                    "url": "/dvmdb/adom/" + self.adom + "/script",
                    "data": {
                        "type": "cli",
                        "target": "device_database",
                        "name": cli_script,
                        "content": content
                    }
                }
            ]
        }

        self._run_request(payload, name=f"Add CLI Script ({cli_script})")

    ##############################################################
    # Execute CLI Script
    ##############################################################
    def executeCliScript(self, cli_script, target, group = False):

        scope = { "name": target }
        if not group: scope["vdom"] = "root"

        payload = {
            "session": self._session,
            "id": 1,
            "method": "exec",
            "params": [
                {
                    "url": "/dvmdb/adom/" + self.adom + "/script/execute",
                    "data": {
                        "adom": self.adom,
                        "script": cli_script,
                        "scope": [ scope ]
                    }
                }
            ]
        }

        self._run_request_async(payload, name=f"Execute CLI Script ({cli_script})")
