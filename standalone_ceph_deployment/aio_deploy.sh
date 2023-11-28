#!/bin/bash

set -Eeuo pipefail

useradd -s /bin/bash -m stack
echo "stack ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/stack
hostnamectl set-hostname standalone.localdomain
hostnamectl set-hostname standalone.localdomain --transient

sudo -u stack -i
export IP=192.168.24.2
export VIP=192.168.24.3
export NETMASK=24
export INTERFACE=eth1

sudo yum update -y && sudo yum install -y vim git curl util-linux tmux wget
url=https://trunk.rdoproject.org/centos9-wallaby/component/tripleo/current-tripleo/
rpm_name=$(curl $url | grep python3-tripleo-repos | sed -e 's/<[^>]*>//g' | awk 'BEGIN { FS = ".rpm" } ; { print $1 }')
rpm=$rpm_name.rpm
sudo yum install -y $url$rpm
sudo -E tripleo-repos -b wallaby current-tripleo-dev --stream
sudo yum update -y
sudo yum install -y python3-tripleoclient

sudo openstack tripleo container image prepare default --output-env-file $HOME/containers-prepare-parameters.yaml

cat <<EOF > $HOME/standalone_parameters.yaml
parameter_defaults:
  CloudName: $IP
  ControlPlaneStaticRoutes: []
  Debug: true
  DeploymentUser: $USER
  DnsServers:
    - 10.11.5.160
    - 10.2.70.215
  DockerInsecureRegistryAddress:
    - $IP:8787
  NeutronPublicInterface: $INTERFACE
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
  StandaloneHomeDir: /home/$USER
  InterfaceLocalMtu: 1500
  # Needed if running in a VM, not needed if on baremetal
  NovaComputeLibvirtType: qemu
  KernelDisableIPv6: 1
  NtpServer: 'clock.redhat.com'
EOF

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
EOF

sudo openstack tripleo deploy --yes \
--templates /usr/share/openstack-tripleo-heat-templates \
--stack standalone \
--standalone-role Standalone \
--local-ip $IP/$NETMASK \
--control-virtual-ip $VIP \
-e /usr/share/openstack-tripleo-heat-templates/environments/standalone/standalone-tripleo.yaml \
-r /usr/share/openstack-tripleo-heat-templates/roles/Standalone.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/low-memory-usage.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/metrics/ceilometer-write-qdr.yaml \
-e $HOME/containers-prepare-parameters.yaml \
-e $HOME/standalone_parameters.yaml \
-e $HOME/telemetry_services.yaml \
--output-dir $HOME/tripleo_output > $HOME/standalone_deploy.log 2>&1

echo "export OS_CLOUD=standalone" >> ~/.bashrc
