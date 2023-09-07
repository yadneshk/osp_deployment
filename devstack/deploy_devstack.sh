#!/bin/bash

sudo useradd -s /bin/bash -d /opt/stack -m stack
sudo chmod +x /opt/stack
echo "stack ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/stack
sudo su - stack
sudo yum install git wget tmux vim -y
git clone https://opendev.org/openstack/devstack
cd devstack
wget "https://github.com/yadneshk/osp_deployment/blob/master/devstack/local.conf"
~/devstack/stack.sh

