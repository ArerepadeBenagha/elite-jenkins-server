#!/bin/bash
# This scripts is standard doc installation procress
# https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-20-04

sudo apt update -y
sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
sudo apt install docker-ce -y
sudo apt update -y

# Docker permissions
sudo groupadd docker && sudo gpasswd -a $USER docker
sudo chmod 666 /var/run/docker.sock
