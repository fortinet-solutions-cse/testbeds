#!/usr/bin/python3

import requests
import json
import urllib3
import base64
import os 
import sys

TIMEOUT=5
LICENSE_FILE_PREFIX="FGVM08TM"
LICENSE_INIT=90001234  #Suffix of the license file to start with. Licenses should be placed in ./licenses
NUMBER_OF_FGT=250 

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


headers = {"Content-Type": "application/x-www-form-urlencoded"}


for i in range(0, NUMBER_OF_FGT):
  try:
    print("Number: " + str(i))
    ## Login
    results_login = requests.post("http://192.168.122." + str(2+i) + "/logincheck",
                                          data='username=admin&secretkey=password&ajax=1',
                                          verify=False,
                                          headers=headers,
                                          timeout=TIMEOUT)

    print(results_login.status_code)
    print(results_login.content)
    print(results_login.text)

    xsrfToken = results_login.cookies['ccsrftoken']
    jar = results_login.cookies


    ## Upload license
    counter = LICENSE_INIT + i
    dir_path = os.path.dirname(os.path.realpath(__file__))

    print("License File: " + '/licenses/' + LICENSE_FILE_PREFIX + str(counter) + '.lic')

    license_content = open(dir_path + '/licenses/' + LICENSE_FILE_PREFIX + str(counter) + '.lic', '+rb').read()
    license_encoded = base64.b64encode(license_content)

    body = {
      "file_content": license_encoded.decode('utf-8')
    }

    headers = {"Content-Type": "x-www-form-urlencoded",
                "x-csrftoken": xsrfToken.strip('"')}

    results_upload_license = requests.post("http://192.168.122." + str(2+i) + '/api/v2/monitor/system/vmlicense/upload',
                                          data=json.dumps(body),
                                          verify=False,
                                          headers=headers,
                                          cookies=jar,
                                          timeout=TIMEOUT)


    print(results_upload_license)
    print(results_upload_license.status_code)
    print(results_upload_license.content)
    print(results_upload_license.text)

  except:
    print("Exception")
    print("Unexpected error:", sys.exc_info()[0])   

