# steampipe

A Helm chart for Kubernetes to deploy Steampipe

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| devops-ia |  | <https://github.com/devops-ia> |

## Prerequisites

* Helm 3+

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://oauth2-proxy.github.io/manifests/ | oauth2-proxy | 7.7.9 |

## Add repository

```console
helm repo add steampipe https://github.com/devops-ia/helm-steampipe
helm repo update
```

## Install Helm chart

```console
helm install [RELEASE_NAME] steampipesteampipe
```

This install all the Kubernetes components associated with the chart and creates the release.

_See [helm install](https://helm.sh/docs/helm/helm_install/) for command documentation._

## Uninstall Helm chart

```console
# Helm
helm uninstall [RELEASE_NAME]
```

This removes all the Kubernetes components associated with the chart and deletes the release.

_See [helm uninstall](https://helm.sh/docs/helm/helm_uninstall/) for command documentation._

## Configuration

See [Customizing the chart before installing](https://helm.sh/docs/intro/using_helm/#customizing-the-chart-before-installing). To see all configurable options with comments:

```console
helm show values steampipe/steampipe
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| args[0] | string | `"--foreground"` |  |
| args[1] | string | `"--show-password"` |  |
| bbdd.enabled | bool | `false` |  |
| bbdd.listen | string | `"network"` |  |
| bbdd.port | int | `9193` |  |
| bbdd.svcAnnotations | object | `{}` |  |
| command | list | `[]` |  |
| configProbe | object | `{}` |  |
| dashboard.enabled | bool | `false` |  |
| dashboard.listen | string | `"network"` |  |
| dashboard.port | int | `9194` |  |
| dashboard.svcAnnotations | object | `{}` |  |
| deploymentAnnotations | object | `{}` |  |
| envFrom | list | `[]` |  |
| env[0].name | string | `"STEAMPIPE_LOG_LEVEL"` |  |
| env[0].value | string | `"TRACE"` |  |
| extraConfig.configMaps.config[0].data."openshift.spc" | string | `"connection \"openshift\" {\n  plugin      = \"openshift\"\n  config_path = \"~/.kube/config\"\n}\n"` |  |
| extraConfig.configMaps.config[0].name | string | `"openshift-connection"` |  |
| extraConfig.configMaps.config[0].type | string | `"Opaque"` |  |
| extraConfig.configMaps.enabled | bool | `false` |  |
| extraConfig.secrets.config[0].data."azure.spc" | string | `"connection \"azure\" {\n  plugin          = \"azure\"\n  environment     = \"AZUREPUBLICCLOUD\"\n  tenant_id       = \"00000000-0000-0000-0000-000000000000\"\n  subscription_id = \"00000000-0000-0000-0000-000000000000\"\n  client_id       = \"00000000-0000-0000-0000-000000000000\"\n  client_secret   = \"~dummy@3password\"\n}\n"` |  |
| extraConfig.secrets.config[0].name | string | `"azure-connection"` |  |
| extraConfig.secrets.config[0].type | string | `"Opaque"` |  |
| extraConfig.secrets.config[1].data.config | string | `"current-context: federal-context\napiVersion: v1\nclusters:\n- cluster:\n    certificate-authority: path/to/my/cafile\n    server: https://horse.org:4443\n  name: horse-cluster\ncontexts:\n- context:\n    cluster: horse-cluster\n    namespace: chisel-ns\n    user: green-user\n  name: federal-context\nkind: Config\nusers:\n- name: green-user\n  user:\n    client-certificate: path/to/my/client/cert\n    client-key: path/to/my/client/key\n"` |  |
| extraConfig.secrets.config[1].name | string | `"openshift-kubeconfig"` |  |
| extraConfig.secrets.config[1].type | string | `"Opaque"` |  |
| extraConfig.secrets.enabled | bool | `false` |  |
| extraContainers | list | `[]` |  |
| extraObjects | list | `[]` |  |
| extraVolumeMount | list | `[]` |  |
| extraVolumes | list | `[]` |  |
| fullnameOverride | string | `""` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.repository | string | `"ghcr.io/turbot/steampipe"` |  |
| image.tag | string | `""` |  |
| imagePullSecrets | list | `[]` |  |
| ingress.annotations | object | `{}` |  |
| ingress.className | string | `""` |  |
| ingress.enabled | bool | `false` |  |
| ingress.hosts[0].host | string | `"chart-example.local"` |  |
| ingress.hosts[0].paths[0].path | string | `"/"` |  |
| ingress.hosts[0].paths[0].pathType | string | `"ImplementationSpecific"` |  |
| ingress.tls | list | `[]` |  |
| initContainer.extraInitVolumeMount | list | `[]` |  |
| initContainer.image.pullPolicy | string | `"IfNotPresent"` |  |
| initContainer.image.repository | string | `"ghcr.io/turbot/steampipe"` |  |
| initContainer.image.tag | string | `""` |  |
| initContainer.mods | list | `[]` |  |
| initContainer.plugins | list | `[]` |  |
| initContainer.resources | object | `{}` |  |
| initContainer.securityContext.runAsNonRoot | bool | `true` |  |
| initContainer.securityContext.runAsUser | int | `9193` |  |
| livenessProbe | object | `{}` |  |
| nameOverride | string | `""` |  |
| nodeSelector | object | `{}` |  |
| oauth2-proxy.alphaConfig.annotations | object | `{}` |  |
| oauth2-proxy.alphaConfig.configData | object | `{}` |  |
| oauth2-proxy.alphaConfig.configFile | string | `""` |  |
| oauth2-proxy.alphaConfig.enabled | bool | `false` |  |
| oauth2-proxy.alphaConfig.existingConfig | string | `nil` |  |
| oauth2-proxy.alphaConfig.existingSecret | string | `nil` |  |
| oauth2-proxy.alphaConfig.metricsConfigData | object | `{}` |  |
| oauth2-proxy.alphaConfig.serverConfigData | object | `{}` |  |
| oauth2-proxy.authenticatedEmailsFile.annotations | object | `{}` |  |
| oauth2-proxy.authenticatedEmailsFile.enabled | bool | `false` |  |
| oauth2-proxy.authenticatedEmailsFile.persistence | string | `"configmap"` |  |
| oauth2-proxy.authenticatedEmailsFile.restrictedUserAccessKey | string | `""` |  |
| oauth2-proxy.authenticatedEmailsFile.restricted_access | string | `""` |  |
| oauth2-proxy.authenticatedEmailsFile.template | string | `""` |  |
| oauth2-proxy.autoscaling.annotations | object | `{}` |  |
| oauth2-proxy.autoscaling.enabled | bool | `false` |  |
| oauth2-proxy.autoscaling.maxReplicas | int | `10` |  |
| oauth2-proxy.autoscaling.minReplicas | int | `1` |  |
| oauth2-proxy.autoscaling.targetCPUUtilizationPercentage | int | `80` |  |
| oauth2-proxy.checkDeprecation | bool | `true` |  |
| oauth2-proxy.config.annotations | object | `{}` |  |
| oauth2-proxy.config.clientID | string | `"XXXXXXX"` |  |
| oauth2-proxy.config.clientSecret | string | `"XXXXXXXX"` |  |
| oauth2-proxy.config.configFile | string | `"email_domains = [ \"*\" ]\nupstreams = [ \"file:///dev/null\" ]"` |  |
| oauth2-proxy.config.cookieName | string | `""` |  |
| oauth2-proxy.config.cookieSecret | string | `"XXXXXXXXXXXXXXXX"` |  |
| oauth2-proxy.config.google | object | `{}` |  |
| oauth2-proxy.customLabels | object | `{}` | Custom labels to add into metadata |
| oauth2-proxy.deploymentAnnotations | object | `{}` |  |
| oauth2-proxy.envFrom | list | `[]` |  |
| oauth2-proxy.extraArgs | object | `{}` |  |
| oauth2-proxy.extraContainers | list | `[]` |  |
| oauth2-proxy.extraEnv | list | `[]` |  |
| oauth2-proxy.extraObjects | list | `[]` |  |
| oauth2-proxy.extraVolumeMounts | list | `[]` |  |
| oauth2-proxy.extraVolumes | list | `[]` |  |
| oauth2-proxy.hostAliases | list | `[]` |  |
| oauth2-proxy.htpasswdFile.enabled | bool | `false` |  |
| oauth2-proxy.htpasswdFile.entries | list | `[]` |  |
| oauth2-proxy.htpasswdFile.existingSecret | string | `""` |  |
| oauth2-proxy.httpScheme | string | `"http"` |  |
| oauth2-proxy.image.pullPolicy | string | `"IfNotPresent"` |  |
| oauth2-proxy.image.repository | string | `"quay.io/oauth2-proxy/oauth2-proxy"` |  |
| oauth2-proxy.image.tag | string | `""` |  |
| oauth2-proxy.ingress.enabled | bool | `false` |  |
| oauth2-proxy.ingress.labels | object | `{}` |  |
| oauth2-proxy.ingress.path | string | `"/"` |  |
| oauth2-proxy.ingress.pathType | string | `"ImplementationSpecific"` |  |
| oauth2-proxy.initContainers.waitForRedis.enabled | bool | `true` |  |
| oauth2-proxy.initContainers.waitForRedis.image.pullPolicy | string | `"IfNotPresent"` |  |
| oauth2-proxy.initContainers.waitForRedis.image.repository | string | `"alpine"` |  |
| oauth2-proxy.initContainers.waitForRedis.image.tag | string | `"latest"` |  |
| oauth2-proxy.initContainers.waitForRedis.kubectlVersion | string | `""` |  |
| oauth2-proxy.initContainers.waitForRedis.resources | object | `{}` |  |
| oauth2-proxy.initContainers.waitForRedis.securityContext.allowPrivilegeEscalation | bool | `false` |  |
| oauth2-proxy.initContainers.waitForRedis.securityContext.capabilities.drop[0] | string | `"ALL"` |  |
| oauth2-proxy.initContainers.waitForRedis.securityContext.enabled | bool | `true` |  |
| oauth2-proxy.initContainers.waitForRedis.securityContext.readOnlyRootFilesystem | bool | `true` |  |
| oauth2-proxy.initContainers.waitForRedis.securityContext.runAsGroup | int | `65534` |  |
| oauth2-proxy.initContainers.waitForRedis.securityContext.runAsNonRoot | bool | `true` |  |
| oauth2-proxy.initContainers.waitForRedis.securityContext.runAsUser | int | `65534` |  |
| oauth2-proxy.initContainers.waitForRedis.securityContext.seccompProfile.type | string | `"RuntimeDefault"` |  |
| oauth2-proxy.initContainers.waitForRedis.timeout | int | `180` |  |
| oauth2-proxy.kubeVersion | string | `nil` |  |
| oauth2-proxy.livenessProbe.enabled | bool | `true` |  |
| oauth2-proxy.livenessProbe.initialDelaySeconds | int | `0` |  |
| oauth2-proxy.livenessProbe.timeoutSeconds | int | `1` |  |
| oauth2-proxy.metrics.enabled | bool | `true` |  |
| oauth2-proxy.metrics.port | int | `44180` |  |
| oauth2-proxy.metrics.service.appProtocol | string | `"http"` |  |
| oauth2-proxy.metrics.serviceMonitor.annotations | object | `{}` |  |
| oauth2-proxy.metrics.serviceMonitor.bearerTokenFile | string | `""` |  |
| oauth2-proxy.metrics.serviceMonitor.enabled | bool | `false` |  |
| oauth2-proxy.metrics.serviceMonitor.interval | string | `"60s"` |  |
| oauth2-proxy.metrics.serviceMonitor.labels | object | `{}` |  |
| oauth2-proxy.metrics.serviceMonitor.metricRelabelings | list | `[]` |  |
| oauth2-proxy.metrics.serviceMonitor.namespace | string | `""` |  |
| oauth2-proxy.metrics.serviceMonitor.prometheusInstance | string | `"default"` |  |
| oauth2-proxy.metrics.serviceMonitor.relabelings | list | `[]` |  |
| oauth2-proxy.metrics.serviceMonitor.scheme | string | `""` |  |
| oauth2-proxy.metrics.serviceMonitor.scrapeTimeout | string | `"30s"` |  |
| oauth2-proxy.metrics.serviceMonitor.tlsConfig | object | `{}` |  |
| oauth2-proxy.namespaceOverride | string | `""` |  |
| oauth2-proxy.nodeSelector | object | `{}` |  |
| oauth2-proxy.podAnnotations | object | `{}` |  |
| oauth2-proxy.podDisruptionBudget.enabled | bool | `true` |  |
| oauth2-proxy.podDisruptionBudget.minAvailable | int | `1` |  |
| oauth2-proxy.podLabels | object | `{}` |  |
| oauth2-proxy.podSecurityContext | object | `{}` |  |
| oauth2-proxy.priorityClassName | string | `""` |  |
| oauth2-proxy.proxyVarsAsSecrets | bool | `true` |  |
| oauth2-proxy.readinessProbe.enabled | bool | `true` |  |
| oauth2-proxy.readinessProbe.initialDelaySeconds | int | `0` |  |
| oauth2-proxy.readinessProbe.periodSeconds | int | `10` |  |
| oauth2-proxy.readinessProbe.successThreshold | int | `1` |  |
| oauth2-proxy.readinessProbe.timeoutSeconds | int | `5` |  |
| oauth2-proxy.redis.enabled | bool | `false` |  |
| oauth2-proxy.replicaCount | int | `1` |  |
| oauth2-proxy.resources | object | `{}` |  |
| oauth2-proxy.revisionHistoryLimit | int | `10` |  |
| oauth2-proxy.securityContext.allowPrivilegeEscalation | bool | `false` |  |
| oauth2-proxy.securityContext.capabilities.drop[0] | string | `"ALL"` |  |
| oauth2-proxy.securityContext.enabled | bool | `true` |  |
| oauth2-proxy.securityContext.readOnlyRootFilesystem | bool | `true` |  |
| oauth2-proxy.securityContext.runAsGroup | int | `2000` |  |
| oauth2-proxy.securityContext.runAsNonRoot | bool | `true` |  |
| oauth2-proxy.securityContext.runAsUser | int | `2000` |  |
| oauth2-proxy.securityContext.seccompProfile.type | string | `"RuntimeDefault"` |  |
| oauth2-proxy.service.annotations | object | `{}` |  |
| oauth2-proxy.service.appProtocol | string | `"http"` |  |
| oauth2-proxy.service.externalTrafficPolicy | string | `""` |  |
| oauth2-proxy.service.internalTrafficPolicy | string | `""` |  |
| oauth2-proxy.service.portNumber | int | `80` |  |
| oauth2-proxy.service.type | string | `"ClusterIP"` |  |
| oauth2-proxy.serviceAccount.annotations | object | `{}` |  |
| oauth2-proxy.serviceAccount.automountServiceAccountToken | bool | `true` |  |
| oauth2-proxy.serviceAccount.enabled | bool | `true` |  |
| oauth2-proxy.serviceAccount.name | string | `nil` |  |
| oauth2-proxy.sessionStorage.redis.clientType | string | `"standalone"` |  |
| oauth2-proxy.sessionStorage.redis.cluster.connectionUrls | list | `[]` |  |
| oauth2-proxy.sessionStorage.redis.existingSecret | string | `""` |  |
| oauth2-proxy.sessionStorage.redis.password | string | `""` |  |
| oauth2-proxy.sessionStorage.redis.passwordKey | string | `"redis-password"` |  |
| oauth2-proxy.sessionStorage.redis.sentinel.connectionUrls | list | `[]` |  |
| oauth2-proxy.sessionStorage.redis.sentinel.existingSecret | string | `""` |  |
| oauth2-proxy.sessionStorage.redis.sentinel.masterName | string | `""` |  |
| oauth2-proxy.sessionStorage.redis.sentinel.password | string | `""` |  |
| oauth2-proxy.sessionStorage.redis.sentinel.passwordKey | string | `"redis-sentinel-password"` |  |
| oauth2-proxy.sessionStorage.redis.standalone.connectionUrl | string | `""` |  |
| oauth2-proxy.sessionStorage.type | string | `"cookie"` |  |
| oauth2-proxy.strategy | object | `{}` |  |
| oauth2-proxy.tolerations | list | `[]` |  |
| oauth2Proxy.enabled | bool | `false` |  |
| podAnnotations | object | `{}` |  |
| podSecurityContext.fsGroup | int | `9193` |  |
| podSecurityContext.runAsGroup | int | `65534` |  |
| podSecurityContext.runAsUser | int | `9193` |  |
| readinessProbe | object | `{}` |  |
| replicaCount | int | `1` |  |
| resources | object | `{}` |  |
| securityContext.runAsNonRoot | bool | `true` |  |
| securityContext.runAsUser | int | `9193` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `""` |  |
| tolerations | list | `[]` |  |