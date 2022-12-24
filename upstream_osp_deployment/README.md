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
./quickstart.sh --install-deps
```

## Setup env
```
#!/bin/bash

set -Eeuo pipefail

export LIBGUESTFS_BACKEND_SETTINGS=network_bridge=virbr0
export UNDERCLOUD_NTP_SERVER=<ntp server>

./quickstart.sh --teardown  all --no-clone --tags all --nodes config/nodes/3ctlr_2comp_3ceph.yml -p quickstart.yml 127.0.0.2
./quickstart.sh --teardown none --no-clone --tags all --nodes config/nodes/3ctlr_2comp_3ceph.yml -I -p quickstart-extras-undercloud.yml --extra-vars undercloud_undercloud_ntp_servers=$UNDERCLOUD_NTP_SERVER 127.0.0.2
./quickstart.sh --teardown none --no-clone --tags all --nodes config/nodes/3ctlr_2comp_3ceph.yml -I -p quickstart-extras-overcloud-prep.yml 127.0.0.2
./quickstart.sh --teardown none --no-clone --tags all --nodes config/nodes/3ctlr_2comp_3ceph.yml -I -p quickstart-extras-overcloud.yml 127.0.0.2
```
