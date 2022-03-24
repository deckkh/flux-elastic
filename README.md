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

create multinode kind cluster

```
apiVersion: kind.x-k8s.io/v1alpha4
kind: Cluster
name: multi-node
nodes:
  - role: control-plane
  - role: worker
    kubeadmConfigPatches:
      - |
        kind: JoinConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "org.myorg.node-type/compute=true"
  - role: worker
    kubeadmConfigPatches:
      - |
        kind: JoinConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "org.myorg.node-type/highio=true"
```


```
# taint nodes

kubectl taint nodes multi-node-worker myapp=worker:NoSchedule
kubectl taint nodes multi-node-worker2 myapp=worker:NoSchedule

```
