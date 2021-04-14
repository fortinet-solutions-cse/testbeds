#!/usr/bin/env python3

import yaml
from jinja2 import Template
from os import environ


def is_good_to_go(question):
    return True if input(question).strip().lower() in ['y', 'yes'] else False


def readConfig():

    print("========================")
    print(" Tenant: " + environ.get("LSD_TENANT"))
    print("========================")
    tenantdir = "tenants/" + environ.get("LSD_TENANT") + "/"

    with open('config.yaml', 'r') as cfgfile, open(tenantdir + 'tenant.yaml.j2', 'r') as tntfile:
        cfg = yaml.safe_load(cfgfile) | yaml.safe_load(Template(tntfile.read()).render())

    print("     FMG URL = " + cfg['fmg_api'])
    print("     FAZ URL = " + cfg['faz_api'])
    print("     Tenant ADOM = " + cfg['adom'])

    if 'ignore_regions' in cfg:
        print("     Ignoring Regions: " + ', '.join(cfg['ignore_regions']))
        cfg['regions'] = [ reg for reg in cfg['regions'] if reg['name'] not in cfg['ignore_regions'] ]

    for region in cfg['regions']:
        if 'geo-file' in region:
            with open(tenantdir + region['geo-file'], 'r') as geofile:
                region['edge-geo'] = [ l.split() for l in geofile.read().splitlines() ]

    if 'QUIET' in environ:
        cfg['quiet'] = True

    return cfg
