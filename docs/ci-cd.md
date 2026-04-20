# CI/CD Integration

## GitHub Actions — Helm lint and test

```yaml
# .github/workflows/helm-test.yml
name: Helm Test

on:
  pull_request:
    paths:
      - "charts/**"
      - "docs/**"
      - "context7.json"

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Helm
        uses: azure/setup-helm@v4
        with:
          version: "3.14.0"

      - name: Helm lint
        run: helm lint charts/steampipe/

      - name: Helm lint with CI values
        run: |
          for f in charts/steampipe/ci/*.yaml; do
            echo "Linting with $f..."
            helm lint charts/steampipe/ -f "$f"
          done

      - name: Helm template (dry-run)
        run: |
          helm template steampipe charts/steampipe/ \
            -f charts/steampipe/ci/values-full.yaml \
            --dry-run

  unittest:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Helm
        uses: azure/setup-helm@v4
        with:
          version: "3.14.0"

      - name: Install helm-unittest
        run: helm plugin install https://github.com/helm-unittest/helm-unittest

      - name: Run unit tests
        run: helm unittest charts/steampipe/
```

## GitHub Actions — Helm diff on PR

```yaml
# .github/workflows/helm-diff.yml
name: Helm Diff

on:
  pull_request:

jobs:
  diff:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Helm
        uses: azure/setup-helm@v4
        with:
          version: "3.14.0"

      - name: Install helm-diff
        run: helm plugin install https://github.com/databus23/helm-diff

      - name: Add Helm repo
        run: |
          helm repo add steampipe https://devops-ia.github.io/helm-steampipe
          helm repo update

      - name: Diff against latest published chart
        run: |
          helm diff upgrade steampipe steampipe/steampipe \
            --namespace steampipe \
            --allow-unreleased \
            -f charts/steampipe/ci/values-full.yaml \
            --chart-path charts/steampipe/
```

## GitHub Actions — install into kind cluster

```yaml
# .github/workflows/e2e.yml
name: E2E Test

on:
  push:
    branches: [main]

jobs:
  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Create kind cluster
        uses: helm/kind-action@v1.8.0

      - name: Set up Helm
        uses: azure/setup-helm@v4

      - name: Install chart
        run: |
          helm install steampipe charts/steampipe/ \
            --namespace steampipe \
            --create-namespace \
            --set bbdd.enabled=true \
            --set bbdd.listen=network \
            --wait --timeout 5m

      - name: Verify pods are running
        run: |
          kubectl wait --for=condition=Ready pod \
            -l app.kubernetes.io/name=steampipe \
            -n steampipe \
            --timeout=120s

      - name: Test PostgreSQL connection
        run: |
          kubectl port-forward -n steampipe svc/steampipe-psql 9193:9193 &
          sleep 5
          kubectl run test --rm -it --image=postgres:15 -- \
            psql -h 172.17.0.1 -p 9193 -U steampipe steampipe -c "SELECT 1;"

      - name: Helm test
        run: helm test steampipe --namespace steampipe
```

## chart-testing (ct) integration

The chart uses [chart-testing](https://github.com/helm/chart-testing) via `.github/ct.yaml`:

```bash
# Run ct lint locally (matches CI)
ct lint --config .github/ct.yaml

# Run ct install locally against a running cluster
ct install --config .github/ct.yaml --namespace steampipe --create-namespace
```

```yaml
# .github/ct.yaml
chart-dirs:
  - charts
chart-repos:
  - steampipe=https://devops-ia.github.io/helm-steampipe
helm-extra-set-args: --timeout=5m
```

## ArgoCD with image updater

Auto-update the `appVersion` when a new Steampipe image is published:

```yaml
# argocd-application-image-updater.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: steampipe
  namespace: argocd
  annotations:
    argocd-image-updater.argoproj.io/image-list: steampipe=ghcr.io/devops-ia/steampipe
    argocd-image-updater.argoproj.io/steampipe.helm.image-name: image.repository
    argocd-image-updater.argoproj.io/steampipe.helm.image-tag: image.tag
    argocd-image-updater.argoproj.io/steampipe.update-strategy: latest
spec:
  source:
    repoURL: https://devops-ia.github.io/helm-steampipe
    chart: steampipe
    targetRevision: 2.4.1
```

## Renovate — auto-update chart version

Add to your `renovate.json` to get automatic PRs when a new chart version is published:

```json
{
  "helmv3": {
    "registryAliases": {
      "steampipe": "https://devops-ia.github.io/helm-steampipe"
    }
  },
  "packageRules": [
    {
      "matchManagers": ["helmv3"],
      "matchPackageNames": ["steampipe/steampipe"],
      "automerge": false,
      "labels": ["helm", "steampipe"]
    }
  ]
}
```

## Pre-commit hooks for chart validation

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/gruntwork-io/pre-commit
    rev: v0.1.23
    hooks:
      - id: helmlint
        args: ["charts/steampipe"]

  - repo: local
    hooks:
      - id: helm-unittest
        name: helm unittest
        entry: helm unittest charts/steampipe/
        language: system
        pass_filenames: false
        files: ^charts/steampipe/
```

## Helm release workflow (chart-releaser)

The chart is released automatically when `Chart.yaml` version is bumped:

```bash
# Bump the chart version (triggers release CI)
# Edit charts/steampipe/Chart.yaml:
#   version: 2.5.0    ← bump this
#   appVersion: 2.5.0 ← updated by updatecli automatically

# Create a release tag
git tag -a v2.5.0 -m "Release v2.5.0"
git push origin v2.5.0
```

## Validate Helm values schema

The chart ships a `values.schema.json`. Test that your custom values pass validation:

```bash
# Helm validates the schema automatically on install/upgrade
helm install steampipe charts/steampipe/ -f my-values.yaml
# If values don't match schema, you'll get a descriptive error

# Manually validate a values file against the schema
helm template steampipe charts/steampipe/ -f my-values.yaml --dry-run --debug 2>&1 | head -30
```
