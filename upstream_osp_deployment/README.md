## Setup user
```
useradd oooq
echo 0 | passwd --stdin oooq
echo "oooq ALL=(root) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/oooq
sudo chmod 0440 /etc/sudoers.d/oooq
su - oooq
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
mkdir /var/tmp/bootcamp
```

## Setup VMs on the KVM host
```
./quickstart.sh --teardown none --no-clone --tags all  --nodes config/nodes/3ctlr_2comp_3ceph.yml -I -p quickstart-extras-undercloud.yml --extra-args ntp_server=clock.corp.redhat.com 127.0.0.2
```

## Ensure you can now connect to the undercloud
```
ssh -F ~/.quickstart/ssh.config.ansible undercloud 
```

## Undercloud Deployment
```
# Make sure to check the interface name of the ctlplane network and replace it in below
./quickstart.sh --teardown none --no-clone --tags all  --nodes config/nodes/3ctlr_2comp_3ceph.yml -I -p quickstart-extras-undercloud.yml --extra-vars ntp_server=clock.corp.redhat.com 127.0.0.2
```

## Prepare the undercloud for the overcloud deployment
```
./quickstart.sh --no-clone --tags all --nodes config/nodes/3ctlr_2comp_3ceph.yml -I --teardown none -p quickstart-extras-overcloud-prep.yml 127.0.0.2
```

## Deploy overcloud
```
./quickstart.sh --no-clone --tags all --nodes config/nodes/3ctlr_2comp_3ceph.yml -I --teardown none -p quickstart-extras-overcloud.yml 127.0.0.2
```
