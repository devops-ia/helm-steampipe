# Steampipe Helm Chart

[Steampipe](https://steampipe.io/) is the zero-ETL solution for getting data directly from APIs and services. This repository enables the deployment of Steampipe on Kubernetes. In addition, there is the possibility to integrate Steampipe with [OAuth2 Proxy](https://github.com/oauth2-proxy/manifests), to add extra security, such as forwarding requests to an IDP, like Keycloak.

## Usage

Charts are available in:

* [Chart Repository](https://helm.sh/docs/topics/chart_repository/)
* [OCI Artifacts](https://helm.sh/docs/topics/registries/)

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

### OCI Registry

Charts are also available in OCI format. The list of available charts can be found [here](https://github.com/devops-ia/helm-steampipe/pkgs/container/helm-steampipe%2Fsteampipe).

#### Install Helm chart

```console
helm install [RELEASE_NAME] oci://ghcr.io/devops-ia/helm-steampipe/steampipe --version=[version]
```

## Steampipe chart

Can be found in [steampipe chart](charts).
