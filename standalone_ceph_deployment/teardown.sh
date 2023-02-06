#!/bin/bash
unset OS_CLOUD
echo "Tearing down TripleO environment"
if type pcs &> /dev/null; then
    sudo pcs cluster destroy
fi
if type podman &> /dev/null; then
    echo "Removing podman containers and images (takes times...)"
    sudo podman rm -af
    sudo podman rmi -af
fi
sudo rm -rf \
    /var/lib/tripleo-config \
    /var/lib/config-data /var/lib/container-config-scripts \
    /var/lib/container-puppet \
    /var/lib/heat-config \
    /var/lib/image-serve \
    /var/lib/containers \
    /var/lib/tripleo-podman \
    /etc/systemd/system/tripleo* \
    /var/lib/mysql/* \
    /etc/openstack \
    /etc/ceph/* \
    ~/*.yaml \
    ~/*.log \
    /etc/systemd/system/tripleo_podman.service \
    /etc/systemd/system/ceph-osd-losetup.service
rm -rf ~/.config/openstack
sudo systemctl daemon-reload


FSID=$(sudo ls /var/lib/ceph)
sudo cephadm rm-cluster --force --fsid $FSID

sudo systemctl stop ceph-osd-losetup.service
sudo systemctl disable ceph-osd-losetup.service
sudo lvremove --force /dev/vg2/data-lv2
sudo vgremove --force vg2
sudo pvremove --force /dev/loop3
sudo losetup -d /dev/loop3
sudo rm -f /var/lib/ceph-osd.img
sudo partprobe
sudo ip link delete ceph-dummy0
