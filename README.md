# Steampipe Helm Chart

[Steampipe](https://steampipe.io/) is the zero-ETL solution for getting data directly from APIs and services. This repository enables the deployment of Steampipe on Kubernetes. In addition, there is the possibility to integrate Steampipe with [OAuth2 Proxy](https://github.com/oauth2-proxy/manifests), to add extra security, such as forwarding requests to an IDP, like Keycloak.

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
