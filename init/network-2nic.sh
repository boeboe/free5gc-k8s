#!/usr/bin/env bash

sudo tee /etc/netplan/50-cloud-init.yaml << END
network:
    version: 2
    ethernets:
        ens5:
            dhcp4: true
        ens6:
            dhcp4: true
END

sudo netplan apply

ifconfig -a | grep ens -A 1
