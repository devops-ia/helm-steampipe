# Copilot Instructions — helm-steampipe

## Build, Lint, and Test

```bash
# Lint the chart
helm lint charts/steampipe/

# Lint with chart-testing (uses .github/ct.yaml config)
ct lint --config .github/ct.yaml

# Dry-run install (validates templates render without a cluster)
helm install steampipe charts/steampipe/ --dry-run --debug

# Dry-run a specific CI values file (there are 6 in charts/steampipe/ci/)
helm install steampipe charts/steampipe/ --dry-run --debug -f charts/steampipe/ci/values-powerpipe.yaml

# Regenerate charts/steampipe/README.md from the .gotmpl template
helm-docs --chart-search-root=charts/steampipe

# Update Helm dependencies (oauth2-proxy sub-chart)
helm dependency update charts/steampipe/

# Run pre-commit hooks (helmlint + helm-docs + markdown-toc + whitespace)
pre-commit run --all-files
```

There is no unit test suite. Validation is done via `helm lint`, `ct lint`, and dry-run installs against the CI values files in `charts/steampipe/ci/`.

## Architecture

This is a **single Helm chart** (`charts/steampipe/`) that deploys Steampipe as a persistent PostgreSQL-compatible service on Kubernetes (port 9193). It has two optional companion components:

- **Powerpipe** — separate Deployment for dashboards/compliance benchmarks, connects to Steampipe's PostgreSQL endpoint. Enabled via `powerpipe.enabled`. Has hard `fail` guards requiring `bbdd.enabled=true` and `bbdd.listen="network"`.
- **oauth2-proxy** — sub-chart dependency for OIDC authentication in front of Ingress. Enabled via `oauth2Proxy.enabled`.

### Pod lifecycle

1. **Init container** installs plugins declared in `initContainer.plugins[]` via a ConfigMap-mounted shell script (`configmap-init-scripts.yaml`). Plugins live in an `emptyDir` — reinstalled on every pod start.
2. **Main container** runs `steampipe service start` with `--foreground` and optional `--database-listen`/`--database-port` flags.
3. **Service** (`<fullname>-psql`) is only created when `bbdd.enabled: true`.

### Steampipe v2 constraints

- `dashboard.*` values are **removed** — the template has a `fail` guard that blocks rendering if `dashboard.enabled=true`.
- `initContainer.mods[]` is removed — mods are Powerpipe's responsibility now.
- Steampipe runs as UID 9193, GID 0 (OpenShift compatible).

## Key Conventions

- **Commit messages** follow [Conventional Commits](https://www.conventionalcommits.org/). Releases are cut by semantic-release via `package.json`.
- **Chart README** (`charts/steampipe/README.md`) is **auto-generated** — never edit it directly. Edit `charts/steampipe/README.md.gotmpl` instead and run `helm-docs`.
- **CI values files** in `charts/steampipe/ci/` are used by `ct lint`/`ct install` for matrix testing. Name them `values-<scenario>.yaml`.
- **Values schema** (`values.schema.json`) must stay in sync with `values.yaml` — Helm validates values against it at install time.
- **Version bumps** for `appVersion` (Steampipe), `powerpipe.image.tag`, and dependency versions are handled by updatecli configs in `.github/updatecli/`. Don't bump these manually.
- **Template naming**: Steampipe resources use `steampipe.fullname`; Powerpipe resources use `steampipe.powerpipe.fullname` (appends `-powerpipe`). The PostgreSQL service always appends `-psql`.
- **Plugin configs** (`.spc` files) are mounted from Secrets or ConfigMaps into `/home/steampipe/.steampipe/config/` via `extraVolumes`/`extraVolumeMount`.
