# Troubleshooting

## Pod stuck in Init:Error or Init:CrashLoopBackOff

The init container installs plugins before the main process starts. If it fails, the pod never becomes Ready.

### Check init container logs

```bash
# Get the pod name
kubectl get pods -n steampipe -l app.kubernetes.io/name=steampipe

# View init container logs
kubectl logs -n steampipe <pod-name> -c init

# Common errors:
# "Error: unknown plugin: aws123" → typo in plugin name
# "Error: could not connect to registry" → network/firewall issue
# "steampipe: command not found" → wrong image
```

### Verify plugin names

Plugin names must match exactly what's on [hub.steampipe.io](https://hub.steampipe.io):

```yaml
# Correct
initContainer:
  plugins:
    - aws
    - gcp
    - azure
    - kubernetes
    - github

# Wrong — these will fail
initContainer:
  plugins:
    - amazon-aws       # wrong
    - google-cloud     # wrong
    - azure-rm         # wrong
```

### Network issues during plugin install

If the init container can't reach the plugin registry:

```bash
# Test network connectivity from the cluster
kubectl run net-test --rm -it --image=curlimages/curl -n steampipe -- \
  curl -I https://hub.steampipe.io

# If using a private registry or air-gapped cluster, pre-build a custom image
# with plugins already installed:
```

```dockerfile
# Dockerfile — pre-install plugins at image build time
FROM ghcr.io/devops-ia/steampipe:2.4.1
RUN steampipe plugin install aws gcp kubernetes
```

```yaml
# Use the custom image instead of installing at runtime
image:
  repository: myregistry.example.com/steampipe-with-plugins
  tag: "2.4.1"

# Clear the plugins list so init container does nothing
initContainer:
  plugins: []
```

---

## CrashLoopBackOff on main container

```bash
# View main container logs
kubectl logs -n steampipe <pod-name> -c steampipe

# View previous crash logs
kubectl logs -n steampipe <pod-name> -c steampipe --previous
```

### Common causes

**Permission denied on .steampipe directory:**

```bash
# Error: "open /home/steampipe/.steampipe/...: permission denied"
# Fix: verify securityContext
```

```yaml
# Correct security context
podSecurityContext:
  fsGroup: 9193
  runAsGroup: 0
  runAsUser: 9193

securityContext:
  runAsNonRoot: true
  runAsUser: 9193
```

**Plugin .spc file not found:**

```bash
# Error: "failed to load plugin config: no such file or directory"
# Check if the volume mount is correct
kubectl describe pod -n steampipe <pod-name> | grep -A 20 "Mounts:"
```

```yaml
# Verify the mountPath ends in the filename, not a directory
extraVolumeMount:
  - name: aws-config
    mountPath: /home/steampipe/.steampipe/config/aws.spc  # correct
    subPath: aws.spc
    readOnly: true

# Wrong — this mounts a directory, not a file
  - name: aws-config
    mountPath: /home/steampipe/.steampipe/config/  # wrong if subPath is set
```

---

## Cannot connect to PostgreSQL

### Checklist

```bash
# 1. Verify bbdd.enabled is true — no Service is created without it
kubectl get svc -n steampipe | grep psql
# Must show: steampipe-psql

# 2. Check the service port
kubectl get svc -n steampipe steampipe-psql -o jsonpath='{.spec.ports[0].port}'
# Should return: 9193

# 3. Verify bbdd.listen is 'network' not 'local'
helm get values steampipe -n steampipe | grep listen

# 4. Port-forward and test
kubectl port-forward -n steampipe svc/steampipe-psql 9193:9193 &
psql -h localhost -p 9193 -U steampipe steampipe -c "SELECT 1;"

# 5. Check if pod is Ready
kubectl get pods -n steampipe -l app.kubernetes.io/name=steampipe
```

### Connection refused — service misconfigured

```yaml
# values.yaml — ensure these are set correctly
bbdd:
  enabled: true   # REQUIRED — without this, no Service is created
  port: 9193
  listen: network # REQUIRED — 'local' only accepts connections from localhost
  serviceType: ClusterIP
```

---

## Random password changes on restart

**Symptom:** Client applications break after pod restarts because the password changed.

**Root cause:** Without `STEAMPIPE_DATABASE_PASSWORD`, Steampipe generates a new random password on every start.

```bash
# Fix: create a stable password secret
kubectl create secret generic steampipe-password \
  --from-literal=password=your-stable-password \
  --namespace steampipe
```

```yaml
# values.yaml
env:
  - name: STEAMPIPE_DATABASE_PASSWORD
    valueFrom:
      secretKeyRef:
        name: steampipe-password
        key: password
```

---

## Plugin queries return no rows (not OOM)

**Symptom:** Queries return empty results even though resources exist.

```bash
# Check if the plugin loaded correctly
psql -h localhost -p 9193 -U steampipe steampipe \
  -c "SELECT * FROM steampipe_connection ORDER BY name;"

# Verify the .spc file is mounted correctly
kubectl exec -n steampipe <pod-name> -- \
  ls -la /home/steampipe/.steampipe/config/

# Check the .spc file content
kubectl exec -n steampipe <pod-name> -- \
  cat /home/steampipe/.steampipe/config/aws.spc
```

---

## Plugin OOM — pod killed

**Symptom:** Pod OOMKilled while running complex queries.

```yaml
# Increase memory limits and tune Steampipe memory settings
resources:
  limits:
    memory: 4Gi
  requests:
    memory: 1Gi

env:
  - name: STEAMPIPE_MEMORY_MAX_MB
    value: "3000"
  - name: STEAMPIPE_PLUGIN_MEMORY_MAX_MB
    value: "1500"
  - name: STEAMPIPE_MAX_PARALLEL
    value: "5"     # Reduce parallel queries to lower memory pressure
  - name: STEAMPIPE_QUERY_TIMEOUT
    value: "120"
```

---

## OpenShift — permission denied

Steampipe runs as UID 9193 / GID 0 and is compatible with OpenShift's **restricted** SCC without modifications. If you see permission errors:

```bash
# Check the SCC assigned to the pod
oc get pod <pod-name> -n steampipe -o jsonpath='{.metadata.annotations.openshift\.io/scc}'

# The pod should use 'restricted' or 'nonroot' SCC
# If forced into 'anyuid' or something else, check your namespace SCC bindings
```

```yaml
# Do NOT override these for OpenShift — these are the correct defaults
podSecurityContext:
  fsGroup: 9193
  runAsGroup: 0   # GID 0 = root group, required for OpenShift compatibility
  runAsUser: 9193

securityContext:
  runAsNonRoot: true
  runAsUser: 9193
```

---

## Ingress returning 502

**Symptom:** Accessing Steampipe via Kubernetes Ingress returns HTTP 502.

**Root cause:** Standard Kubernetes Ingress operates at L7 (HTTP/HTTPS) and cannot proxy TCP traffic. Steampipe speaks the PostgreSQL wire protocol.

**Option 1 — LoadBalancer service (recommended)**

```yaml
bbdd:
  enabled: true
  listen: network
  serviceType: LoadBalancer
  svcAnnotations:
    service.beta.kubernetes.io/aws-load-balancer-type: nlb
    service.beta.kubernetes.io/aws-load-balancer-scheme: internal
```

**Option 2 — NGINX TCP passthrough**

```bash
# Patch the tcp-services ConfigMap in the ingress-nginx namespace
kubectl patch configmap tcp-services \
  --namespace ingress-nginx \
  --patch '{"data":{"9193":"steampipe/steampipe-psql:9193"}}'
```

**Option 3 — Traefik IngressRouteTCP**

```yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRouteTCP
metadata:
  name: steampipe-psql
  namespace: steampipe
spec:
  entryPoints:
    - postgresql
  routes:
    - match: HostSNI(`*`)
      services:
        - name: steampipe-psql
          port: 9193
```

---

## Plugins not available after restart

**Expected behavior:** Plugins are installed in an `emptyDir` volume and are **reinstalled on every pod start** by the init container. This is intentional to keep plugin versions current.

If plugins are missing after restart, the init container failed — check its logs:

```bash
kubectl logs -n steampipe <pod-name> -c init
```

If startup time with plugin installation is too slow, pre-install at build time (see [air-gapped / pre-installed section in troubleshooting above](#network-issues-during-plugin-install)).

---

## Debugging tips

```bash
# Get all events for the namespace
kubectl get events -n steampipe --sort-by='.lastTimestamp'

# Describe the pod for a full lifecycle view
kubectl describe pod -n steampipe <pod-name>

# Execute a shell in the running container
kubectl exec -it -n steampipe <pod-name> -c steampipe -- /bin/bash

# Run a direct steampipe query from inside the container
kubectl exec -n steampipe <pod-name> -c steampipe -- \
  steampipe query "SELECT 1 AS test"

# Check if Steampipe service is listening inside the pod
kubectl exec -n steampipe <pod-name> -c steampipe -- \
  pg_isready -h localhost -p 9193 -U steampipe
```
