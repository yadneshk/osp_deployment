#!/bin/bash

NNCP_TIMEOUT=480
set -euxo pipefail

cd ~/install_yamls/devsetup
CPUS=36 MEMORY=96000 DISK=100 make crc 
make download_tools

make crc_attach_default_interface

EDPM_TOTAL_NODES=2 make edpm_compute

cd ..
make crc_storage
make input

make openstack
sleep 180 

make openstack_deploy

while true; do
    output=$(oc get oscp openstack-galera-network-isolation | grep galera)
    
    if echo "$output" | grep -q "True"; then
        echo "openstack-galera-network-isolation Ready"
        break  # Exit the loop if the string is found, remove this if you want to keep checking
    else
        echo "Waiting for oscp to be ready..."
    fi  
    sleep 5  # Wait 5 seconds before checking again, adjust the time as needed
done

DATAPLANE_TOTAL_NODES=2 make edpm_deploy
while true; do
    output=$(oc get osdpns | grep edpm)
    
    if echo "$output" | grep -q "True"; then
        echo "openstack-edpm-ipam Ready"
        break  # Exit the loop if the string is found, remove this if you want to keep checking
    else
        echo "Waiting for osdpns to be ready..."
    fi  
    sleep 5  # Wait 5 seconds before checking again, adjust the time as needed
done

make edpm_nova_discover_hosts

oc -n openstack rsh openstackclient openstack compute service list

oc create -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: cluster-observability-operator
  namespace: openshift-operators
spec:
  channel: development
  installPlanApproval: Automatic
  name: cluster-observability-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

cd ~/install_yamls/devsetup; make edpm_deploy_instance
