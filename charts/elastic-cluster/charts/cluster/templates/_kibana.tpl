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


{{- define "kibana.logging" }}
    logging:
      appenders:
        json-layout:
          type: console
          layout:
            type: json
      root:
        appenders: [json-layout]
{{ end }}


{{- define "kibana.config" }}
  config:
{{- template "kibana.oidc" . }}
{{- template "kibana.logging" . }}
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
{{- end}}

{{- define "kibana.securesettings"}}
secureSettings:
- secretName:  {{ .Release.Name}}-kb-reporting-encryption
- secretName:  {{ .Release.Name}}-kb-security-encryption
- secretName:  {{ .Release.Name}}-kb-savedobjects-encryption
{{- end}}


{{- define "kibana.podtemplate" }}
  podTemplate:
    spec:
{{- include "generic.nodeselector" .Values.kibana.config.nodeselector | indent 6 }}
{{- include "generic.tolerations" .Values.kibana.config.tolerations |indent 6 }}
{{- include "generic.securitycontext" .Values.kibana.config.securitycontext |indent 6 }}
{{- include "kibana.containers" .Values.kibana.config | indent 6 }}
{{ end }}

{{- define "kibana.spec" }}
  version: {{ .Values.elastic.config.version}}
  count: {{ .Values.kibana.config.count}}

  elasticsearchRef:
    name: "{{ .Release.Name }}"

{{- include "kibana.securesettings" .Values.kibana.config | indent 2 }}

{{- template "kibana.config" . }}
{{- template "kibana.podtemplate" . }}
{{- end }}
