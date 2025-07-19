{{- define "alert-rule-group" -}}
{{- range $datasources := .Values.grafana.provision.datasources -}}
{{ $clusterId := $datasources.clusterId }}
{{ $clusterEnv := $datasources.clusterEnv }}
{{ $alertEnabled := $datasources.alertEnabled }}
{{- if ne $alertEnabled false }}
apiVersion: grafana.integreatly.org/v1beta1
kind: GrafanaAlertRuleGroup
metadata:
  name: {{ printf "%s" $clusterId }}
  namespace: {{ $.Release.Namespace }}
spec:
  folderRef: {{ printf "%s" $clusterId }}
  instanceSelector:
{{ toYaml $.Values.grafana.instanceSelector | indent 4 }}
  interval: 5m
  rules:
    - uid: {{ printf "ClientWebsiteNotReady-%s" $clusterId |  trunc 40 | lower  }}
      title: ClientWebsiteNotReady
      condition: C
      data:
        - refId: A
          relativeTimeRange:
            from: 600
            to: 0
          datasourceUid: {{ printf "metrics-%s" $clusterId }}
          model:
            disableTextWrap: false
            editorMode: builder
            expr: max_over_time(kube_pod_container_status_waiting_reason{namespace="deployments"}[10m]) >= bool 1
            fullMetaSearch: false
            includeNullMetadata: true
            instant: true
            intervalMs: 1000
            legendFormat: __auto
            maxDataPoints: 43200
            range: false
            refId: A
            useBackend: false
        - refId: C
          datasourceUid: __expr__
          model:
            conditions:
                - evaluator:
                    params:
                        - 0
                    type: gt
                  operator:
                    type: and
                  query:
                    params:
                        - C
                  reducer:
                    params: []
                    type: last
                  type: query
            datasource:
                type: __expr__
                uid: __expr__
            expression: A
            intervalMs: 1000
            maxDataPoints: 43200
            refId: C
            type: threshold
      noDataState: NoData
      execErrState: Error
      for: 5m
      annotations:
        summary: Client's website is not ready after more than 5 minutes.
      labels:
        owner: IT Operations
        priority: P1
      isPaused: true
      notificationSettings:
        receiver: kasha-team-non-prd-alerts
{{ end -}}
---
{{- end -}}
{{- end -}}
