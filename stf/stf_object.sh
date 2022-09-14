oc apply -f - <<EOF
apiVersion: infra.watch/v1beta1
kind: ServiceTelemetry
metadata:
  name: default
  namespace: service-telemetry
spec:
  alerting:
    enabled: true
    alertmanager:
      storage:
        strategy: ephemeral
  backends:
    metrics:
      prometheus:
        enabled: true
        storage:
          strategy: ephemeral
    events:
      elasticsearch:
        enabled: true
        storage:
          strategy: ephemeral
  clouds:
  - events:
      collectors:
      - collectorType: collectd
        debugEnabled: false
        subscriptionAddress: collectd/cloud1-notify
      - collectorType: ceilometer
        debugEnabled: false
        subscriptionAddress: anycast/ceilometer/cloud1-event.sample
    metrics:
      collectors:
      - collectorType: collectd
        debugEnabled: false
        subscriptionAddress: collectd/cloud1-telemetry
      - collectorType: ceilometer
        debugEnabled: false
        subscriptionAddress: anycast/ceilometer/cloud1-metering.sample
      - collectorType: sensubility
        debugEnabled: false
        subscriptionAddress: sensubility/cloud1-telemetry
    name: cloud1
  graphing:
    enabled: false
    grafana:
      adminPassword: secret
      adminUser: root
      baseImage: docker.io/grafana/grafana:latest
      disableSignoutMenu: false
      ingressEnabled: false
  highAvailability:
    enabled: false
  observabilityStrategy: use_community
  transports:
    qdr:
      enabled: true
      web:
        enabled: false
EOF
