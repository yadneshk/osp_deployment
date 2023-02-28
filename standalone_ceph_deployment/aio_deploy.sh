#!/bin/bash

set -Eeuo pipefail

export IP=192.168.24.2
export VIP=192.168.24.3
export NETMASK=24
export INTERFACE=eth1
export CEPH_IP=192.168.42.2


sudo hostnamectl set-hostname psi-standalone.localdomain
sudo hostnamectl set-hostname psi-standalone.localdomain --transient

sudo yum update -y && sudo yum install -y vim git curl util-linux lvm2 tmux wget
url=https://trunk.rdoproject.org/centos9/component/tripleo/current/
rpm_name=$(curl $url | grep python3-tripleo-repos | sed -e 's/<[^>]*>//g' | awk 'BEGIN { FS = ".rpm" } ; { print $1 }')
rpm=$rpm_name.rpm
sudo yum install -y $url$rpm
sudo -E tripleo-repos current-tripleo-dev ceph
sudo yum update -y
sudo yum install -y python3-tripleoclient

openstack tripleo container image prepare default --output-env-file $HOME/containers-prepare-parameters.yaml

sudo dd if=/dev/zero of=/var/lib/ceph-osd.img bs=1 count=0 seek=7G
sudo losetup /dev/loop3 /var/lib/ceph-osd.img
sudo pvcreate /dev/loop3
sudo vgcreate vg2 /dev/loop3
sudo lvcreate -n data-lv2 -l +100%FREE vg2

cat <<EOF > /tmp/ceph-osd-losetup.service
[Unit]
Description=Ceph OSD losetup
After=syslog.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c '/sbin/losetup /dev/loop3 || \
/sbin/losetup /dev/loop3 /var/lib/ceph-osd.img ; partprobe /dev/loop3'
ExecStop=/sbin/losetup -d /dev/loop3
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sudo mv /tmp/ceph-osd-losetup.service /etc/systemd/system/
sudo restorecon /etc/systemd/system/ceph-osd-losetup.service
sudo systemctl enable ceph-osd-losetup.service

sudo ip link add ceph-dummy0 type dummy
sudo ip addr add 192.168.42.2/24 dev ceph-dummy0
sudo ip addr add 192.168.42.3/32 dev ceph-dummy0
sudo ip link set ceph-dummy0 up

cat <<EOF > $HOME/standalone_parameters.yaml
parameter_defaults:
  CloudName: 192.168.24.2
  ControlPlaneStaticRoutes: []
  Debug: true
  DeploymentUser: centos
  DnsServers:
    - 10.11.5.160
    - 10.2.70.215
  DockerInsecureRegistryAddress:
    - 192.168.24.2:8787
  NeutronPublicInterface: eth1
  # domain name used by the host
  CloudDomain: localdomain
  NeutronDnsDomain: localdomain
  # re-use ctlplane bridge for public net, defined in the standalone
  # net config (do not change unless you know what you're doing)
  NeutronBridgeMappings: datacentre:br-ctlplane
  NeutronPhysicalBridge: br-ctlplane
  # enable to force metadata for public net
  #NeutronEnableForceMetadata: true
  StandaloneEnableRoutedNetworks: false
  StandaloneHomeDir: /home/centos
  InterfaceLocalMtu: 1500
  # Needed if running in a VM, not needed if on baremetal
  NovaComputeLibvirtType: qemu
  KernelDisableIPv6: 1
  NtpServer: 'clock.redhat.com'
EOF

cat <<EOF > $HOME/osd_spec.yaml
data_devices:
  paths:
    - /dev/vg2/data-lv2
EOF

sudo openstack overcloud ceph spec \
--standalone \
--mon-ip $CEPH_IP \
--osd-spec $HOME/osd_spec.yaml \
--output $HOME/ceph_spec.yaml

sudo openstack overcloud ceph user enable \
--standalone \
$HOME/ceph_spec.yaml

cat <<EOF > $HOME/initial_ceph.conf
[global]
osd pool default size = 1
[mon]
mon_warn_on_pool_no_redundancy = false
EOF

sudo openstack overcloud ceph deploy \
--mon-ip $CEPH_IP \
--ceph-spec $HOME/ceph_spec.yaml \
--config $HOME/initial_ceph.conf \
--standalone \
--single-host-defaults \
--skip-hosts-config \
--skip-container-registry-config \
--skip-user-create \
--output $HOME/deployed_ceph.yaml

cat <<EOF > $HOME/telemetry_services.yaml
resource_registry:
    OS::TripleO::Services::GnocchiApi: /usr/share/openstack-tripleo-heat-templates/deployment/gnocchi/gnocchi-api-container-puppet.yaml
    OS::TripleO::Services::GnocchiMetricd: /usr/share/openstack-tripleo-heat-templates/deployment/gnocchi/gnocchi-metricd-container-puppet.yaml
    OS::TripleO::Services::GnocchiStatsd: /usr/share/openstack-tripleo-heat-templates/deployment/gnocchi/gnocchi-statsd-container-puppet.yaml
    OS::TripleO::Services::AodhApi: /usr/share/openstack-tripleo-heat-templates/deployment/aodh/aodh-api-container-puppet.yaml
    OS::TripleO::Services::AodhEvaluator: /usr/share/openstack-tripleo-heat-templates/deployment/aodh/aodh-evaluator-container-puppet.yaml
    OS::TripleO::Services::AodhNotifier: /usr/share/openstack-tripleo-heat-templates/deployment/aodh/aodh-notifier-container-puppet.yaml
    OS::TripleO::Services::AodhListener: /usr/share/openstack-tripleo-heat-templates/deployment/aodh/aodh-listener-container-puppet.yaml
    OS::TripleO::Services::Collectd: /usr/share/openstack-tripleo-heat-templates/deployment/metrics/collectd-container-puppet.yaml

parameter_defaults:
    CeilometerEnableGnocchi: true
    CeilometerEnablePanko: false
    GnocchiArchivePolicy: 'high'

    CephAnsibleExtraConfig:
        common_single_host_mode: true

    EventPipelinePublishers: ['gnocchi://?filter_project=service']
    PipelinePublishers: ['gnocchi://?filter_project=service']

    # manage the polling and pipeline configuration files for Ceilometer agents
    ManagePolling: true
    ManagePipeline: true

    # enable Ceilometer metrics and events
    CeilometerQdrPublishMetrics: true
    CeilometerQdrPublishEvents: true

    # enable collection of API status
    CollectdEnableSensubility: true
    CollectdSensubilityTransport: amqp1

    # enable collection of containerized service metrics
    CollectdEnableLibpodstats: true

    # set collectd overrides for higher telemetry resolution and extra plugins
    # to load
    CollectdConnectionType: amqp1
    CollectdAmqpInterval: 5
    CollectdDefaultPollingInterval: 5
    CollectdExtraPlugins:
    - vmem
    StandaloneExtraConfig:
        ceilometer::agent::polling::polling_interval: 30
        ceilometer::agent::polling::polling_meters:
        - cpu
        - disk.*
        - ip.*
        - image.*
        - memory
        - memory.*
        - network.*
        - perf.*
        - port
        - port.*
        - switch
        - switch.*
        - storage.*
        - volume.*

        # to avoid filling the memory buffers if disconnected from the message bus
        # note: this may need an adjustment if there are many metrics to be sent.
        collectd::plugin::amqp1::send_queue_limit: 5000

        # receive extra information about virtual memory
        collectd::plugin::vmem::verbose: true

        # provide name and uuid in addition to hostname for better correlation
        # to ceilometer data
        collectd::plugin::virt::hostname_format: "name uuid hostname"

        # provide the human-friendly name of the virtual instance
        collectd::plugin::virt::plugin_instance_format: metadata

        # set memcached collectd plugin to report its metrics by hostname
        # rather than host IP, ensuring metrics in the dashboard remain uniform
        collectd::plugin::memcached::instances:
          local:
            host: "%{hiera('fqdn_canonical')}"
            port: 11211
        collectd::plugin::ceph::daemons:
        - 'ceph-mon.controller-00'
        - 'ceph-osd.01'
        - 'ceph-osd.02'
EOF

export CEPH_CLIENT_KEY=$(sudo cat /etc/ceph/ceph.client.admin.keyring | grep key | awk '{print $3}')

cat <<EOF > $HOME/ceph.client.glance.keyring
[client.glance]
   key = $CEPH_CLIENT_KEY
   caps mgr = allow *
   caps mon = profile rbd
   caps osd = profile rbd pool=images
EOF
sudo mv $HOME/ceph.client.glance.keyring /etc/ceph

cat <<EOF > $HOME/ceph.client.openstack.keyring
[client.openstack]
   key = $CEPH_CLIENT_KEY
   caps mgr = "allow *"
   caps mon = "profile rbd"
   caps osd = "profile rbd pool=vms, profile rbd pool=volumes, profile rbd pool=images"
EOF
sudo mv $HOME/ceph.client.openstack.keyring /etc/ceph

cat <<EOF > $HOME/ceph.client.radosgw.keyring
[client.radosgw]
   key = $CEPH_CLIENT_KEY 
   caps mgr = "allow *"
   caps mon = "allow rw"
   caps osd = "allow rwx"
EOF
sudo mv $HOME/ceph.client.radosgw.keyring /etc/ceph

sudo chcon -t container_file_t /etc/ceph/*

sudo openstack tripleo deploy --yes \
--templates /usr/share/openstack-tripleo-heat-templates \
--stack standalone \
--standalone-role Standalone \
--local-ip $IP/$NETMASK \
--control-virtual-ip $VIP \
-e /usr/share/openstack-tripleo-heat-templates/environments/standalone/standalone-tripleo.yaml \
-r /usr/share/openstack-tripleo-heat-templates/roles/Standalone.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/cephadm/cephadm.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/low-memory-usage.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/metrics/ceilometer-write-qdr.yaml \
-e $HOME/containers-prepare-parameters.yaml \
-e $HOME/standalone_parameters.yaml \
-e $HOME/telemetry_services.yaml \
-e $HOME/deployed_ceph.yaml \
--output-dir $HOME/tripleo_output \
--reproduce-command > $HOME/standalone_deploy.log 2>&1

echo "export OS_CLOUD=standalone" >> ~/.bashrc
