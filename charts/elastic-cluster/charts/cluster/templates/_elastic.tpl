#
# ELASTIC
#


{{- define "elastic.noderoles" }}
      node.roles: [{{ join "," .roles  }} ]
{{- end }}

{{- define "elastic.annotations" }}
{{ if  .Values.elastic.config.zoneawareness }}
  annotations:
    eck.k8s.elastic.co/downward-node-labels: "topology.kubernetes.io/zone"
{{ end }}
{{ end }}

{{- define "elastic.config.zoneawareness" }}
{{ if  .Values.elastic.config.zoneawareness }}
      # uncomment the lines below to use the zone attribute from the node labels
      cluster.routing.allocation.awareness.attributes: k8s_node_name,zone
      node.attr.zone: ${ZONE}
{{- end }}
{{- end }}


{{- define "elastic.podtemplate.env" }}
{{ if  .Values.elastic.config.zoneawareness }}
          # uncomment the lines below to make the topology.kubernetes.io/zone annotation available as an environment variable and
          # use it as a cluster routing allocation attribute.
          - name: ZONE
            valueFrom:
              fieldRef:
                fieldPath: metadata.annotations['topology.kubernetes.io/zone']
{{- end }}
{{- end }}


{{- define "elastic.podtemplate.topology" }}
{{- $root := index . 0 -}}
{{- $local := index . 1 -}}

{{ if  $root.Values.elastic.config.zoneawareness }}
        topologySpreadConstraints:
          - maxSkew: 1
            topologyKey: topology.kubernetes.io/zone
            whenUnsatisfiable: DoNotSchedule 
            labelSelector:
              matchLabels:
                elasticsearch.k8s.elastic.co/cluster-name: {{ $root.Release.Name}}
                elasticsearch.k8s.elastic.co/statefulset-name: {{ $root.Release.Name}}-es-{{ $local.name}}
{{- end }}
{{- end }}


{{- define "elastic.shared_cache"}}
{{ if  .shared_cache }}
      xpack.searchable.snapshot.shared_cache.size: {{ .shared_cache }}
{{ end}}      
{{- end }}

{{- define "elastic.mmap"}}
      node.store.allow_mmap: {{ .Values.production.enabled }}
{{ end }}

{{- define "elastic.oidc" }}
{{ if  .Values.elastic.config.oidc.enabled }}
      xpack.security.authc.realms.native.native1:
        order: 0
      xpack.security.authc.realms.oidc.{{ .Values.elastic.config.oidc.name }}:
        order: 1
        rp.client_id: "{{ .Values.elastic.config.oidc.clientid }}"
        rp.response_type: "code"
        rp.requested_scopes: ["openid", "email"]
        rp.redirect_uri: "{{ .Values.kibana.config.endpoint }}/api/security/oidc/callback"
        op.issuer: "https://login.microsoftonline.com/{{ .Values.elastic.config.oidc.tenantid }}/v2.0"
        op.authorization_endpoint: "https://login.microsoftonline.com/{{ .Values.elastic.config.oidc.tenantid }}/oauth2/v2.0/authorize"
        op.token_endpoint: "https://login.microsoftonline.com/{{ .Values.elastic.config.oidc.tenantid }}/oauth2/v2.0/token"
        op.userinfo_endpoint: "https://graph.microsoft.com/oidc/userinfo"
        op.endsession_endpoint: "https://login.microsoftonline.com/{{ .Values.elastic.config.oidc.tenantid }}/oauth2/v2.0/logout"
        rp.post_logout_redirect_uri: "{{ .Values.kibana.config.endpoint }}/logged_out"
        op.jwkset_path: "https://login.microsoftonline.com/{{ .Values.elastic.config.oidc.tenantid }}/discovery/v2.0/keys"
        claims.principal: sub
{{- end }}
{{- end }}


{{- define "elastic.config" }}
{{- $root := index . 0 -}}
{{- $local := index . 1 -}}
{{- template "elastic.mmap" $root }}
{{- template "elastic.config.zoneawareness" $root }}
{{- template "elastic.shared_cache" $local }}
{{- template "elastic.noderoles" $local }}
{{- template "elastic.oidc" $root }}
{{- end }}







{{- define "elastic.initcontainers"}}
        initContainers:
{{ if  .Values.production.enabled }}
        - name: sysctl
          securityContext:
            privileged: true
          command: ['sh', '-c', 'sysctl -w vm.max_map_count=262144']
{{ end }}

{{ if  .Values.elastic.config.oidc.enabled }}
        - name: elastic-internal-init-keystore
          env:
{{ template "elastic.podtemplate.env" .}}
{{ end }}

{{- end}}

{{- define "elastic.containers"}}
{{- $root := index . 0 }}
{{- $local := index . 1 }}
        containers:
        - name: elasticsearch
          resources:
            limits:
              memory: {{ $local.limits.memory}}
              cpu: {{ $local.limits.cpu}}
            requests:
              memory: {{ $local.requests.memory}}
              cpu: {{ $local.requests.cpu}}        
          env:
{{ template "elastic.podtemplate.env" $root }}
{{- end}}



{{- define "elastic.podtemplate" }}
{{- $root := index . 0 }}
{{- $local := index . 1 }}
    podTemplate:
      spec:
{{- include "generic.nodeselector" $root.Values.elastic.config.nodeselector | indent 8 }}
{{- include "generic.tolerations" $root.Values.elastic.config.tolerations | indent 8}}
{{- include "generic.securitycontext" $root.Values.elastic.config.securitycontext | indent 8 }}
{{- template "elastic.initcontainers" $root }}
{{- template "elastic.containers" (list $root $local)}}
{{- template "elastic.podtemplate.topology" (list $root $local)}}
{{- end }}


{{- define "elastic.volumeclaim"}}
    volumeClaimTemplates:
    - metadata:
        name: elasticsearch-data # Do not change this name unless you set up a volume mount for the data path.
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: {{ .storage}}
        storageClassName: {{ .storageclass}}
{{- end}}


{{- define "elastic.securesettings" }}

{{ if  .Values.elastic.config.oidc.enabled }}
  secureSettings:
  - secretName: mysecret
{{ end }}
{{ end }}




{{- define "elastic.nodeset" }}
{{- $root := index . 0 -}}
{{- $local := index . 1 -}}
{{ if gt ( $local.count |toString|atoi) 0 }}
  - name: {{ $local.name}}
    count: {{ $local.count}}
    config:
{{- template "elastic.config" (list $root $local) }}
{{- template "elastic.podtemplate" (list $root $local) }}
{{- template "elastic.volumeclaim" $local }}

{{ end }}

{{- end }}


{{- define "elastic.nodesets" }}
  nodeSets:

{{- template "elastic.nodeset" (list .  .Values.master.nodeset)}}
{{- template "elastic.nodeset" (list .  .Values.data.nodeset)}}
{{- template "elastic.nodeset" (list .  .Values.datahot.nodeset)}}
{{- template "elastic.nodeset" (list .  .Values.datawarm.nodeset)}}
{{- template "elastic.nodeset" (list .  .Values.datacold.nodeset)}}
{{- template "elastic.nodeset" (list .  .Values.datafrozen.nodeset)}}
{{- template "elastic.nodeset" (list .  .Values.ingest.nodeset)}}
{{- template "elastic.nodeset" (list .  .Values.coord.nodeset)}}
{{- template "elastic.nodeset" (list .  .Values.ml.nodeset)}}
{{- template "elastic.nodeset" (list .  .Values.transform.nodeset)}}
{{ end }}


{{- define "elastic.spec" }}
spec:
  version: {{ .Values.elastic.config.version }}

{{- template "elastic.securesettings" . }}

{{- template "elastic.nodesets" .}}

{{ end }}