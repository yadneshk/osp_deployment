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
./quickstart.sh --teardown all --no-clone --tags all  --nodes config/nodes/1ctlr_1comp.yml -p quickstart.yml -w /var/tmp/bootcamp/ --extra-vars whole_disk_images=False 127.0.0.2
```

## Ensure you can now connect to the undercloud
```
ssh -F /var/tmp/bootcamp/ssh.config.ansible undercloud ls  
```

## Undercloud Deployment
```
# Make sure to check the interface name of the ctlplane network and replace it in below
./quickstart.sh -R tripleo-ci/CentOS-8/master --no-clone --tags all --nodes config/nodes/1ctlr_1comp.yml -I --teardown none -p quickstart-extras-undercloud.yml -w /var/tmp/bootcamp/ 127.0.0.2
```

## Prepare the undercloud for the overcloud deployment
```
./quickstart.sh --no-clone --tags all --nodes config/nodes/1ctlr_1comp.yml -I --teardown none -p quickstart-extras-overcloud-prep.yml -w /var/tmp/bootcamp/ 127.0.0.2
```

## Deploy overcloud
```
./quickstart.sh --no-clone --tags all --nodes config/nodes/1ctlr_1comp.yml -I --teardown none -p quickstart-extras-overcloud.yml -w /var/tmp/bootcamp/ 127.0.0.2
```
