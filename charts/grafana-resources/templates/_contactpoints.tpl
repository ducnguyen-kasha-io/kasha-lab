{{- define "tpl-contactpoints" -}}
{{- range $provision := .Values.grafana.provision.contactpoints.channelList -}}
{{ $secretKeyRef := $.Values.grafana.secretKeyRef }}
{{ $clusterId := $provision.clusterId }}
{{ $clusterEnv := $provision.clusterEnv }}
apiVersion: grizzly.grafana.com/v1alpha1
kind: AlertContactPoint
metadata:
    name: kasha-teams-non-prd-channel
spec:
    disableResolveMessage: false
    name: Kasha Test Alert
    settings:
        message: '{{ template "kasha.teams.message" . }}'
        title: '{{ template "kasha.teams.title" . }}'
        url: https://kashaglobalholdinglimited.webhook.office.com/webhookb2/7f9a9209-4e9f-4538-a968-185887a64cfd@01599455-31f6-4698-812b-887ffb90c9c9/IncomingWebhook/0e6461d89d9d489899ab6e4d10f9e43a/88fd40bf-4656-401d-b39b-3741bc13a446/V2phJ2WTm5j07j5KVPhZ29JIIeyRii3_Qwfi1kdQ9_2zQ1
    type: teams
    uid: kasha-teams-non-prd-channel
{{- end -}}
{{- end -}}

