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

echo -e "Verifying SSH connection to remote host..."
if [ $(ssh -q -o "BatchMode=yes" root@$1 exit; echo -e $?) -eq 0 ]
then
	echo -e "Success\n\nStarting OSP Deployment..."
	
	time infrared virsh --cleanup yes --host-address $HOST --host-key ~/.ssh/id_rsa
	time infrared virsh --host-address $HOST --host-key ~/.ssh/id_rsa --topology-nodes undercloud:1,controller:1,compute:1,ceph:1 --topology-network 3_nets --disk-pool=/home/images/ -e override.undercloud.cpu=8 -e override.undercloud.memory=10240 -e override.undercloud.disks.disk1.size=60G -e override.controller.cpu=8 -e override.controller.memory=20480 -e override.controller.disks.disk1.size=60G -e override.compute.cpu=8 -e override.compute.memory=10240 -e override.compute.disks.disk1.size=60G -e override.ceph.cpu=4 -e override.ceph.memory=6192 -e override.ceph.disks.disk1.size=60G
	time infrared tripleo-undercloud --version $VERSION --images-task=rpm --cdn /root/automation_works/infrared_osp_deployment/undercloud_cdn.yml
	time infrared tripleo-overcloud --deployment-files virt --version $VERSION --introspect yes --tagging yes --deploy yes --containers yes --registry-skip-puddle yes --registry-mirror registry.access.redhat.com --registry-namespace rhosp13 --registry-prefix openstack --registry-tag {version}-{release}
	echo -e "Deployment complete"
else
	echo -e "SSH failed"
fi
