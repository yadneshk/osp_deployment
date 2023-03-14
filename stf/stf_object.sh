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
  alertmanagerConfigManifest: |
    apiVersion: v1
    kind: Secret
    metadata:
      name: 'alertmanager-default'
      namespace: 'service-telemetry'
    type: Opaque
    stringData:
      alertmanager.yaml: |-
        global:
          resolve_timeout: 10m
        route:
          group_by: ['job']
          group_wait: 30s
          group_interval: 5m
          repeat_interval: 12h
          receiver: 'email'
        receivers:
        - name: 'email'
          email_configs:
          - to: 'xxxxx@gmail.com'
            from: 'xxxx@gmail.com'
            smarthost: 'smtp.gmail.com:587'
            auth_username: 'xxxxx@gmail.com'
            auth_password: 'put app_password here'
            require_tls: true
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
