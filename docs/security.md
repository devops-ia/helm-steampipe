# Security

## Workload Identity — AWS IRSA

AWS IRSA (IAM Roles for Service Accounts) lets Steampipe authenticate to AWS without static credentials.

### Step 1 — Create the IAM role

```bash
# Get cluster OIDC issuer URL
OIDC_URL=$(aws eks describe-cluster --name my-cluster \
  --query "cluster.identity.oidc.issuer" --output text)

# Create the trust policy
cat > trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::123456789012:oidc-provider/${OIDC_URL#https://}"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "${OIDC_URL#https://}:sub": "system:serviceaccount:steampipe:steampipe",
        "${OIDC_URL#https://}:aud": "sts.amazonaws.com"
      }
    }
  }]
}
EOF

# Create the IAM role
aws iam create-role \
  --role-name steampipe-reader \
  --assume-role-policy-document file://trust-policy.json

# Attach a read-only policy (or your custom policy)
aws iam attach-role-policy \
  --role-name steampipe-reader \
  --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess
```

### Step 2 — Helm values

```yaml
# values-irsa.yaml
serviceAccount:
  create: true
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/steampipe-reader
  automountServiceAccountToken: true

initContainer:
  plugins:
    - aws

bbdd:
  enabled: true
  listen: network

extraVolumes:
  - name: aws-config
    configMap:
      name: steampipe-aws-config   # No credentials in this ConfigMap

extraVolumeMount:
  - name: aws-config
    mountPath: /home/steampipe/.steampipe/config/aws.spc
    subPath: aws.spc
    readOnly: true

env:
  - name: STEAMPIPE_DATABASE_PASSWORD
    valueFrom:
      secretKeyRef:
        name: steampipe-password
        key: password
```

```yaml
# steampipe-aws-config ConfigMap — no credentials needed
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

```bash
helm install steampipe steampipe/steampipe \
  --namespace steampipe \
  --create-namespace \
  -f values-irsa.yaml
```

## Workload Identity — GCP

### Step 1 — Bind IAM

```bash
# Create a GCP Service Account
gcloud iam service-accounts create steampipe-reader \
  --project=my-project

# Grant the roles you need
gcloud projects add-iam-policy-binding my-project \
  --member="serviceAccount:steampipe-reader@my-project.iam.gserviceaccount.com" \
  --role="roles/viewer"

# Bind the Kubernetes ServiceAccount to the GCP SA
gcloud iam service-accounts add-iam-policy-binding \
  steampipe-reader@my-project.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="serviceAccount:my-project.svc.id.goog[steampipe/steampipe]"
```

### Step 2 — Helm values

```yaml
# values-gcp-wi.yaml
serviceAccount:
  create: true
  annotations:
    iam.gke.io/gcp-service-account: steampipe-reader@my-project.iam.gserviceaccount.com
  automountServiceAccountToken: true

initContainer:
  plugins:
    - gcp

bbdd:
  enabled: true
  listen: network

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

## Workload Identity — Azure

### Step 1 — Configure the Azure identity

```bash
# Create a managed identity
az identity create \
  --name steampipe-reader \
  --resource-group my-rg

CLIENT_ID=$(az identity show --name steampipe-reader --resource-group my-rg \
  --query clientId -o tsv)

# Assign reader role
az role assignment create \
  --assignee $CLIENT_ID \
  --role "Reader" \
  --scope /subscriptions/00000000-0000-0000-0000-000000000000

# Create the federated credential
az identity federated-credential create \
  --name steampipe-federated \
  --identity-name steampipe-reader \
  --resource-group my-rg \
  --issuer "https://oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE" \
  --subject "system:serviceaccount:steampipe:steampipe" \
  --audiences '["api://AzureADTokenExchange"]'
```

### Step 2 — Helm values

```yaml
# values-azure-wi.yaml
serviceAccount:
  create: true
  annotations:
    azure.workload.identity/client-id: "00000000-0000-0000-0000-000000000000"
  labels:
    azure.workload.identity/use: "true"

podLabels:
  azure.workload.identity/use: "true"

initContainer:
  plugins:
    - azure

bbdd:
  enabled: true
  listen: network

extraVolumes:
  - name: azure-config
    configMap:
      name: steampipe-azure-config

extraVolumeMount:
  - name: azure-config
    mountPath: /home/steampipe/.steampipe/config/azure.spc
    subPath: azure.spc
    readOnly: true
```

```yaml
# ConfigMap — no client_secret
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

## Stable database password

By default Steampipe generates a random password each time the pod starts. Always set a stable one:

```bash
kubectl create secret generic steampipe-password \
  --from-literal=password=your-secure-password \
  --namespace steampipe
```

```yaml
env:
  - name: STEAMPIPE_DATABASE_PASSWORD
    valueFrom:
      secretKeyRef:
        name: steampipe-password
        key: password
```

## Network Policy

Restrict which pods can connect to Steampipe's PostgreSQL port:

```yaml
# network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: steampipe-ingress
  namespace: steampipe
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: steampipe
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: monitoring
          podSelector:
            matchLabels:
              app.kubernetes.io/name: grafana
      ports:
        - protocol: TCP
          port: 9193
  egress:
    - {}  # Allow all egress (needed for cloud API calls)
```

## Pod Security Standards

Steampipe runs as UID 9193 / GID 0 and is compatible with the **restricted** Pod Security Standard without modifications:

```yaml
# namespace label for restricted PSS
kubectl label namespace steampipe \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/warn=restricted
```

```yaml
# values.yaml — PSS-compatible security context (already the default)
podSecurityContext:
  fsGroup: 9193
  runAsGroup: 0
  runAsUser: 9193

securityContext:
  runAsNonRoot: true
  runAsUser: 9193
  allowPrivilegeEscalation: false
  capabilities:
    drop: ["ALL"]
  seccompProfile:
    type: RuntimeDefault
```

## Minimum RBAC for Kubernetes plugin

If using the Kubernetes plugin to query cluster resources, grant the ServiceAccount only the verbs it needs:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: steampipe-k8s-reader
rules:
  - apiGroups: ["", "apps", "batch", "networking.k8s.io", "rbac.authorization.k8s.io", "storage.k8s.io"]
    resources: ["*"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: steampipe-k8s-reader
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: steampipe-k8s-reader
subjects:
  - kind: ServiceAccount
    name: steampipe
    namespace: steampipe
```

## Secrets management with external-secrets

Use External Secrets Operator to sync credentials from AWS Secrets Manager or Vault:

```yaml
# external-secret.yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: steampipe-aws-creds
  namespace: steampipe
spec:
  refreshInterval: 1h
  secretStoreRef:
    kind: ClusterSecretStore
    name: aws-secrets-manager
  target:
    name: steampipe-aws
    template:
      data:
        aws.spc: |
          connection "aws" {
            plugin     = "aws"
            access_key = "{{ .access_key }}"
            secret_key = "{{ .secret_key }}"
            regions    = ["us-east-1"]
          }
  data:
    - secretKey: access_key
      remoteRef:
        key: steampipe/aws
        property: access_key
    - secretKey: secret_key
      remoteRef:
        key: steampipe/aws
        property: secret_key
```
