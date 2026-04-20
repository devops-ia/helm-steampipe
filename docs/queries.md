# SQL Queries

Steampipe exposes a PostgreSQL endpoint (port 9193). Connect with `psql`, any PostgreSQL client, or from an in-cluster pod. All examples assume a port-forward or in-cluster connection.

## AWS

### EC2 instances

```sql
-- All running instances with key details
SELECT
  instance_id,
  instance_type,
  instance_state,
  region,
  launch_time,
  tags ->> 'Name' AS name
FROM aws_ec2_instance
WHERE instance_state = 'running'
ORDER BY region, launch_time DESC;
```

```sql
-- Instances with no IAM profile (potential security gap)
SELECT instance_id, instance_type, region
FROM aws_ec2_instance
WHERE iam_instance_profile_id IS NULL
  AND instance_state = 'running';
```

```sql
-- Instances older than 90 days
SELECT instance_id, instance_type, region, launch_time
FROM aws_ec2_instance
WHERE launch_time < NOW() - INTERVAL '90 days'
  AND instance_state = 'running'
ORDER BY launch_time;
```

### S3 buckets

```sql
-- Public S3 buckets
SELECT name, region, creation_date
FROM aws_s3_bucket
WHERE bucket_policy_is_public = true
   OR acl ->> 'Owner' IS NULL
ORDER BY creation_date;
```

```sql
-- Buckets without server-side encryption
SELECT name, region
FROM aws_s3_bucket
WHERE server_side_encryption_configuration IS NULL;
```

```sql
-- Bucket size and object count by region
SELECT
  region,
  count(*) AS bucket_count
FROM aws_s3_bucket
GROUP BY region
ORDER BY bucket_count DESC;
```

### IAM

```sql
-- IAM users with console access but no MFA
SELECT name, create_date, password_last_used
FROM aws_iam_user
WHERE password_enabled = true
  AND mfa_enabled = false
ORDER BY create_date;
```

```sql
-- IAM roles with admin policies attached
SELECT r.name AS role_name, p.name AS policy_name
FROM aws_iam_role r
JOIN aws_iam_role_policy rp ON r.name = rp.role_name
JOIN aws_iam_policy p ON rp.policy_arn = p.arn
WHERE p.name IN ('AdministratorAccess', 'PowerUserAccess');
```

```sql
-- Access keys older than 90 days
SELECT user_name, access_key_id, status, create_date
FROM aws_iam_access_key
WHERE create_date < NOW() - INTERVAL '90 days'
  AND status = 'Active'
ORDER BY create_date;
```

### Security Groups

```sql
-- Security groups with unrestricted inbound SSH or RDP
SELECT
  group_name,
  group_id,
  vpc_id,
  region
FROM aws_vpc_security_group_rule
WHERE type = 'ingress'
  AND cidr_ipv4 = '0.0.0.0/0'
  AND (from_port = 22 OR from_port = 3389)
ORDER BY region;
```

### RDS

```sql
-- RDS instances not in multi-AZ (single point of failure)
SELECT db_instance_identifier, engine, engine_version, db_instance_class, region
FROM aws_rds_db_instance
WHERE multi_az = false
  AND db_instance_status = 'available'
ORDER BY region;
```

```sql
-- RDS instances with public access
SELECT db_instance_identifier, engine, publicly_accessible, region
FROM aws_rds_db_instance
WHERE publicly_accessible = true;
```

## GCP

### Compute

```sql
-- Running GCP VMs by zone
SELECT name, zone, machine_type, status
FROM gcp_compute_instance
WHERE status = 'RUNNING'
ORDER BY zone;
```

```sql
-- VMs with external IPs (exposed to internet)
SELECT name, zone, network_interfaces
FROM gcp_compute_instance
WHERE EXISTS (
  SELECT 1 FROM jsonb_array_elements(network_interfaces) ni
  WHERE ni -> 'accessConfigs' IS NOT NULL
);
```

### Storage

```sql
-- GCS buckets with public access
SELECT name, location, storage_class
FROM gcp_storage_bucket
WHERE iam_configuration ->> 'publicAccessPrevention' != 'enforced'
ORDER BY location;
```

### GKE

```sql
-- GKE clusters and their Kubernetes versions
SELECT name, location, current_master_version, node_config
FROM gcp_kubernetes_cluster
ORDER BY location;
```

## Azure

### Virtual Machines

```sql
-- Running Azure VMs by location
SELECT name, location, vm_size, power_state
FROM azure_compute_virtual_machine
WHERE power_state = 'running'
ORDER BY location;
```

```sql
-- VMs without managed disk (unmanaged storage)
SELECT name, resource_group, location
FROM azure_compute_virtual_machine
WHERE managed_disk_id IS NULL;
```

### AKS

```sql
-- AKS clusters and their Kubernetes version
SELECT name, resource_group, location, kubernetes_version, node_resource_group
FROM azure_kubernetes_cluster
ORDER BY location;
```

### Storage

```sql
-- Storage accounts with HTTP allowed (not HTTPS-only)
SELECT name, resource_group, location
FROM azure_storage_account
WHERE enable_https_traffic_only = false;
```

## Kubernetes

```sql
-- Pods not in Running state
SELECT namespace, name, phase, node_name, start_time
FROM kubernetes_pod
WHERE phase != 'Running'
ORDER BY namespace, name;
```

```sql
-- Pods without resource limits (potential noisy neighbors)
SELECT
  namespace,
  name,
  c ->> 'name' AS container
FROM kubernetes_pod,
     jsonb_array_elements(spec -> 'containers') AS c
WHERE c -> 'resources' -> 'limits' IS NULL
ORDER BY namespace, name;
```

```sql
-- Deployments with fewer ready replicas than desired
SELECT
  namespace,
  name,
  spec_replicas AS desired,
  status_ready_replicas AS ready
FROM kubernetes_deployment
WHERE status_ready_replicas < spec_replicas
ORDER BY namespace;
```

```sql
-- Services of type LoadBalancer (external exposure)
SELECT namespace, name, spec_type, status_load_balancer
FROM kubernetes_service
WHERE spec_type = 'LoadBalancer'
ORDER BY namespace;
```

```sql
-- ClusterRoleBindings that grant cluster-admin
SELECT name, subjects
FROM kubernetes_cluster_role_binding
WHERE role_name = 'cluster-admin'
ORDER BY name;
```

```sql
-- Namespaces without resource quotas
SELECT n.name AS namespace
FROM kubernetes_namespace n
LEFT JOIN kubernetes_resource_quota q ON n.name = q.namespace
WHERE q.name IS NULL
  AND n.name NOT IN ('kube-system', 'kube-public', 'kube-node-lease')
ORDER BY namespace;
```

## Multi-cloud

### Compare running VMs across clouds

```sql
SELECT 'aws'   AS cloud, instance_id AS id, instance_type AS size, region   AS location FROM aws_ec2_instance             WHERE instance_state = 'running'
UNION ALL
SELECT 'gcp'   AS cloud, id,                machine_type,           zone              FROM gcp_compute_instance            WHERE status = 'RUNNING'
UNION ALL
SELECT 'azure' AS cloud, id,                vm_size,                location          FROM azure_compute_virtual_machine   WHERE power_state = 'running'
ORDER BY cloud, location;
```

### Storage inventory across clouds

```sql
SELECT 'aws'   AS cloud, name, region    AS location FROM aws_s3_bucket
UNION ALL
SELECT 'gcp'   AS cloud, name, location             FROM gcp_storage_bucket
UNION ALL
SELECT 'azure' AS cloud, name, location             FROM azure_storage_account
ORDER BY cloud, location;
```

### Cross-cloud Kubernetes cluster inventory

```sql
-- EKS clusters
SELECT 'eks'   AS type, name, region   AS location, version FROM aws_eks_cluster
UNION ALL
-- GKE clusters
SELECT 'gke'   AS type, name, location,              current_master_version FROM gcp_kubernetes_cluster
UNION ALL
-- AKS clusters
SELECT 'aks'   AS type, name, location,              kubernetes_version     FROM azure_kubernetes_cluster
ORDER BY type, location;
```

## Compliance patterns

### CIS AWS Benchmark — sample checks

```sql
-- CIS 1.4: No root access keys
SELECT account_id, access_key_1_active, access_key_2_active
FROM aws_iam_credential_report
WHERE user_name = '<root_account>'
  AND (access_key_1_active = true OR access_key_2_active = true);
```

```sql
-- CIS 2.1: Ensure CloudTrail is enabled in all regions
SELECT region, name, is_multi_region_trail, is_logging
FROM aws_cloudtrail_trail
WHERE is_multi_region_trail = false OR is_logging = false;
```

```sql
-- CIS 4.1: No security groups allow unrestricted inbound
SELECT group_id, group_name, region
FROM aws_vpc_security_group_rule
WHERE type = 'ingress'
  AND cidr_ipv4 = '0.0.0.0/0'
  AND ip_protocol = '-1';
```
