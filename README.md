<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://steampipe.io/images/steampipe-color-logo-and-wordmark-with-white-bubble.svg">
  <source media="(prefers-color-scheme: light)" srcset="https://steampipe.io/images/steampipe-color-logo-and-wordmark-with-white-bubble.svg">
  <img width="55%" alt="Steampipe Logo" src="https://steampipe.io/images/steampipe-color-logo-and-wordmark-with-white-bubble.svg">
</picture>

# Helm Chart for Steampipe

> **`select * from cloud;` — now running in your cluster.**

[![Release](https://img.shields.io/github/v/release/devops-ia/helm-steampipe?label=helm%20chart&color=blue)](https://github.com/devops-ia/helm-steampipe/releases)
[![Steampipe](https://img.shields.io/badge/steampipe-2.4.1-green)](https://github.com/turbot/steampipe/releases)
[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/helm-steampipe)](https://artifacthub.io/packages/helm/helm-steampipe/steampipe)
[![Lint](https://github.com/devops-ia/helm-steampipe/actions/workflows/helm-lint-test.yml/badge.svg)](https://github.com/devops-ia/helm-steampipe/actions/workflows/helm-lint-test.yml)
[![License](https://img.shields.io/github/license/devops-ia/helm-steampipe)](LICENSE)

[Steampipe](https://steampipe.io) is **the zero-ETL way to query APIs and services with SQL**. This Helm chart deploys Steampipe on Kubernetes as a persistent service, exposing a PostgreSQL-compatible endpoint — available to every workload in your cluster, all the time.

## Why run Steampipe on Kubernetes?

| Benefit | Description |
|---------|-------------|
| 🔄 **Always-on** | Persistent service mode — no cold start, always ready to query |
| 🌐 **Cluster-wide access** | Any pod can connect to the built-in PostgreSQL endpoint |
| 🔐 **Enterprise auth** | Optional OAuth2 Proxy integration (OIDC, Google, GitHub, Keycloak…) |
| ☁️ **Multi-cloud at once** | Query AWS, GCP, Azure, Kubernetes — all from a single endpoint |
| 🔌 **BI tool friendly** | Connect Grafana, Metabase, or any PostgreSQL client directly |

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Kubernetes Cluster                                          │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Steampipe Pod                                        │   │
│  │                                                       │   │
│  │  ┌─────────────┐   ┌──────────────────────────────┐  │   │
│  │  │ initContainer│   │  steampipe container         │  │   │
│  │  │              │   │                              │  │   │
│  │  │ plugin install│  │  :9193 PostgreSQL endpoint   │  │   │
│  │  └──────────────┘   └──────────────────────────────┘  │   │
│  └──────────────────────────────────────────────────────┘   │
│                              │                               │
│  ┌───────────┐               │ postgres://                   │
│  │  Service  │               │                               │
│  │ ClusterIP │◀──────────────┘                               │
│  │  :9193    │                                               │
│  └─────┬─────┘                                               │
│        │                                                     │
│        ├──────────────▶  Grafana / psql / BI tools           │
│        │                                                     │
│  ┌─────▼──────────────────────────────────────────────┐     │
│  │  Powerpipe Pod (optional)                           │     │
│  │                                                     │     │
│  │  ┌──────────────┐   ┌───────────────────────────┐  │     │
│  │  │ initContainer │   │  powerpipe container      │  │     │
│  │  │               │   │                           │  │     │
│  │  │ mod install   │   │  :9033 HTTP dashboard     │  │     │
│  │  └───────────────┘   └───────────────────────────┘  │     │
│  └─────────────────────────────────────────────────────┘     │
│                              │                               │
│  ┌───────────┐   ┌──────────▼───┐   ┌───────────────────┐   │
│  │  Service  │   │   Ingress    │   │  oauth2-proxy     │   │
│  │ ClusterIP │   │  (HTTP ✅)   │   │  (optional)       │   │
│  │  :9033    │   │              │   │  OIDC / Google /  │   │
│  └───────────┘   └──────────────┘   │  GitHub / Keycloak│   │
│                                     └───────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Quick Start

### Prerequisites

- Kubernetes `1.21+`
- Helm `3.9+`

### 1 — Minimal install (no plugins)

```console
helm repo add helm-steampipe https://devops-ia.github.io/helm-steampipe
helm repo update
helm install steampipe helm-steampipe/steampipe
```

### 2 — Install with plugins (AWS + Kubernetes)

```console
helm install steampipe helm-steampipe/steampipe \
  --set initContainer.plugins[0]=aws \
  --set initContainer.plugins[1]=kubernetes
```

### 3 — Setup with OAuth2 Proxy

```console
helm install steampipe helm-steampipe/steampipe \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=steampipe.example.com \
  --set "ingress.hosts[0].paths[0].path=/" \
  --set oauth2Proxy.enabled=true \
  --set initContainer.plugins[0]=aws \
  --set initContainer.plugins[1]=kubernetes
```

## Real-World Examples

### Query AWS from your cluster

```yaml
# values-aws.yaml
initContainer:
  plugins:
    - aws

extraConfig:
  secrets:
    enabled: true
    config:
      - name: aws-credentials
        type: Opaque
        data:
          aws.spc: |
            connection "aws" {
              plugin  = "aws"
              regions = ["us-east-1", "eu-west-1"]
            }

extraVolumeMount:
  - name: aws-credentials
    mountPath: /home/steampipe/.steampipe/config/aws.spc
    subPath: aws.spc
    readOnly: true

extraVolumes:
  - name: aws-credentials
    secret:
      secretName: aws-credentials
```

```console
helm install steampipe helm-steampipe/steampipe -f values-aws.yaml
```

Then connect from any pod in your cluster:

```console
psql -h steampipe -p 9193 -U steampipe steampipe
steampipe=> select instance_id, instance_type, region from aws_ec2_instance limit 10;
```

### Query Kubernetes resources with SQL

```yaml
# values-k8s.yaml
initContainer:
  plugins:
    - kubernetes

serviceAccount:
  create: true
  annotations:
    # For GKE Workload Identity, add: iam.gke.io/gcp-service-account: ...
```

```console
helm install steampipe helm-steampipe/steampipe -f values-k8s.yaml
```

```sql
-- How many pods are running per namespace?
select namespace, count(*) as pod_count
from kubernetes_pod
where phase = 'Running'
group by namespace
order by pod_count desc;
```

### Multi-cloud: AWS + GCP + Azure

```yaml
# values-multicloud.yaml
initContainer:
  plugins:
    - aws
    - gcp
    - azure

extraConfig:
  secrets:
    enabled: true
    config:
      - name: cloud-connections
        type: Opaque
        data:
          aws.spc: |
            connection "aws" {
              plugin  = "aws"
              regions = ["*"]
            }
          gcp.spc: |
            connection "gcp" {
              plugin  = "gcp"
            }
          azure.spc: |
            connection "azure" {
              plugin = "azure"
            }

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

extraVolumes:
  - name: cloud-connections
    secret:
      secretName: cloud-connections
```

### Connect Grafana (or any BI tool) to Steampipe

Steampipe exposes a PostgreSQL-compatible endpoint on port `9193`. Connect any BI tool that supports PostgreSQL:

| Tool | Connection string |
|------|-------------------|
| Grafana | `Host: steampipe:9193`, `Database: steampipe`, `User: steampipe` |
| Metabase | PostgreSQL connection → `steampipe:9193` |
| DBeaver | PostgreSQL driver → `jdbc:postgresql://steampipe:9193/steampipe` |
| psql | `psql -h steampipe -p 9193 -U steampipe steampipe` |

Enable the PostgreSQL service in your values:

```yaml
bbdd:
  enabled: true
  port: 9193
  listen: network
```

### Protect access with OAuth2 Proxy (Keycloak / Google / GitHub)

Steampipe v2 has no built-in authentication. Use [oauth2-proxy](https://oauth2-proxy.github.io/oauth2-proxy/) to add OIDC/OAuth2 authentication in front of it. See the [oauth2-proxy provider docs](https://oauth2-proxy.github.io/oauth2-proxy/configuration/providers/) for all supported identity providers.

> ⚠️ **Ingress note:** Steampipe exposes a PostgreSQL (TCP) endpoint, not HTTP. Standard Kubernetes Ingress (L7) will not proxy PostgreSQL traffic. Use a TCP-capable Ingress controller (e.g., NGINX TCP passthrough, Traefik `IngressRouteTCP`) or a `LoadBalancer` service (`bbdd.serviceType: LoadBalancer`).

```yaml
# values-oauth2.yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: steampipe.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: steampipe-tls
      hosts:
        - steampipe.example.com

oauth2Proxy:
  enabled: true
  config:
    clientID: "YOUR_CLIENT_ID"
    clientSecret: "YOUR_CLIENT_SECRET"
    cookieSecret: "RANDOM_32_BYTE_BASE64"
    configFile: |
      email_domains = [ "yourcompany.com" ]
      provider = "oidc"
      oidc_issuer_url = "https://keycloak.example.com/realms/myrealm"
```

## Plugins

Browse the full plugin catalog at [hub.steampipe.io/plugins](https://hub.steampipe.io/plugins) — 100+ providers available.

### Popular plugins

| Plugin | Install | Description |
|--------|---------|-------------|
| [AWS](https://hub.steampipe.io/plugins/turbot/aws) | `aws` | 400+ tables for EC2, S3, IAM, RDS, and more |
| [GCP](https://hub.steampipe.io/plugins/turbot/gcp) | `gcp` | Compute, Storage, BigQuery, GKE, IAM |
| [Azure](https://hub.steampipe.io/plugins/turbot/azure) | `azure` | Virtual Machines, Storage, AKS, Entra ID |
| [Kubernetes](https://hub.steampipe.io/plugins/turbot/kubernetes) | `kubernetes` | Pods, Deployments, Services, RBAC |
| [GitHub](https://hub.steampipe.io/plugins/turbot/github) | `github` | Repos, PRs, Issues, Actions, Secrets |
| [Terraform](https://hub.steampipe.io/plugins/turbot/terraform) | `terraform` | Parse Terraform state and HCL files |
| [Datadog](https://hub.steampipe.io/plugins/turbot/datadog) | `datadog` | Monitors, dashboards, logs, metrics |

### Install plugins via Helm

```yaml
initContainer:
  plugins:
    - aws
    - gcp
    - kubernetes
    - github
```

> **Mods** are no longer managed by Steampipe v2. Use [Powerpipe](https://powerpipe.io) to install and run compliance and insights mods.

## Powerpipe Integration

[Powerpipe](https://powerpipe.io) provides **dashboards, benchmarks, and compliance checks** on top of Steampipe's SQL engine. This chart can deploy Powerpipe as a separate pod that connects to Steampipe's PostgreSQL endpoint.

### Quick start — AWS compliance

```yaml
# values-powerpipe.yaml
initContainer:
  plugins:
    - aws

bbdd:
  enabled: true
  listen: "network"

env:
  - name: STEAMPIPE_DATABASE_PASSWORD
    valueFrom:
      secretKeyRef:
        name: steampipe-password
        key: password

powerpipe:
  enabled: true
  image:
    repository: ghcr.io/turbot/powerpipe
    tag: "latest"
  mods:
    - github.com/turbot/steampipe-mod-aws-compliance
  env:
    - name: STEAMPIPE_DATABASE_PASSWORD
      valueFrom:
        secretKeyRef:
          name: steampipe-password
          key: password
  ingress:
    enabled: true
    className: nginx
    hosts:
      - host: powerpipe.example.com
        paths:
          - path: /
            pathType: Prefix
```

```console
kubectl create secret generic steampipe-password --from-literal=password=your-secure-password
helm install steampipe helm-steampipe/steampipe -f values-powerpipe.yaml
```

Then visit `https://powerpipe.example.com` to run compliance benchmarks in your browser.

### Available mods

Browse the full catalog at [hub.powerpipe.io/mods](https://hub.powerpipe.io/mods):

| Mod | Description |
|-----|-------------|
| `steampipe-mod-aws-compliance` | CIS, PCI DSS, HIPAA, SOC 2 for AWS |
| `steampipe-mod-aws-well-architected` | AWS Well-Architected Framework checks |
| `steampipe-mod-kubernetes-compliance` | NSA, CIS benchmarks for Kubernetes |
| `steampipe-mod-azure-compliance` | CIS, HIPAA, NIST for Azure |
| `steampipe-mod-gcp-compliance` | CIS, NIST for Google Cloud |
| `steampipe-mod-terraform-aws-compliance` | Security checks for Terraform AWS configs |

> **Note:** Powerpipe's Ingress is standard HTTP (L7) — it works with any Kubernetes Ingress controller. Unlike Steampipe's PostgreSQL endpoint, no TCP passthrough is needed.

## Automatic Updates

This chart is kept up-to-date automatically:

| Tool | What it updates | Schedule |
|------|-----------------|----------|
| [updatecli](https://www.updatecli.io/) | `appVersion` when Steampipe releases a new version | Daily |
| [updatecli](https://www.updatecli.io/) | `powerpipe.image.tag` when Powerpipe releases a new version | Daily |
| [updatecli](https://www.updatecli.io/) | Helm dependency versions — oauth2-proxy (minor) | Weekly |
| [updatecli](https://www.updatecli.io/) | Helm dependency versions — oauth2-proxy (major) | Monthly |
| [Dependabot](https://docs.github.com/en/code-security/dependabot) | GitHub Actions & npm dependencies | Monthly |

## Chart Documentation

For full configuration reference, see the [chart README](charts/steampipe/README.md).

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feat/my-feature`)
3. Commit your changes following [Conventional Commits](https://www.conventionalcommits.org/)
4. Open a Pull Request

See [TESTING.md](TESTING.md) for how to run lint and tests locally.

Found a bug? [Open an issue](https://github.com/devops-ia/helm-steampipe/issues/new).

## License

[Apache 2.0](LICENSE) © [devops-ia](https://github.com/devops-ia)

---

<p align="center">
  Built with ❤️ for the <a href="https://turbot.com/community/join">Steampipe community</a>
</p>
