# Installation

## Prerequisites

- Helm 3.8+
- Kubernetes 1.25+
- `kubectl` configured against your cluster

## Install from Helm repository

```bash
# Add the Helm repository
helm repo add steampipe https://devops-ia.github.io/helm-steampipe
helm repo update

# Install with default settings (no plugins, no service exposed)
helm install steampipe steampipe/steampipe --namespace steampipe --create-namespace

# Verify the pod is running
kubectl get pods -n steampipe -l app.kubernetes.io/name=steampipe
```

## Install from OCI registry

```bash
# Install specific version directly from GitHub Container Registry
helm install steampipe oci://ghcr.io/devops-ia/helm-steampipe/steampipe \
  --version 2.4.1 \
  --namespace steampipe \
  --create-namespace

# List available versions
helm show chart oci://ghcr.io/devops-ia/helm-steampipe/steampipe
```

## Minimal install with database service enabled

```bash
helm install steampipe steampipe/steampipe \
  --namespace steampipe \
  --create-namespace \
  --set bbdd.enabled=true \
  --set bbdd.listen=network

# Port-forward to connect locally
kubectl port-forward -n steampipe svc/steampipe-psql 9193:9193 &

# Connect with psql (default user/db: steampipe)
psql -h localhost -p 9193 -U steampipe steampipe
```

## Install with a values file

```bash
# Preview default values
helm show values steampipe/steampipe > values.yaml

# Install with your custom values
helm install steampipe steampipe/steampipe \
  --namespace steampipe \
  --create-namespace \
  -f values.yaml
```

## Dry-run before applying

Always preview what will be rendered before installing in production:

```bash
# Render templates without applying
helm install steampipe steampipe/steampipe \
  --namespace steampipe \
  --dry-run --debug \
  -f values.yaml

# Diff an upgrade against the running release (requires helm-diff plugin)
helm diff upgrade steampipe steampipe/steampipe \
  --namespace steampipe \
  -f values.yaml
```

## Upgrade

```bash
# Update the Helm repository
helm repo update

# Check current values before upgrading
helm get values steampipe -n steampipe > current-values.yaml

# Upgrade preserving current values
helm upgrade steampipe steampipe/steampipe \
  --namespace steampipe \
  -f current-values.yaml

# Upgrade to a specific version
helm upgrade steampipe steampipe/steampipe \
  --namespace steampipe \
  --version 2.5.0 \
  -f current-values.yaml

# Monitor the rollout
kubectl rollout status deployment/steampipe -n steampipe
```

## Uninstall

```bash
helm uninstall steampipe --namespace steampipe

# Clean up secrets and configmaps created separately
kubectl delete secret steampipe-password -n steampipe --ignore-not-found
kubectl delete configmap steampipe-plugins -n steampipe --ignore-not-found
```

## Namespace-scoped RBAC

If you want to restrict Steampipe's service account to only the resources it needs (e.g. for the Kubernetes plugin):

```yaml
# rbac.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: steampipe-reader
rules:
  - apiGroups: [""]
    resources: ["pods", "services", "configmaps", "namespaces", "nodes", "serviceaccounts"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["apps"]
    resources: ["deployments", "replicasets", "daemonsets", "statefulsets"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["rbac.authorization.k8s.io"]
    resources: ["clusterroles", "clusterrolebindings", "roles", "rolebindings"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: steampipe-reader
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: steampipe-reader
subjects:
  - kind: ServiceAccount
    name: steampipe
    namespace: steampipe
```

```bash
# Apply RBAC and install chart with automount enabled
kubectl apply -f rbac.yaml

helm install steampipe steampipe/steampipe \
  --namespace steampipe \
  --set serviceAccount.automountServiceAccountToken=true \
  --set bbdd.enabled=true
```

## GitOps with ArgoCD

```yaml
# argocd-application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: steampipe
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://devops-ia.github.io/helm-steampipe
    chart: steampipe
    targetRevision: 2.4.1
    helm:
      releaseName: steampipe
      values: |
        bbdd:
          enabled: true
          listen: network
        initContainer:
          plugins:
            - aws
            - kubernetes
        env:
          - name: STEAMPIPE_DATABASE_PASSWORD
            valueFrom:
              secretKeyRef:
                name: steampipe-password
                key: password
          - name: STEAMPIPE_UPDATE_CHECK
            value: "false"
          - name: STEAMPIPE_TELEMETRY
            value: "none"
  destination:
    server: https://kubernetes.default.svc
    namespace: steampipe
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

## GitOps with Flux

```yaml
# flux-helmrelease.yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: steampipe
  namespace: steampipe
spec:
  interval: 10m
  chart:
    spec:
      chart: steampipe
      version: ">=2.0.0 <3.0.0"
      sourceRef:
        kind: HelmRepository
        name: steampipe
        namespace: flux-system
  values:
    bbdd:
      enabled: true
      listen: network
    initContainer:
      plugins:
        - aws
    env:
      - name: STEAMPIPE_DATABASE_PASSWORD
        valueFrom:
          secretKeyRef:
            name: steampipe-password
            key: password
```

```yaml
# flux-helmrepository.yaml
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  name: steampipe
  namespace: flux-system
spec:
  interval: 1h
  url: https://devops-ia.github.io/helm-steampipe
```

## Verify the installation

```bash
# Check pod is running
kubectl get pods -n steampipe

# Check service endpoints
kubectl get svc -n steampipe
# Expected: steampipe-psql with port 9193

# View init container logs (plugin installation)
kubectl logs -n steampipe -l app.kubernetes.io/name=steampipe -c init

# View main container logs
kubectl logs -n steampipe -l app.kubernetes.io/name=steampipe -c steampipe

# Run a test query
kubectl port-forward -n steampipe svc/steampipe-psql 9193:9193 &
psql -h localhost -p 9193 -U steampipe steampipe -c "SELECT 1 AS health_check;"
```
