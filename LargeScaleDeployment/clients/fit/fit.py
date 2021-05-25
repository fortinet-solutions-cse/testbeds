#!/usr/bin/python3
# -*- coding: utf-8 -*-

import click
import requests
import requests_toolbelt
import telnetlib
import socket
import random
from requests.packages.urllib3.exceptions import InsecureRequestWarning
from selenium import webdriver
import selenium
import platform

# disable warnings in requests for cert bypass
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

__version__ = 0.16

# some console colours
W = '\033[0m'  # white (normal)
R = '\033[31m'  # red
G = '\033[32m'  # green
O = '\033[33m'  # orange
B = '\033[34m'  # blue
P = '\033[35m'  # purple
C = '\033[36m'  # cyan
GR = '\033[37m'  # gray

if platform.system() == "Windows":
	W = ''  # white (normal)
	R = ''  # red
	G = ''  # green
	O = ''  # orange
	B = ''  # blue
	P = ''  # purple
	C = ''  # cyan
	GR = ''  # gray



def banner():
    '''Print stylized banner'''
    print(r"""
                          ,----,
                        ,/   .`|
    ,---,.   ,---,    ,`   .'  :
  ,'  .' |,`--.' |  ;    ;     /
,---.'   ||   :  :.'___,/    ,'
|   |   .':   |  '|    :     |
:   :  :  |   :  |;    |.';  ;
:   |  |-,'   '  ;`----'  |  |
|   :  ;/||   |  |    '   :  ;
|   |   .''   :  ;    |   |  '
'   :  '  |   |  '    '   :  |
|   |  |  '   :  |    ;   |.'
|   :  \  ;   |.'     '---'
|   | ,'  '---'
`----'
Firewall Inspection Tester
Author: Alex Harvey, @meshmeld""")
    print("Version: %0.2f\n" % __version__)


def checkconnection():
    ''' check network connection '''
    try:
        r = requests.get("https://www.google.ca", verify=False)
    except:
        return False
    else:
        return True


def checkips(srcip):
    for ipaddr in srcip:
        try:
            socket.inet_aton(ipaddr)
            print(G + "[+] " + W + "Source IP Address " + ipaddr)
        except socket.error:
            print(R + "[-] " + W + "IP Address " + ipaddr + " is not valid")
            exit(-1)

def setsrcip(srcip):
    ''' Set a random source ip from a list '''
    ip = random.choice(srcip)
    s = requests.Session()
    s.mount("http://", requests_toolbelt.adapters.source.SourceAddressAdapter(ip))
    s.mount("https://", requests_toolbelt.adapters.source.SourceAddressAdapter(ip))
    return s


@click.group(chain=True)
def cli():
    banner()
    if checkconnection():
        print(G + "[+] " + W + "Network connection is okay")
    else:
        print(R + "[!] " + W + "Network connection failed")
        print(R + "[!] " + W + "Please verify the network connection")
        exit(-1)


@cli.command()
@click.option('--repeat/--no-repeat', default=False)
@click.option('--srcip', '-s', multiple=True)
def all(repeat, srcip):
    '''Run all test one after the other'''
    checkips(srcip)
    if repeat:
        print(G + "[+] " + W + "Repeat, repeat, repeat...")

    while True:
        _iprep(srcip)
        _vxvault(srcip)
        _malwareurls(srcip)
        _appctrl()
        _webtraffic()
        if repeat == False:
            exit()


@cli.command()
@click.option('--srcip', '-s', multiple=True)
def iprep(srcip):
    '''IP Reputation test using zeustracker uiplist'''
    checkips(srcip)
    _iprep(srcip)


def _iprep(srcip):
    '''IP Reputation test using zeustracker uiplist'''
    # https://zeustracker.abuse.ch/blocklist.php?download=badips
    print(G + "[+] " + W + "IP Reputation Test")
    print(G + "[+] " + W + "Fetching bad ip list...", end=" ")
    r = requests.get("https://zeustracker.abuse.ch/blocklist.php?download=badips", verify=False)
    print("Done")

    # clean up list
    data2 = []
    data = r.text.split("\n")
    for line in data:
        if len(line) > 1:
            if line[0] != "#":
                data2.append(line)
    data = data2

    with click.progressbar(data) as ips:
        for ip in ips:
            try:
                tn = telnetlib.Telnet(ip, 443, 1)
            except (socket.timeout, socket.error, ConnectionRefusedError):
                pass


@cli.command()
@click.option('--srcip', '-s', multiple=True)
def vxvault(srcip):
    '''Malware samples download from vxvault'''
    checkips(srcip)
    _vxvault(srcip)


def _vxvault(srcip):
    '''Malware samples download from vxvault'''
    # http://vxvault.net/URL_List.php
    print(G + "[+] " + W + "VX Vault Malware Downloads")
    print(G + "[+] " + W + "Fetching VXVault list...", end=" ")
    r = requests.get("http://vxvault.net/URL_List.php", timeout=10)
    print("Done")

    if len(srcip) > 0:
        print(G + "[+] " + W + "Multi source IP mode enabled")

    # clean up list
    data2 = []
    data = r.text.split("\r\n")
    for line in data:
        if len(line) > 1:
            if line[0] == "h":
                data2.append(line)
    data = data2
    with click.progressbar(data) as urls:
        for url in urls:
            try:
                if len(srcip) > 0:
                    r = setsrcip(srcip).get(url, timeout=1)
                else:
                    r = requests.get(url, timeout=1)
            except requests.exceptions.RequestException:
                pass


@cli.command()
@click.option('--srcip', '-s', multiple=True)
def malwareurls(srcip):
    '''  Malware URl/Domain test '''
    checkips(srcip)
    _malwareurls(srcip)


def _malwareurls(srcip):
    '''  Malware URl/Domain test '''
    # http://www.malwaredomainlist.com/mdlcsv.php
    print(G + "[+] " + W + "Malware URL Downloads")
    print(G + "[+] " + W + "Fetching Malware URL list...", end=" ")
    # r = requests.get("http://vxvault.net/URL_List.php", timeout=1)
    f = open("malware_urls.csv", 'r')
    lines = f.read()
    print("Done")

    if len(srcip) > 0:
        print(G + "[+] " + W + "Multi source IP mode enabled")

    lines = lines.split("\n")
    with click.progressbar(lines) as urls:
        for url in urls:
            try:
                if len(srcip) > 0:
                    r = setsrcip(srcip).get(("http://" + url), timeout=1)
                else:
                    r = requests.get(("http://" + url), timeout=1)
            except requests.exceptions.RequestException:
                pass


@cli.command()
def appctrl():
    ''' Trigger application control '''
    _appctrl()


def _appctrl():
    ''' Trigger application control '''
    print(G + "[+] " + W + "Application Congtrol")
    print(G + "[+] " + W + "Fetching AppCtrl list...", end=" ")
    # r = requests.get("http://vxvault.net/URL_List.php", timeout=1)
    f = open("appctrl.csv", 'r')
    lines = f.read()
    print("Done")

    lines = lines.split("\n")
    with click.progressbar(lines) as urls:
        for url in urls:
            try:
                r = requests.get(url, timeout=1)
            except requests.exceptions.RequestException:
                pass


@cli.command()
def wf():
    '''  URL categorisation trigger '''
    _wf()


def _wf():
    '''  URL categorisation trigger '''
    # http://www.malwaredomainlist.com/mdlcsv.php
    print(G + "[+] " + W + "WF categorisation trigger")
    print(G + "[+] " + W + "Fetching URL list...", end=" ")
    # r = requests.get("http://vxvault.net/URL_List.php", timeout=1)
    f = open("wf.csv", 'r')
    lines = f.read()
    print("Done")

    lines = lines.split("\n")
    with click.progressbar(lines) as urls:
        for url in urls:
            try:
                r = requests.get(url, timeout=1)
            except requests.exceptions.RequestException:
                pass


@cli.command()
def webtraffic():
    ''' Generate good web traffic '''
    _webtraffic()


def _webtraffic():
    driver = webdriver.PhantomJS()
    driver.set_window_size(1920, 1080)
    driver.set_page_load_timeout(10)

    print(G + "[+] " + W + "Web traffic trigger")
    print(G + "[+] " + W + "Fetching traffic list...", end=" ")
    f = open("goodurl.csv", 'r')
    lines = f.read()
    print("Done")

    lines = lines.split("\n")
    with click.progressbar(lines) as urls:
        for url in urls:
            try:
                driver.get("http://www.%s" % url)
            except KeyboardInterrupt:
                raise
            except:
            	pass

    driver.quit()


if __name__ == '__main__':
    cli()
