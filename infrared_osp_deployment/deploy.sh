#!/bin/bash

#######
#USAGE#
#######

# ./install-OSP.sh <hostname/IP of Beaker machine> <OSP version>

# ./install-OSP.sh dell-m620-4.gsslab.pnq.redhat.com 13

#rm -Rf ${HOME}/infrared
#rm -Rf ${HOME}/.infrared
#
#if [ ! -d ${HOME}/infrared ]
#then
#	echo -e "Installing Infrared"
#	rm -Rf ${HOME}/infrared
#	git clone https://github.com/redhat-openstack/infrared.git ${HOME}/infrared
#	cd ${HOME}/infrared
#
#	#pip3 install --user virtualenv
#	yum install git gcc libffi-devel openssl-devel python-virtualenv libselinux-python redhat-rpm-config -y
#	virtualenv .venv && source .venv/bin/activate
#	pip install --upgrade pip
#	pip install --upgrade setuptools
#	pip install selinux
#	pip install -U -e .
#	echo ". $(pwd)/etc/bash_completion.d/infrared" >> ${VIRTUAL_ENV}/bin/activate
#	infrared plugin add plugins/virsh
#	infrared plugin add plugins/tripleo-undercloud
#	infrared plugin add plugins/tripleo-overcloud
#else
#	echo -e "Infrared already configured. Proceeding to OSP deployment"
#fi
#
cd ${HOME}/infrared
source .venv/bin/activate
export HOST="$1"
export VERSION=$2
export HOST_KEY=${HOME}/.ssh/id_rsa
export ANSIBLE_LOG_PATH=deploy.log

echo -e "Verifying SSH connection to remote host..."
if [ $(ssh -q -o "BatchMode=yes" root@$1 exit; echo -e $?) -eq 0 ]
then
	echo -e "Success\n\nStarting OSP Deployment..."
	
	time infrared virsh --cleanup yes --host-address $HOST --host-key ~/.ssh/id_rsa -vvvv
	#time infrared virsh --host-address $HOST --host-key ~/.ssh/id_rsa --topology-nodes undercloud:1,controller:1,compute:1,ceph:0 --topology-network 3_nets --disk-pool=/home/images/ -e override.undercloud.cpu=4 -e override.undercloud.memory=10240 -e override.undercloud.disks.disk1.size=60G -e override.controller.cpu=4 -e override.controller.memory=10240 -e override.controller.disks.disk1.size=60G -e override.compute.cpu=4 -e override.compute.memory=6192 -e override.compute.disks.disk1.size=60G -e override.ceph.cpu=4 -e override.ceph.memory=8192 -e override.ceph.disks.disk1.size=60G
	#time infrared tripleo-undercloud --version $VERSION --images-task=rpm
	#time infrared tripleo-overcloud --deployment-files virt --version $VERSION --introspect yes --tagging yes --deploy yes --containers yes
	#echo -e "Deployment complete"
else
	echo -e "SSH failed"
fi
