# Plugin Configuration

Steampipe plugins are declared in `initContainer.plugins[]` and automatically installed by the init container before the main process starts. Each plugin requires a connection configuration file (`.spc`) mounted into `/home/steampipe/.steampipe/config/`.

## Quick reference

```yaml
# Minimal plugin setup
initContainer:
  plugins:
    - aws
    - gcp
    - azure
    - kubernetes
    - github
```

## ConfigMap vs Secret — when to use each

| Use case | Resource type |
|----------|---------------|
| Plugin config with **no credentials** (in-cluster auth, workload identity) | `ConfigMap` |
| Plugin config with **static credentials** (API keys, passwords) | `Secret` |
| Cloud provider credentials (access keys, service account keys) | `Secret` |

## AWS plugin

### Static credentials (via Secret)

```yaml
# aws-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: steampipe-aws
  namespace: steampipe
type: Opaque
stringData:
  aws.spc: |
    connection "aws" {
      plugin     = "aws"
      access_key = "AKIAIOSFODNN7EXAMPLE"
      secret_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
      regions    = ["us-east-1", "us-west-2", "eu-west-1"]
    }
```

```yaml
# values.yaml
initContainer:
  plugins:
    - aws

bbdd:
  enabled: true
  listen: network

extraVolumes:
  - name: aws-config
    secret:
      secretName: steampipe-aws

extraVolumeMount:
  - name: aws-config
    mountPath: /home/steampipe/.steampipe/config/aws.spc
    subPath: aws.spc
    readOnly: true
```

### IRSA (no credentials in .spc)

When using AWS IRSA, the `.spc` file needs no credentials — the plugin auto-detects them from the IRSA token:

```yaml
# aws-irsa-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: steampipe-aws-config
  namespace: steampipe
data:
  aws.spc: |
    connection "aws" {
      plugin  = "aws"
      regions = ["us-east-1", "us-west-2", "eu-west-1"]
    }
```

```yaml
# values.yaml
serviceAccount:
  create: true
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/steampipe-role

initContainer:
  plugins:
    - aws

extraVolumes:
  - name: aws-config
    configMap:
      name: steampipe-aws-config

extraVolumeMount:
  - name: aws-config
    mountPath: /home/steampipe/.steampipe/config/aws.spc
    subPath: aws.spc
    readOnly: true
```

### Multi-account aggregator

```yaml
# multi-account.spc
connection "aws_dev" {
  plugin  = "aws"
  profile = "dev"
  regions = ["us-east-1"]
}

connection "aws_prod" {
  plugin  = "aws"
  profile = "prod"
  regions = ["us-east-1", "eu-west-1", "ap-southeast-1"]
}

connection "aws_all" {
  plugin      = "aws"
  type        = "aggregator"
  connections = ["aws_dev", "aws_prod"]
}
```

## GCP plugin

### Service account key

```yaml
# gcp-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: steampipe-gcp
  namespace: steampipe
type: Opaque
stringData:
  gcp.spc: |
    connection "gcp" {
      plugin                 = "gcp"
      project                = "my-project-id"
      credentials            = "/var/secrets/gcp/service-account.json"
    }
```

```yaml
# values.yaml
initContainer:
  plugins:
    - gcp

extraVolumes:
  - name: gcp-credentials
    secret:
      secretName: gcp-service-account-key
  - name: gcp-config
    secret:
      secretName: steampipe-gcp

extraVolumeMount:
  - name: gcp-credentials
    mountPath: /var/secrets/gcp/service-account.json
    subPath: service-account.json
    readOnly: true
  - name: gcp-config
    mountPath: /home/steampipe/.steampipe/config/gcp.spc
    subPath: gcp.spc
    readOnly: true
```

### GCP Workload Identity (no key file)

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: steampipe-gcp-config
  namespace: steampipe
data:
  gcp.spc: |
    connection "gcp" {
      plugin  = "gcp"
      project = "my-project-id"
    }
```

```yaml
# values.yaml
serviceAccount:
  create: true
  annotations:
    iam.gke.io/gcp-service-account: steampipe@my-project.iam.gserviceaccount.com

initContainer:
  plugins:
    - gcp

extraVolumes:
  - name: gcp-config
    configMap:
      name: steampipe-gcp-config

extraVolumeMount:
  - name: gcp-config
    mountPath: /home/steampipe/.steampipe/config/gcp.spc
    subPath: gcp.spc
    readOnly: true
```

## Azure plugin

### Service principal

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: steampipe-azure
  namespace: steampipe
type: Opaque
stringData:
  azure.spc: |
    connection "azure" {
      plugin          = "azure"
      subscription_id = "00000000-0000-0000-0000-000000000000"
      tenant_id       = "00000000-0000-0000-0000-000000000000"
      client_id       = "00000000-0000-0000-0000-000000000000"
      client_secret   = "your-client-secret"
    }
```

### Azure Workload Identity (no client_secret)

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: steampipe-azure-config
  namespace: steampipe
data:
  azure.spc: |
    connection "azure" {
      plugin          = "azure"
      subscription_id = "00000000-0000-0000-0000-000000000000"
      tenant_id       = "00000000-0000-0000-0000-000000000000"
      client_id       = "00000000-0000-0000-0000-000000000000"
    }
```

```yaml
# values.yaml — Azure Workload Identity
serviceAccount:
  create: true
  annotations:
    azure.workload.identity/client-id: "00000000-0000-0000-0000-000000000000"
  labels:
    azure.workload.identity/use: "true"

podLabels:
  azure.workload.identity/use: "true"
```

## Kubernetes plugin

### In-cluster (queries the cluster Steampipe runs in)

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: steampipe-k8s-config
  namespace: steampipe
data:
  kubernetes.spc: |
    connection "kubernetes" {
      plugin = "kubernetes"
    }
```

```yaml
# values.yaml
serviceAccount:
  create: true
  automountServiceAccountToken: true

initContainer:
  plugins:
    - kubernetes

extraVolumes:
  - name: k8s-config
    configMap:
      name: steampipe-k8s-config

extraVolumeMount:
  - name: k8s-config
    mountPath: /home/steampipe/.steampipe/config/kubernetes.spc
    subPath: kubernetes.spc
    readOnly: true
```

### External cluster via kubeconfig

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: steampipe-k8s-external
  namespace: steampipe
type: Opaque
stringData:
  kubernetes.spc: |
    connection "k8s_prod" {
      plugin         = "kubernetes"
      config_path    = "/var/secrets/kubeconfig"
      config_context = "prod-cluster"
    }
```

## GitHub plugin

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: steampipe-github
  namespace: steampipe
type: Opaque
stringData:
  github.spc: |
    connection "github" {
      plugin = "github"
      token  = "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    }
```

```yaml
# values.yaml
initContainer:
  plugins:
    - github

extraVolumes:
  - name: github-config
    secret:
      secretName: steampipe-github

extraVolumeMount:
  - name: github-config
    mountPath: /home/steampipe/.steampipe/config/github.spc
    subPath: github.spc
    readOnly: true
```

## Terraform plugin

Query Terraform state files and configurations:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: steampipe-terraform-config
  namespace: steampipe
data:
  terraform.spc: |
    connection "terraform" {
      plugin = "terraform"
      configuration_file_paths = ["/workspace/*.tf", "/workspace/modules/**/*.tf"]
      state_file_paths         = ["/workspace/terraform.tfstate"]
    }
```

## Multiple plugins with shared credentials volume

```yaml
# values.yaml — install 3 plugins, mount all configs from one Secret
initContainer:
  plugins:
    - aws
    - gcp
    - kubernetes

extraVolumes:
  - name: cloud-configs
    secret:
      secretName: steampipe-all-configs

extraVolumeMount:
  - name: cloud-configs
    mountPath: /home/steampipe/.steampipe/config/aws.spc
    subPath: aws.spc
    readOnly: true
  - name: cloud-configs
    mountPath: /home/steampipe/.steampipe/config/gcp.spc
    subPath: gcp.spc
    readOnly: true
  - name: cloud-configs
    mountPath: /home/steampipe/.steampipe/config/kubernetes.spc
    subPath: kubernetes.spc
    readOnly: true
```

## Pin a specific plugin version

```yaml
initContainer:
  plugins:
    - aws@0.141.0
    - kubernetes@0.32.0
```

## Discover available plugin tables after install

```bash
# After port-forwarding to the service:
psql -h localhost -p 9193 -U steampipe steampipe \
  -c "SELECT table_schema, table_name FROM information_schema.tables WHERE table_schema NOT IN ('pg_catalog','information_schema') ORDER BY table_schema, table_name;"

# Describe a specific table
psql -h localhost -p 9193 -U steampipe steampipe \
  -c "SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'aws_s3_bucket' ORDER BY ordinal_position;"
```
