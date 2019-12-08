#!/bin/bash

#######
#USAGE#
#######

# ./install-OSP.sh <hostname/IP of Beaker machine> <OSP version>

# ./install-OSP.sh dell-m620-4.gsslab.pnq.redhat.com 13

if [ ! -d ${HOME}/infrared ]
then
	echo -e "Installing Infrared"
	rm -Rf ${HOME}/infrared
	git clone https://github.com/redhat-openstack/infrared.git ${HOME}/infrared
	cd ${HOME}/infrared

	pip3 install --user virtualenv
	virtualenv --python=/usr/bin/python2 .venv && source .venv/bin/activate
	pip install --upgrade pip
	pip install --upgrade setuptools
	pip install selinux
	pip install -U -e .
	infrared plugin add plugins/virsh
	infrared plugin add plugins/tripleo-undercloud
	infrared plugin add plugins/tripleo-overcloud
else
	echo -e "Infrared already configured. Proceeding to OSP deployment"
fi

cd ${HOME}/infrared
source .venv/bin/activate
export HOST="$1"
export VERSION=$2
export HOST_KEY=${HOME}/.ssh/id_rsa
export ANSIBLE_LOG_PATH=deploy.log

echo -e "Checking if SSH connection to remote host..."
if [ $(ssh -q -o "BatchMode=yes" root@$1 exit; echo -e $?) -eq 0 ]
then
	echo -e "Success\n\nStarting OSP Deployment..."
	
	time infrared virsh --cleanup True --host-address $HOST --host-key $HOST_KEY
	time infrared virsh --host-address $HOST --host-key $HOST_KEY --topology-nodes undercloud:1,controller:3,compute:2,ceph:3 --topology-network 3_nets --disk-pool=/home/images/
	time infrared tripleo-undercloud --version $VERSION --images-task=rpm --build=latest
	time infrared tripleo-overcloud --deployment-files virt --version $VERSION --introspect yes --tagging yes --deploy yes --containers yes
else
	echo -e "SSH failed"
fi
