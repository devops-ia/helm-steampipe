# Steampipe Helm Chart

[Steampipe](https://steampipe.io/) is the zero-ETL solution for getting data directly from APIs and services. We offer these Steampipe engines.

## Usage

Charts are available in:

* [Chart Repository](https://helm.sh/docs/topics/chart_repository/)

### Chart Repository

#### Add repository

```console
helm repo add steampipe https://devops-ia.github.io/helm-steampipe
helm repo update
```

#### Install Helm chart

```console
helm install [RELEASE_NAME] steampipe/steampipe
```

This install all the Kubernetes components associated with the chart and creates the release.

_See [helm install](https://helm.sh/docs/helm/helm_install/) for command documentation._
