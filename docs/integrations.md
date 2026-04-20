# Integrations

Steampipe exposes a standard PostgreSQL endpoint (default: port 9193) accessible within the cluster via the `<release-name>-psql` service. Any tool that supports PostgreSQL connections works out of the box.

## Connect from within the cluster

```bash
# Service DNS pattern: <release>-psql.<namespace>.svc.cluster.local
psql -h steampipe-psql.steampipe.svc.cluster.local \
     -p 9193 -U steampipe steampipe

# From a debug pod
kubectl run psql-client --rm -it --image=postgres:15 -n steampipe -- \
  psql -h steampipe-psql -p 9193 -U steampipe steampipe -c "SELECT 1;"
```

## Port-forward for local development

```bash
kubectl port-forward -n steampipe svc/steampipe-psql 9193:9193 &

# psql
psql -h localhost -p 9193 -U steampipe steampipe

# DBeaver / TablePlus / DataGrip connection string
postgresql://steampipe@localhost:9193/steampipe?sslmode=disable
```

## Grafana

Connect Grafana to Steampipe using the built-in PostgreSQL datasource.

### Add datasource via Helm (grafana chart)

```yaml
# grafana values.yaml
datasources:
  datasources.yaml:
    apiVersion: 1
    datasources:
      - name: Steampipe
        type: postgres
        url: steampipe-psql.steampipe.svc.cluster.local:9193
        database: steampipe
        user: steampipe
        secureJsonData:
          password: your-steampipe-password
        jsonData:
          sslmode: disable
          postgresVersion: 1400
          timescaledb: false
        isDefault: false
```

### Example Grafana dashboard query

```sql
-- EC2 instance count by state (for a panel)
SELECT
  instance_state AS metric,
  count(*)       AS value
FROM aws_ec2_instance
GROUP BY instance_state
ORDER BY value DESC
```

```sql
-- Running cost proxy: instance type distribution
SELECT
  instance_type,
  count(*) AS instance_count,
  region
FROM aws_ec2_instance
WHERE instance_state = 'running'
GROUP BY instance_type, region
ORDER BY instance_count DESC
```

## Prometheus — ServiceMonitor

Steampipe does not expose Prometheus metrics natively. To monitor the PostgreSQL port availability, use a blackbox exporter probe:

```yaml
# servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: Probe
metadata:
  name: steampipe-tcp
  namespace: steampipe
spec:
  interval: 30s
  module: tcp_connect
  prober:
    url: prometheus-blackbox-exporter.monitoring.svc.cluster.local:9115
  targets:
    staticConfig:
      static:
        - steampipe-psql.steampipe.svc.cluster.local:9193
```

Track Steampipe pod resource usage with standard PodMonitor:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: steampipe
  namespace: steampipe
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: steampipe
  podMetricsEndpoints:
    - port: http
      interval: 30s
```

## psql one-liners against the cluster service

```bash
# Query from a pod in the same namespace (no port-forward needed)
kubectl run q --rm -it --image=postgres:15 -n steampipe -- \
  psql -h steampipe-psql -p 9193 -U steampipe steampipe \
  -c "SELECT name, region FROM aws_s3_bucket WHERE bucket_policy_is_public = true;"

# Export query results to CSV
kubectl run q --rm -it --image=postgres:15 -n steampipe -- \
  psql -h steampipe-psql -p 9193 -U steampipe steampipe \
  -c "COPY (SELECT instance_id, instance_type, region FROM aws_ec2_instance) TO STDOUT CSV HEADER" \
  > ec2-inventory.csv
```

## Python in-cluster (psycopg2)

```python
import psycopg2

# In-cluster connection (no port-forward needed from within the cluster)
conn = psycopg2.connect(
    host="steampipe-psql.steampipe.svc.cluster.local",
    port=9193,
    dbname="steampipe",
    user="steampipe",
    password="your-steampipe-password",
    sslmode="disable",
)
cur = conn.cursor()

# Query running EC2 instances
cur.execute("""
    SELECT instance_id, instance_type, region
    FROM aws_ec2_instance
    WHERE instance_state = 'running'
    ORDER BY region
""")

for row in cur.fetchall():
    print(row)

conn.close()
```

## Node.js in-cluster (pg)

```javascript
const { Client } = require("pg");

const client = new Client({
  host: "steampipe-psql.steampipe.svc.cluster.local",
  port: 9193,
  database: "steampipe",
  user: "steampipe",
  password: process.env.STEAMPIPE_PASSWORD,
  ssl: false,
});

await client.connect();

const { rows } = await client.query(
  "SELECT name, region, creation_date FROM aws_s3_bucket ORDER BY creation_date DESC LIMIT 20"
);
console.log(rows);

await client.end();
```

## dbt on Kubernetes

Point dbt at the Steampipe in-cluster endpoint:

```yaml
# ~/.dbt/profiles.yml (or mounted as a ConfigMap)
steampipe:
  target: prod
  outputs:
    prod:
      type: postgres
      host: steampipe-psql.steampipe.svc.cluster.local
      port: 9193
      dbname: steampipe
      user: steampipe
      password: "{{ env_var('STEAMPIPE_PASSWORD') }}"
      schema: public
      sslmode: disable
      threads: 4
```

```yaml
# dbt-job.yaml — run dbt as a Kubernetes Job
apiVersion: batch/v1
kind: Job
metadata:
  name: dbt-steampipe-run
  namespace: steampipe
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: dbt
          image: ghcr.io/dbt-labs/dbt-postgres:1.7.0
          command: ["dbt", "run", "--profiles-dir", "/dbt", "--project-dir", "/project"]
          env:
            - name: STEAMPIPE_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: steampipe-password
                  key: password
          volumeMounts:
            - name: dbt-profiles
              mountPath: /dbt
            - name: dbt-project
              mountPath: /project
      volumes:
        - name: dbt-profiles
          configMap:
            name: dbt-profiles
        - name: dbt-project
          configMap:
            name: dbt-project
```

## ArgoCD Application with health checks

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: steampipe
  namespace: argocd
  annotations:
    argocd.argoproj.io/sync-wave: "1"
spec:
  project: default
  source:
    repoURL: https://devops-ia.github.io/helm-steampipe
    chart: steampipe
    targetRevision: 2.4.1
    helm:
      releaseName: steampipe
      valuesObject:
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
  destination:
    server: https://kubernetes.default.svc
    namespace: steampipe
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - ServerSideApply=true
```

## Expose externally with LoadBalancer

For access from outside the cluster (dev/staging environments):

```yaml
# values-loadbalancer.yaml
bbdd:
  enabled: true
  port: 9193
  listen: network
  serviceType: LoadBalancer
  svcAnnotations:
    # AWS NLB
    service.beta.kubernetes.io/aws-load-balancer-type: nlb
    service.beta.kubernetes.io/aws-load-balancer-scheme: internal
```

```bash
# Get the external address
kubectl get svc -n steampipe steampipe-psql -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```
