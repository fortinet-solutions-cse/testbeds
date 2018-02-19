#!/usr/bin/env bash

# Test FortiMail traffic with this simple script:

sudo apt-get install -y swaks

swaks -f a@agmail.com -t a@a.com -s 172.21.6.159

while true; do
  sleep 1;
  swaks -f a@agmail.com -t a@a.com -s 172.21.6.159;
done