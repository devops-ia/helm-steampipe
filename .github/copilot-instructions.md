# Copilot Instructions — helm-steampipe

## Build, Lint, and Test

```bash
# Lint the chart
helm lint charts/steampipe/

# Lint with chart-testing (uses .github/ct.yaml config)
ct lint --config .github/ct.yaml

# Dry-run install (validates templates render without a cluster)
helm install steampipe charts/steampipe/ --dry-run --debug

# Dry-run a specific CI values file (there are 5 in charts/steampipe/ci/)
helm install steampipe charts/steampipe/ --dry-run --debug -f charts/steampipe/ci/values-bbdd.yaml

# Run all helm-unittest tests
helm unittest charts/steampipe/

# Run a single test file
helm unittest charts/steampipe/ -f tests/bbdd_test.yaml

# Run tests matching a name pattern
helm unittest charts/steampipe/ -t "should create a service when bbdd.enabled is true"

# Update snapshots after intentional template changes
helm unittest --update-snapshot charts/steampipe/

# Regenerate charts/steampipe/README.md from the .gotmpl template
helm-docs --chart-search-root=charts/steampipe

# Run pre-commit hooks (helmlint + helm-docs + markdown-toc + whitespace)
pre-commit run --all-files
```

Unit tests live in `charts/steampipe/tests/*_test.yaml`. Snapshots are stored in `charts/steampipe/tests/__snapshot__/` — commit them alongside template changes.

## Architecture

This is a **single Helm chart** (`charts/steampipe/`) that deploys Steampipe as a persistent PostgreSQL-compatible service on Kubernetes (port 9193). There are no optional companion components (Powerpipe and oauth2-proxy were removed in v4.0.0 and are separate charts).

### Pod lifecycle

1. **Init container** installs plugins declared in `initContainer.plugins[]` via a ConfigMap-mounted shell script (`configmap-init-scripts.yaml`). Plugins live in an `emptyDir` — reinstalled on every pod start. **The init container uses the same image as the main container** — no separate image.
2. **Main container** runs `steampipe service start` with `--foreground` and optional `--database-listen`/`--database-port` flags.
3. **Service** (`<fullname>-psql`) is only created when `bbdd.enabled: true`.

### Steampipe v2 constraints

- Steampipe runs as UID 9193, GID 0 (OpenShift compatible).
- Image: `ghcr.io/devops-ia/steampipe` (not `ghcr.io/turbot/steampipe`).
- `appVersion` is bumped automatically by updatecli (`.github/updatecli/helm-appversion.yaml`) monitoring `devops-ia/steampipe` releases.

## Key Conventions

- **Commit messages** follow [Conventional Commits](https://www.conventionalcommits.org/). Releases are cut by semantic-release via `package.json`.
- **Chart README** (`charts/steampipe/README.md`) is **auto-generated** — never edit it directly. Edit `charts/steampipe/README.md.gotmpl` instead and run `helm-docs`.
- **CI values files** in `charts/steampipe/ci/` are used by `ct lint`/`ct install` for matrix testing. Name them `values-<scenario>.yaml`.
- **Values schema** (`values.schema.json`) must stay in sync with `values.yaml` — Helm validates values against it at install time.
- **Version bumps** for `appVersion` are handled by updatecli (`.github/updatecli/helm-appversion.yaml`). Don't bump manually.
- **Template naming**: Steampipe resources use `steampipe.fullname`. The PostgreSQL service always appends `-psql`.
- **Plugin configs** (`.spc` files) are mounted from Secrets or ConfigMaps into `/home/steampipe/.steampipe/config/` via `extraVolumes`/`extraVolumeMount`.
- **CLI drift detection**: A workflow (`.github/workflows/helm-snapshot-check.yml`) posts a PR comment comparing `cli-snapshot.json` from `devops-ia/steampipe` at the old and new appVersions when `Chart.yaml` changes on a PR.
- **Ingress is TCP-only**: Steampipe exposes PostgreSQL (port 9193), not HTTP. Standard Kubernetes Ingress won't work. Use NGINX TCP services ConfigMap, Traefik `IngressRouteTCP`, or simply rely on `bbdd.serviceType: LoadBalancer`. Don't create an HTTP Ingress expecting it to proxy PostgreSQL.
- **`extraObjects`**: Use `extraObjects[]` to deploy arbitrary Kubernetes manifests (CronJobs, NetworkPolicies, etc.) alongside the chart without a separate Helm release.

## Writing Tests

Tests use [helm-unittest](https://github.com/helm-unittest/helm-unittest). Each file targets one or more templates and uses `set:` to override values inline:

```yaml
suite: my tests
templates:
  - templates/deployment.yaml

tests:
  - it: should do X when Y is set
    set:
      bbdd.enabled: true
      bbdd.serviceType: LoadBalancer
    asserts:
      - equal:
          path: spec.type
          value: LoadBalancer
```

- Use `templates:` at the test level to scope assertions to a specific template when the suite covers multiple.
- Use `hasDocuments: count: 0` to assert a template renders nothing (e.g., Service when `bbdd.enabled: false`).
- After changing templates, run `helm unittest --update-snapshot charts/steampipe/` and commit the updated snapshots in `tests/__snapshot__/`.

