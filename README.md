# flux-elastic

Add these to the bootstrap repo

```
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: flux-elastic-clusters
  namespace: flux-system
spec:
  dependsOn:
    - name: flux-elastic-infrastructure  
  interval: 1m0s
  path: ./clusters/
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-elastic


apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: flux-elastic-infrastructure
  namespace: flux-system
spec:
  interval: 1m0s
  path: ./infrastructure/
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-elastic


---
apiVersion: source.toolkit.fluxcd.io/v1beta1
kind: GitRepository
metadata:
  name: flux-elastic
  namespace: flux-system
spec:
  interval: 1m0s
  ref:
    branch: main
  url: https://github.com/deckkh/flux-elastic
```
