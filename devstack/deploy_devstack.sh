#!/bin/bash

sudo useradd -s /bin/bash -d /opt/stack -m stack
sudo chmod +x /opt/stack
echo "stack ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/stack
sudo yum install git wget tmux -y
sudo -u stack -i git clone https://opendev.org/openstack/devstack
sudo -u stack -i cd devstack
sudo -u stack -i wget "https://github.com/yadneshk/osp_deployment/blob/master/devstack/local.conf"
sudo -u stack -i ~/devstack/stack.sh

