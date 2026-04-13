# Testing

## Prerequisites

- [Helm 3+](https://helm.sh/docs/intro/install/)
- [helm-docs](https://github.com/norwoodj/helm-docs) (for README generation)
- [chart-testing (ct)](https://github.com/helm/chart-testing) (for lint/test)
- [pre-commit](https://pre-commit.com/) (optional, for local hooks)

## Local lint

```console
helm lint charts/steampipe/
```

## Chart testing (ct)

Uses the `ct.yaml` config in `.github/`.

```console
ct lint --config .github/ct.yaml
```

## Install chart dependencies

```console
helm dependency update charts/steampipe/
```

## Dry-run install

```console
helm install steampipe charts/steampipe/ --dry-run --debug
```

## Update README

Generate the `README.md` from `README.md.gotmpl` using helm-docs:

```console
helm-docs --chart-search-root=charts/steampipe
```

## pre-commit hooks

```console
pre-commit install
pre-commit run --all-files
```

## updatecli (local)

Check what updatecli would do without applying changes:

```console
# Check steampipe new releases
updatecli diff --config .github/updatecli/helm-appversion.yaml

# Check Helm dependency updates (minor)
updatecli diff --config .github/updatecli/helm-chart-dependencies.yaml
```
