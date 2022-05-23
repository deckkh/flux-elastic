#
# GENERIC
# 

{{- define "generic.tolerations" }}
{{ if  .key }}
tolerations:
  - key: {{ .key}}
    operator: Equal
    value: {{ .value }}
    effect: NoSchedule          
{{- end }}
{{end }}

{{- define "generic.securitycontext" }}
{{ if  .runasuser }}
securityContext: 
  runAsUser: {{ .runasuser}}
  fsGroup: {{ .fsgroup }}
  runAsNonRoot: {{ .runasnonroot }}
{{- end }}
{{- end }}


{{- define "generic.nodeselector" }}
{{ if  .key }}
nodeSelector:
  {{ .key }}: {{ .value}}
{{- end }}
{{- end }}
