# steampipe

A Helm chart for Kubernetes to deploy Steampipe

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| amartingarcia | <adrianmg231189@gmail.com> |  |
| ialejandro | <hello@ialejandro.rocks> |  |

## TL;DR

```console
helm repo add steampipe https://devops-ia.github.io/helm-steampipe
helm install my-steampipe steampipe/steampipe
```

## Prerequisites

* Helm 3+
* Kubernetes 1.25+
* A cloud provider credential (AWS IAM, GCP SA, Azure SP, etc.) in a Kubernetes Secret

## Add repository

```console
helm repo add steampipe https://devops-ia.github.io/helm-steampipe
helm repo update
```

## Install (repository mode)

```console
helm install [RELEASE_NAME] steampipe/steampipe
```

_See [helm install](https://helm.sh/docs/helm/helm_install/) for command documentation._

## Install (OCI mode)

```console
helm install [RELEASE_NAME] oci://ghcr.io/devops-ia/helm-steampipe/steampipe --version=[version]
```

## Uninstall

```console
helm uninstall [RELEASE_NAME]
```

_See [helm uninstall](https://helm.sh/docs/helm/helm_uninstall/) for command documentation._

---

## How it works

The chart deploys Steampipe in **service mode** — a persistent PostgreSQL endpoint (port 9193) that any Postgres-compatible client can query. An init container pre-installs the plugins you declare in `values.yaml` before the main process starts.

```
┌─────────────────────────────────────────────────────────────────┐
│ Pod                                                             │
│                                                                 │
│  ┌─────────────────┐      ┌────────────────────────────────┐   │
│  │  initContainer  │      │  steampipe container           │   │
│  │                 │      │                                │   │
│  │ plugin install  │ ───▶ │  steampipe service start       │   │
│  └─────────────────┘      │  --foreground                  │   │
│      (emptyDir)           │  --database-listen network     │   │
│                           │  port: 9193 (PostgreSQL)       │   │
│                           └────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

Plugin config files (`.spc`) are mounted from Kubernetes Secrets or ConfigMaps into `/home/steampipe/.steampipe/config/` via `extraVolumes` / `extraVolumeMount`.

---

## Examples

### 1 — Minimal (no plugins, port-forward only)

```console
helm install steampipe steampipe/steampipe
kubectl port-forward svc/steampipe-psql 9193:9193
psql -h localhost -p 9193 -U steampipe
```

### 2 — AWS plugin with IAM credentials

Create a Kubernetes Secret containing the connection file:

```console
kubectl create secret generic aws-credentials \
  --from-literal=aws.spc='connection "aws" {
  plugin     = "aws"
  access_key = "AKIAIOSFODNN7EXAMPLE"
  secret_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
  regions    = ["us-east-1", "us-west-2"]
}'
```

Then in `values.yaml`:

```yaml
initContainer:
  plugins:
    - aws

bbdd:
  enabled: true

extraVolumes:
  - name: aws-credentials
    secret:
      secretName: aws-credentials

extraVolumeMount:
  - name: aws-credentials
    mountPath: /home/steampipe/.steampipe/config/aws.spc
    subPath: aws.spc
    readOnly: true
```

Then query:

```sql
SELECT account_id, region, instance_id, instance_type
FROM aws_ec2_instance
WHERE instance_state = 'running'
ORDER BY region;
```

### 3 — Kubernetes plugin (in-cluster)

```yaml
serviceAccount:
  create: true
  automountServiceAccountToken: true

initContainer:
  plugins:
    - kubernetes

bbdd:
  enabled: true

extraVolumes:
  - name: k8s-connection
    configMap:
      name: k8s-connection

extraVolumeMount:
  - name: k8s-connection
    mountPath: /home/steampipe/.steampipe/config/kubernetes.spc
    subPath: kubernetes.spc
    readOnly: true
```

Create the ConfigMap separately:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: k8s-connection
data:
  kubernetes.spc: |
    connection "kubernetes" {
      plugin = "kubernetes"
    }
```

```sql
-- Pods not in Running state
SELECT namespace, name, phase, node_name
FROM kubernetes_pod
WHERE phase != 'Running'
ORDER BY namespace, name;
```

### 4 — Multi-cloud (AWS + GCP + Azure)

Create a Secret with all connection files, then mount them:

```yaml
initContainer:
  plugins:
    - aws
    - gcp
    - azure

bbdd:
  enabled: true

extraVolumes:
  - name: cloud-connections
    secret:
      secretName: cloud-connections

extraVolumeMount:
  - name: cloud-connections
    mountPath: /home/steampipe/.steampipe/config/aws.spc
    subPath: aws.spc
    readOnly: true
  - name: cloud-connections
    mountPath: /home/steampipe/.steampipe/config/gcp.spc
    subPath: gcp.spc
    readOnly: true
  - name: cloud-connections
    mountPath: /home/steampipe/.steampipe/config/azure.spc
    subPath: azure.spc
    readOnly: true
```

### 5 — Stable database password via Secret

By default Steampipe generates a random password on each start. Set a stable one:

```console
kubectl create secret generic steampipe-password --from-literal=password=your-stable-password
```

```yaml
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
```

### 6 — Connect from Grafana or BI tools

Steampipe exposes a standard PostgreSQL interface. Point any Postgres datasource to:

| Field    | Value                                         |
|----------|-----------------------------------------------|
| Host     | `<release-name>-psql.<namespace>.svc`         |
| Port     | `9193`                                        |
| Database | `steampipe`                                   |
| Username | `steampipe`                                   |
| Password | value of `STEAMPIPE_DATABASE_PASSWORD`        |
| SSL Mode | `disable` (within cluster)                    |

---

## Environment Variables Reference

Steampipe v2.x recognizes the following environment variables. Set them via `env:` in your `values.yaml`:

| Variable | Description | Default |
|----------|-------------|---------|
| `STEAMPIPE_DATABASE_PASSWORD` | Set a stable password for the PostgreSQL endpoint. Without this, Steampipe generates a random password on each start. | _(random)_ |
| `STEAMPIPE_UPDATE_CHECK` | Enable or disable automatic update checks. Set to `false` in Kubernetes. | `true` |
| `STEAMPIPE_TELEMETRY` | Telemetry level: `info` or `none`. Set to `none` in production. | `info` |
| `STEAMPIPE_CACHE` | Enable or disable query caching. | `true` |
| `STEAMPIPE_CACHE_TTL` | Cache time-to-live in seconds. | `300` |
| `STEAMPIPE_CACHE_MAX_SIZE_MB` | Maximum cache size in MB. | _(unlimited)_ |
| `STEAMPIPE_MAX_PARALLEL` | Maximum number of parallel plugin queries. | `10` |
| `STEAMPIPE_MEMORY_MAX_MB` | Maximum memory usage in MB before Steampipe applies back-pressure. | _(system dependent)_ |
| `STEAMPIPE_QUERY_TIMEOUT` | Query timeout in seconds. | `240` |
| `STEAMPIPE_INTROSPECTION` | Enable introspection tables (`info` or `none`). | `none` |
| `STEAMPIPE_INSTALL_DIR` | Override the Steampipe installation directory. | `/home/steampipe/.steampipe` |

> **Ref:** [Steampipe environment variables](https://steampipe.io/docs/reference/env-vars)

### Recommended Kubernetes configuration

```yaml
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
```

---

## Plugin Configuration Guide

Steampipe plugins are declared in `initContainer.plugins[]` and installed automatically before the main container starts. Each plugin requires a connection configuration file (`.spc`) mounted into the container.

### Step 1 — Declare plugins

```yaml
initContainer:
  plugins:
    - aws
    - kubernetes
```

### Step 2 — Create connection files as Kubernetes Secrets or ConfigMaps

Each plugin needs a `.spc` file defining connection parameters. Create them as Kubernetes Secrets (with credentials) or ConfigMaps (for non-sensitive config):

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: steampipe-connections
type: Opaque
stringData:
  aws.spc: |
    connection "aws" {
      plugin  = "aws"
      regions = ["us-east-1"]
    }
```

### Step 3 — Mount into the config directory

```yaml
extraVolumes:
  - name: steampipe-connections
    secret:
      secretName: steampipe-connections

extraVolumeMount:
  - name: steampipe-connections
    mountPath: /home/steampipe/.steampipe/config/aws.spc
    subPath: aws.spc
    readOnly: true
```

### Using cloud provider workload identity (recommended)

Instead of embedding credentials in `.spc` files, use workload identity:

- **AWS (IRSA):** Annotate the ServiceAccount with the IAM role ARN. The `aws` plugin auto-detects IRSA credentials.
- **GCP (Workload Identity):** Annotate the ServiceAccount with the GCP SA email. The `gcp` plugin uses Application Default Credentials.
- **Azure (Workload Identity):** Configure the Azure Workload Identity webhook. The `azure` plugin reads from projected tokens.

```yaml
serviceAccount:
  create: true
  annotations:
    # AWS IRSA
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/steampipe-role
    # or GCP Workload Identity
    # iam.gke.io/gcp-service-account: steampipe@project.iam.gserviceaccount.com
```

### Available plugins

Steampipe supports 140+ plugins. See the [Steampipe Hub](https://hub.steampipe.io/plugins) for the full catalog, including:

| Plugin | Use case |
|--------|----------|
| `aws` | Query 300+ AWS resource types |
| `gcp` | Google Cloud Platform resources |
| `azure` | Microsoft Azure resources |
| `kubernetes` | In-cluster and multi-cluster K8s queries |
| `github` | Repositories, PRs, issues, actions |
| `terraform` | Parse and query Terraform state/plans |
| `csv` | Query local CSV files as SQL tables |
| `net` | DNS, TLS certificates, network diagnostics |
| `exec` | Execute commands and query the output |

---

## Troubleshooting

### Pod stuck in CrashLoopBackOff

**Symptom:** The pod starts but immediately crashes.

**Common causes:**
1. **Plugin install failure:** Check init container logs:
   ```console
   kubectl logs <pod-name> -c init
   ```
   Verify plugin names match [Steampipe Hub](https://hub.steampipe.io/plugins).

2. **Permission denied:** Steampipe requires UID 9193, GID 0. Ensure your security policy allows:
   ```yaml
   podSecurityContext:
     fsGroup: 9193
     runAsUser: 9193
     runAsGroup: 0
   ```

3. **Invalid .spc file:** Check the main container logs for plugin load errors:
   ```console
   kubectl logs <pod-name> -c steampipe
   ```

### Cannot connect to PostgreSQL

**Symptom:** `psql` or client connections timeout or are refused.

**Checklist:**
1. Ensure `bbdd.enabled: true` is set — without it, no Service is created.
2. Verify the service exists: `kubectl get svc | grep psql`
3. Check `bbdd.listen` is set to `"network"` (not `"local"`).
4. For port-forward: `kubectl port-forward svc/<release>-psql 9193:9193`
5. Default username is `steampipe`, database is `steampipe`.

### Ingress not working

**Symptom:** HTTP connections via Ingress fail or return 502.

**Root cause:** Steampipe speaks PostgreSQL (TCP), not HTTP. Standard Kubernetes Ingress resources operate at L7 (HTTP/HTTPS) and cannot proxy TCP traffic.

**Solutions:**
- Use a `LoadBalancer` service instead: set `bbdd.serviceType: LoadBalancer`
- Use NGINX Ingress Controller TCP passthrough: configure via `tcp-services` ConfigMap
- Use Traefik `IngressRouteTCP` CRD

### Random password changes on restart

**Symptom:** Client connections break after pod restarts.

**Fix:** Set a stable password:
```yaml
env:
  - name: STEAMPIPE_DATABASE_PASSWORD
    valueFrom:
      secretKeyRef:
        name: steampipe-password
        key: password
```

### Plugins not available after restart

**Symptom:** Plugins work initially but queries fail after pod restart.

**Explanation:** Plugins are stored in an `emptyDir` volume. They are reinstalled by the init container on every pod start. This is by design — it ensures plugin versions stay current. If the init container fails, plugins won't be available.

---

## Upgrading

### v3.x → v4.0.0

**Breaking changes:**

| Change | Migration action |
|--------|-----------------|
| `powerpipe.*` removed | Powerpipe is now a separate Helm chart. Remove `powerpipe.*` from values. |
| `oauth2Proxy.*` / `oauth2-proxy` sub-chart removed | Manage authentication externally. Remove `oauth2Proxy.*` from values. |
| `extraConfig.*` removed | Use `extraVolumes` + `extraVolumeMount` with standard Kubernetes Secrets/ConfigMaps instead. |
| `dashboard.*` removed | Already removed in v2. If still present, remove. |
| `initContainer.image.repository` / `initContainer.image.tag` removed | Init container now uses the same image as the main container automatically. |
| Image registry changed | Changed from `ghcr.io/turbot/steampipe` to `ghcr.io/devops-ia/steampipe`. |

**Migration steps:**

1. Back up current values:
   ```console
   helm get values my-steampipe > values-backup.yaml
   ```

2. Remove deprecated fields:
   - Delete `powerpipe.*` section entirely
   - Delete `oauth2Proxy.*` and `oauth2-proxy.*` sections
   - Delete `extraConfig.*` section
   - Delete `initContainer.image.repository` and `initContainer.image.tag`

3. Migrate `extraConfig` Secrets/ConfigMaps to standard Kubernetes resources + `extraVolumes`/`extraVolumeMount`:
   ```yaml
   # Before (v3):
   extraConfig:
     secrets:
       enabled: true
       config:
         - name: aws-credentials
           data:
             aws.spc: |
               connection "aws" { plugin = "aws" }

   # After (v4): create the Secret separately, then:
   extraVolumes:
     - name: aws-credentials
       secret:
         secretName: aws-credentials
   extraVolumeMount:
     - name: aws-credentials
       mountPath: /home/steampipe/.steampipe/config/aws.spc
       subPath: aws.spc
       readOnly: true
   ```

4. Upgrade:
   ```console
   helm upgrade my-steampipe steampipe/steampipe -f values.yaml
   ```

### v2.x → v3.0.0

Powerpipe was integrated in v3. Powerpipe has since been extracted to a standalone chart (v4+).

### v1.x → v2.0.0

**Breaking changes:**

| Change | Migration action |
|--------|-----------------|
| `dashboard` removed | Remove `dashboard.*` from values. |
| `mods` removed | Remove `initContainer.mods[]`. |
| Default service type | `bbdd.serviceType` changed from `LoadBalancer` to `ClusterIP`. |
| `--show-password` removed | Use `STEAMPIPE_DATABASE_PASSWORD` env var. |
| `runAsGroup` corrected | Changed to `0` (OpenShift compatible). |

---

## Configuration

See [Customizing the chart before installing](https://helm.sh/docs/intro/using_helm/#customizing-the-chart-before-installing). To see all configurable options:

```console
helm show values steampipe/steampipe
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Affinity for pod assignment |
| args | list | `["--foreground"]` | Arguments for Pod Only --foreground is required. Use STEAMPIPE_DATABASE_PASSWORD env var (via a Kubernetes Secret) to set a stable password instead of relying on the random one. |
| bbdd | object | `{"enabled":false,"listen":"network","port":9193,"serviceType":"ClusterIP","svcAnnotations":{}}` | Configure BBDD (database) endpoint for Steampipe When enabled, creates a ClusterIP service on the PostgreSQL port (9193) so other pods can connect using any PostgreSQL-compatible client. |
| bbdd.serviceType | string | `"ClusterIP"` | Service type for the bbdd service. ClusterIP is recommended for internal access; use LoadBalancer or NodePort only if external access is required. |
| command | list | `[]` | Command for Pod |
| deploymentAnnotations | object | `{}` | Deployment annotations |
| env | list | `[{"name":"STEAMPIPE_UPDATE_CHECK","value":"false"},{"name":"STEAMPIPE_TELEMETRY","value":"none"}]` | Environment variables to configure application STEAMPIPE_UPDATE_CHECK and STEAMPIPE_TELEMETRY are recommended for Kubernetes deployments Ref: https://steampipe.io/docs/reference/env-vars/overview |
| envFrom | list | `[]` | Variables from file |
| extraContainers | list | `[]` | Extra containers to add to the pod |
| extraObjects | list | `[]` | Extra Kubernetes manifests to deploy |
| extraVolumeMount | list | `[]` | Mount extra volumes |
| extraVolumes | list | `[]` | Reference volumes Use this to mount plugin connection configs (.spc files) into /home/steampipe/.steampipe/config/ |
| fullnameOverride | string | `""` | String to fully override steampipe.fullname template |
| image | object | `{"pullPolicy":"IfNotPresent","repository":"ghcr.io/devops-ia/steampipe","tag":""}` | Image registry |
| imagePullSecrets | list | `[]` | Registry secret names as an array |
| ingress | object | `{"annotations":{},"className":"","enabled":false,"hosts":[{"host":"chart-example.local","paths":[{"path":"/","pathType":"ImplementationSpecific","port":9193}]}],"tls":[]}` | Ingress configuration to expose app ⚠️  WARNING: Steampipe exposes a PostgreSQL endpoint (TCP), NOT HTTP. Standard Kubernetes Ingress operates at L7 (HTTP/HTTPS) and will NOT work for PostgreSQL connections. You need a TCP-capable Ingress controller:   - NGINX: use TCP services ConfigMap (https://kubernetes.github.io/ingress-nginx/user-guide/exposing-tcp-udp-services/)   - Traefik: use IngressRouteTCP CRD   - HAProxy: supports TCP mode natively For most use cases, a ClusterIP or LoadBalancer service (bbdd.serviceType) is simpler. |
| initContainer | object | `{"extraInitVolumeMount":[],"image":{"pullPolicy":"IfNotPresent"},"plugins":[],"resources":{},"securityContext":{"runAsNonRoot":true,"runAsUser":9193}}` | Configure initContainers The init container installs Steampipe plugins before the main container starts. It uses the same image (repository + tag) as the main container to ensure CLI compatibility. |
| initContainer.plugins | list | `[]` | Configure Steampipe plugins to install Ref: https://hub.steampipe.io/plugins |
| initContainer.resources | object | `{}` | The resources limits and requested |
| livenessProbe | object | `{}` | Configure liveness probe Ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/ |
| nameOverride | string | `""` | String to partially override steampipe.fullname template (will maintain the release name) |
| nodeSelector | object | `{}` | Node labels for pod assignment |
| podAnnotations | object | `{}` | Pod annotations |
| podLabels | object | `{}` | Pod labels |
| podSecurityContext | object | `{"fsGroup":9193,"runAsGroup":0,"runAsUser":9193}` | Privilege and access control settings for a Pod or Container Steampipe runs as UID=9193, GID=0 (root group for OpenShift compatibility) |
| readinessProbe | object | `{}` | Configure readinessProbe Ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/ |
| replicaCount | int | `1` | Number of replicas |
| resources | object | `{}` | The resources limits and requested |
| securityContext | object | `{"runAsNonRoot":true,"runAsUser":9193}` | Privilege and access control settings |
| serviceAccount | object | `{"annotations":{},"automountServiceAccountToken":false,"create":true,"name":""}` | Enable creation of ServiceAccount |
| startupProbe | object | `{}` | Configure startupProbe Ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/ |
| tolerations | list | `[]` | Tolerations for pod assignment |
| topologySpreadConstraints | list | `[]` | Topology spread constraints for pod assignment Ref: https://kubernetes.io/docs/concepts/workloads/pods/pod-topology-spread-constraints/ |
