#!/bin/bash
#To be done in ubuntu 20.04LTS

sudo apt install -y virtinst virt-manager

#Manual
#Generate public key in default dir (~/.ssh/id_rsa.pub)


# Things done
# Check this: set etc/sysctl.conf: ipv4.forward (uncomment)
echo -e "\n\n*****************************************************"
echo -e "Running ssh-keygen... please enter fields manually:"
echo -e "*****************************************************"

ssh-keygen

echo -e "Done. \n\nPlease REBOOT NOW before starting demo:\n\n sudo reboot\n"
