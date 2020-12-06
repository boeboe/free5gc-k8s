#!/usr/bin/env bash

HOSTNAME=$(hostname)

echo "Copy ssh keys and change permissions"
sudo cp ./ssh/${HOSTNAME}/* /home/ubuntu/.ssh
sudo chown -R ubuntu:ubuntu /home/ubuntu/.ssh
sudo chmod 600 /home/ubuntu/.ssh/id_rsa
sudo chmod 644 /home/ubuntu/.ssh/id_rsa.pub

echo "Disable ssh strict host key checking"
tee -a ~/.ssh/config << END
Host *
    StrictHostKeyChecking no
END

sudo chmod 400 ~/.ssh/config

echo "Add blueprint ssh keys to authorized_keys"
cat ./ssh/*/id_rsa.pub >> ~/.ssh/authorized_keys
