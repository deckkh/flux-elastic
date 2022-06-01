#
# KIBANA
#

{{- define "kibana.oidc" }}
{{ if  .Values.elastic.config.oidc.enabled }}
    xpack.security.authc.providers:
      oidc.{{ .Values.elastic.config.oidc.name}}:
        order: 0
        realm: {{ .Values.elastic.config.oidc.name}}
        description: {{ .Values.elastic.config.oidc.description}}
      basic.native1:
        order: 1
{{ end }}
{{ end }}


{{- define "kibana.config" }}
  config:
{{- template "kibana.oidc" . }}
    monitoring:
      ui:
        ccs:
          enabled: false
{{ end }}

{{- define "kibana.containers"}}
        containers:
        - name: kibana
          resources:
            limits:
              memory: {{ .limits.memory}}
              cpu: {{ .limits.cpu}}
            requests:
              memory: {{ .requests.memory}}
              cpu: {{ .requests.cpu}}        
          env:
{{- end}}

{{- define "kibana.podtemplate" }}
  podTemplate:
    spec:
{{- include "generic.nodeselector" .Values.kibana.config.nodeselector | indent 6 }}
{{- include "generic.tolerations" .Values.kibana.config.tolerations |indent 6 }}
{{- include "generic.securitycontext" .Values.kibana.config.securitycontext |indent 6 }}
{{- template "kibana.containers" .Values.kibana.config }}
{{ end }}

{{- define "kibana.spec" }}
  version: {{ .Values.elastic.config.version}}
  count: {{ .Values.kibana.config.count}}
  elasticsearchRef:
    name: {{ .Release.Name }}
{{- template "kibana.config" . }}
{{- template "kibana.podtemplate" . }}
{{- end }}
