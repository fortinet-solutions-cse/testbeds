#!/usr/bin/python3

import requests
import json
import collections

bearer = 'add_your_bearer_here'

# Create new licenses for VMs
# Parameters:
#  configId: The configuration id indicating the type of license. E.g. 4 cpu and 360.
#  count: number of licenses to be created. Maximum is 30.
#  description: self-descriptive
#  endDate: End date for the license. None for last date of the program.
#
def create_vm_license(configId, count, description, endDate):
    url = "https://support.fortinet.com/ES/api/flexvm/v1/vms/create"

    payload = json.dumps({
      "configId": configId,
      "count": count,
      "description": description, 
      "endDate": endDate
    })
    headers = {
      'Authorization': 'Bearer ' + bearer,
      'Content-Type': 'application/json'
    }
    response = requests.request("POST", url, headers=headers, data=payload)
    print(response.text)


# Update an existing license
# Params: Refer to 'create_vm_license'
#
def update_vm_license(serialNumber, configId, description, endDate):
  url = "https://support.fortinet.com/ES/api/flexvm/v1/vms/update"

  payload = json.dumps({
    "serialNumber": serialNumber,
    "configId": configId,
    "description": description,
    "endDate": endDate
  })
  headers = {
    'Authorization': 'Bearer ' + bearer,
    'Content-Type': 'application/json'
  }

  response = requests.request("POST", url, headers=headers, data=payload)
  print(response.text)


# Obtain list of licenses for VMs
# Returns a list with each item being a dict with:
#   serialNumber
#   configId
#   description
#   endDate
#
def get_vms_licenses():
  url = "https://support.fortinet.com/ES/api/flexvm/v1/vms/list"

  payload = json.dumps({
      "configId": 257
  })
  headers = {
    'Authorization': 'Bearer ' + bearer,
    'Content-Type': 'application/json'
  }

  response = requests.request("POST", url, headers=headers, data=payload)
  #print(response.text)
  vms = response.json()

  return vms['result']


# Function used to order lists of VMs
#
def getSN(vm):
  return vm['serialNumber']


# When working with LSD project, it will return the next N,M
# according to the counting system implemented in this project
# Each N group has M=250 VMs
# In node1: M goes 1, 5, 9, 13
# In node2: M goes 2, 6, 10, 14
# In node3: M goes 3, 7, 11, 15
# In node4: M goes 4, 8, 12, 16
#
def calculateNM(N,M):
  M += 1
  if M == 251:
    M = 1
    N += 4
    if N > 16:
      N -= 15
  return N, M


# Examples

# USE CASE 1: Create massive amount of licenses

# for i in range(0,23):
#  create_vm_license(257, 30, "LSD2", None)


# USE CASE 2: Simple update

# vms = get_vms_licenses()
# for vm in vms:
#     if vm['serialNumber'] > 'FGVMMLTM21002841'  and vm['serialNumber']<='FGVMMLTM21003095':
#       print(vm['serialNumber'] + " " + str(vm['description']))
#       if str(vm['description']) != 'LSD2':
#         print("  Updating VM: " + vm['serialNumber'])
#         update_vm(vm['serialNumber'], 257, 'LSD2', None)


if __name__ == 'main':

  # USE CASE 3: Rename each VM with a proper site-id name
  #
  vms = get_vms_licenses()
  vms.sort(key=getSN)

  N=1
  M=1
  vm_number = 0
  for vm in vms:
    print(f" number: {vm_number} key: {vm['serialNumber']} token: {vm['token']} N: {N}  M:{M}")
    update_vm_license(vm['serialNumber'], 257, f'site-{N}-{M}', None)
    vm_number +=1
    N, M = calculateNM(N,M)

