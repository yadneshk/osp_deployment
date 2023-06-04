#!/bin/bash

export DNS=
export NTP=

cd ~/install_yamls/devsetup
make edpm_play_cleanup
make edpm_compute_cleanup

cd ~/install_yamls/
make openstack_deploy_cleanup
make openstack_cleanup
make crc_storage_cleanup

cd ~/install_yamls/devsetup
make crc_cleanup
CPUS=8 MEMORY=20480 DISK=60 make crc
make download_tools

cd ~/install_yamls/
NETWORK_ISOLATION=false make openstack
make crc_storage
make input
NETWORK_ISOLATION=false make openstack_deploy

make ansibleee
cd ~/install_yamls/devsetup
make crc_attach_default_interface
DATAPLANE_DNS_SERVER=$DNS DATAPLANE_CHRONY_NTP_SERVER=$NTP EDPM_COMPUTE_SUFFIX=0 DATAPLANE_SINGLE_NODE=false make edpm_compute
DATAPLANE_DNS_SERVER=$DNS DATAPLANE_CHRONY_NTP_SERVER=$NTP EDPM_COMPUTE_SUFFIX=0 DATAPLANE_SINGLE_NODE=false make edpm_compute_repos
cd ~/install_yamls/
DATAPLANE_DNS_SERVER=$DNS DATAPLANE_CHRONY_NTP_SERVER=$NTP EDPM_COMPUTE_SUFFIX=0 DATAPLANE_SINGLE_NODE=false make edpm_deploy
