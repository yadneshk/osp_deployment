## Setup user
```
useradd deployer
echo 0 | passwd --stdin deployer
echo "deployer ALL=(root) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/deployer
sudo chmod 0440 /etc/sudoers.d/deployer
su - deployer
```

## Setup ssh-keys
```
ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''
ssh-copy-id root@127.0.0.2
```

## Install deps
```
yum -y install git tmux wget ansible vim
git clone https://opendev.org/openstack/tripleo-quickstart.git
cd tripleo-quickstart
export NTP_SERVER=clock.corp.redhat.com
cat <<EOF >  extra-vars.yaml
extra_args: >-
  --ntp-server $NTP_SERVER

undercloud_undercloud_ntp_servers: $NTP_SERVER
undercloud_clean_nodes: False
EOF

./quickstart.sh --install-deps
```

## Setup env
```
#!/bin/bash

set -Eeuo pipefail

#RELEASE=wallaby
#RELEASE=tripleo-ci/CentOS-9/wallaby
RELEASE=tripleo-ci/CentOS-8/wallaby
NODES_CONFIG=1ctlr_1comp_1ceph

cd ~/tripleo-quickstart
./quickstart.sh -b -X -R ${RELEASE} --tags all --nodes config/nodes/${NODES_CONFIG}.yml --extra-vars @`pwd`/extra-vars.yaml --extra-vars @/root/tripleo-quickstart/config/general_config/featureset049.yml -p quickstart.yml 127.0.0.2

cd ~/.quickstart/tripleo-quickstart
./quickstart.sh -R ${RELEASE} --tags all -I -T none --nodes config/nodes/${NODES_CONFIG}.yml --extra-vars @/root/tripleo-quickstart/extra-vars.yaml --extra-vars @/root/tripleo-quickstart/config/general_config/featureset049.yml -p quickstart-extras-undercloud.yml 127.0.0.2
./quickstart.sh -R ${RELEASE} --tags all -I -T none --nodes config/nodes/${NODES_CONFIG}.yml --extra-vars @/root/tripleo-quickstart/extra-vars.yaml --extra-vars @/root/tripleo-quickstart/config/general_config/featureset049.yml -p quickstart-extras-overcloud-prep.yml 127.0.0.2
./quickstart.sh -R ${RELEASE} --tags all -I -T none --nodes config/nodes/${NODES_CONFIG}.yml --extra-vars @/root/tripleo-quickstart/extra-vars.yaml --extra-vars @/root/tripleo-quickstart/config/general_config/featureset049.yml -p quickstart-extras-overcloud.yml 127.0.0.2
```
