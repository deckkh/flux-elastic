
{{- define "elastic.noderoles" }}
      node.roles: [{{ join "," .roles  }} ]
{{- end }}

{{- define "elastic.zoneawareness"}}
      cluster.routing.allocation.awareness.attributes: zone
      node.attr.zone: ${ZONE}
{{- end }}


{{- define "elastic.shared_cache"}}
      xpack.searchable.snapshot.shared_cache.size: {{ .shared_cache }}
{{- end }}

{{- define "elastic.mmap"}}
      node.store.allow_mmap: {{ .Values.production.enabled }}
{{ end }}

{{- define "elastic.oidc" }}
{{ if  .Values.oidc.enabled }}
      xpack.security.authc.realms.native.native1:
        order: 0
      xpack.security.authc.realms.oidc.myrealm:
        order: 1
        rp.client_id: "the_client_id"
        rp.response_type: code
        rp.redirect_uri: "https://kibana.example.org:5601/api/security/oidc/callback"
        op.issuer: "https://op.example.org"
        op.authorization_endpoint: "https://op.example.org/oauth2/v1/authorize"
        op.token_endpoint: "https://op.example.org/oauth2/v1/token"
        op.jwkset_path: "https://login.microsoftonline.com/3232323-5566-3333-123456789012/discovery/v2.0/keys" 
        op.userinfo_endpoint: "https://op.example.org/oauth2/v1/userinfo"
        op.endsession_endpoint: "https://op.example.org/oauth2/v1/logout"
        rp.post_logout_redirect_uri: "https://kibana.example.org:5601/security/logged_out"
        claims.principal: sub
        claims.groups: "{{ .Values.oidc.claimurl }}"
{{- end }}
{{- end }}


{{- define "elastic.config" }}
{{- $root := index . 0 -}}
{{- $local := index . 1 -}}
{{- template "elastic.mmap" $root }}
{{- template "elastic.zoneawareness" $local }}
{{- template "elastic.shared_cache" $local }}
{{- template "elastic.noderoles" $local }}
{{- template "elastic.oidc" $root }}
{{- end }}


{{- define "elastic.tolerations" }}
        tolerations:
          - key: myapp
            operator: Equal
            value: worker
            effect: NoSchedule          
{{- end }}


{{- define "elastic.nodeselector" }}
        nodeSelector:
          org.myorg.node-type/compute: "true" 
{{- end }}



{{- define "elastic.initcontainers"}}
        initContainers:
{{ if  .Values.production.enabled }}
        - name: sysctl
          securityContext:
            privileged: true
          command: ['sh', '-c', 'sysctl -w vm.max_map_count=262144']
{{ end }}

{{ if  .Values.oidc.enabled }}
        - name: elastic-internal-init-keystore
          env:
          - name: ZONE
            value: dummyzone
{{ end }}

{{- end}}

{{- define "elastic.containers"}}
        containers:
        - name: elasticsearch
          resources:
            limits:
              memory: {{ .limits.memory}}
              cpu: {{ .limits.cpu}}
            requests:
              memory: {{ .requests.memory}}
              cpu: {{ .requests.cpu}}        
          env:
          - name: ZONE
            value: dummyzone
{{- end}}

{{- define "elastic.securitycontext" }}
        securityContext: 
          runAsUser: 1000
          fsGroup: 1000
          runAsNonRoot: true
{{- end }}

{{- define "elastic.podtemplate" }}
{{- $root := index . 0 }}
{{- $local := index . 1 }}
    podTemplate:
      spec:
{{- template "elastic.nodeselector" $local }}
{{- template "elastic.tolerations" $local }}
{{- template "elastic.securitycontext" $local }}
{{- template "elastic.initcontainers" $root }}
{{- template "elastic.containers" $local }}
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

{{ if  .Values.oidc.enabled }}
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
