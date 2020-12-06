#!/usr/bin/env bash

echo "Adding Ansible apt repo"
sudo apt-add-repository -y ppa:ansible/ansible
sudo apt-get -y update

echo "Install packages"
sudo apt-get install -y grc nmap tree siege httpie tcpdump make git wget socat ansible

echo "Install helm"
sudo snap install helm --classic

echo "Install k9s"
sudo snap install k9s
mkdir /home/ubuntu/.k9s

echo "Install docker"
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
sudo apt-get -y update
sudo apt install -y docker-ce gnupg2 pass
sudo curl -L https://github.com/docker/compose/releases/download/1.21.2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo groupadd docker
sudo usermod -aG docker ubuntu
