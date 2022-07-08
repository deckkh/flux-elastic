#
# FILEBEAT
# 


{{- define "filebeat.volumemounts" }}
- mountPath: /usr/share/metricbeat/certs/output-ca
  name: output-ca
{{ end }}


{{- define "filebeat.volumes" }}
- name: output-ca
  secret:
    secretName: {{ .Values.filebeat.config.output.cluster}}-{{ .Values.filebeat.config.output.httpca}}
{{ end }}

{{- define "filebeat.apikey" }}
- name: API_KEY
  valueFrom:
    secretKeyRef:
      key: apikey
      name: {{ .Values.filebeat.config.output.cluster}}-{{ .Values.filebeat.config.output.apikey}}
{{ end}}

{{- define "filebeat.output" }}
output.elasticsearch:
    hosts: ["https://{{ .Values.filebeat.config.output.cluster}}-es-http:9200"]
    api_key: ${API_KEY}
    ssl.verification_mode: "certificate"
    ssl.certificate_authorities: ["/usr/share/metricbeat/certs/output-ca/tls.crt"]
{{ end}}

{{- define "filebeat.tolerations" }}

{{- if eq .Values.filebeat.config.collect "elasticlogs" }}
- key: es-other
  operator: "Exists"
  effect: NoSchedule
- key: es-data
  operator: "Exists"
  effect: NoSchedule
{{ else }}  
- operator: "Exists"
{{ end }}  

{{ end}}

{{- define "filebeat.templates" }}
{{- if eq .Values.filebeat.config.collect "elasticlogs" }}
templates:
    - condition:
        equals:
          kubernetes.container.name: elasticsearch
      config:
        - type: container
          paths:
            - /var/log/containers/*-${data.kubernetes.container.id}.log    

          processors:
          - decode_json_fields:
              fields: ["message"]
              process_array: false
              max_depth: 1
              target: "orgmsg"
              overwrite_keys: false
              add_error_key: true

    - condition:
        equals:
          kubernetes.container.name: kibana
      config:
        - type: container
            paths:
            - /var/log/containers/*-${data.kubernetes.container.id}.log    

          processors:
          - decode_json_fields:
              fields: ["message"]
              process_array: false
              max_depth: 1
              target: "orgmsg"
              overwrite_keys: false
              add_error_key: true

{{ else }}            
templates:
    - condition:
        not:
          or: 
            - equals: 
                kubernetes.container.name: elasticsearch
            - equals: 
                kubernetes.container.name: kibana
      config:
        - type: container
          paths:
            - /var/log/containers/*-${data.kubernetes.container.id}.log    
{{ end }}            
{{ end}}

