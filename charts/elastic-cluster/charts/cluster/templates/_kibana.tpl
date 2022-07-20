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

{{- define "kibana.elasticsearch" }}
    elasticsearch:
      hosts:
      - https://{{.Release.Name}}-es-http.observability.svc:9200
      serviceAccountToken : ${SERVICE_ACCOUNT_TOKEN}
      ssl:
        certificateAuthorities: /etc/certs/ca.crt        
        verificationMode: certificate
{{ end }}

{{- define "kibana.config" }}
  config:
{{- template "kibana.elasticsearch" . }}
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


  volumeMounts:
    - name: elasticsearch-certs
      mountPath: /etc/certs
      readOnly: true            
{{- end}}

{{- define "kibana.serviceaccounttoken" }}
- name: SERVICE_ACCOUNT_TOKEN
  valueFrom:
    secretKeyRef:
      key: token
      name: {{ .Release.Name}}-kibana-user
{{ end}}

{{- define "kibana.env" }}
env:

{{- include "kibana.serviceaccounttoken" .}}
{{ end}}

{{- define "kibana.podtemplate" }}
  podTemplate:
    spec:


      volumes:
        - name: elasticsearch-certs
          secret:
            secretName: cluster14-es-http-certs-public

{{- include "generic.nodeselector" .Values.kibana.config.nodeselector | indent 6 }}
{{- include "generic.tolerations" .Values.kibana.config.tolerations |indent 6 }}
{{- include "generic.securitycontext" .Values.kibana.config.securitycontext |indent 6 }}
{{- include "kibana.containers" .Values.kibana.config | indent 6 }}
{{- include "kibana.env" . | indent 8 }}

{{ end }}

{{- define "kibana.spec" }}
  version: {{ .Values.elastic.config.version}}
  count: {{ .Values.kibana.config.count}}
{{- template "kibana.config" . }}
{{- template "kibana.podtemplate" . }}
{{- end }}
