# steampipe

A Helm chart for Kubernetes to deploy Steampipe

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| amartingarcia | <adrianmg231189@gmail.com> | <https://github.com/amartingarcia> |

## Prerequisites

* Helm 3+

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://oauth2-proxy.github.io/manifests/ | oauth2-proxy | 7.7.* |

## Add repository

```console
helm repo add steampipe https://github.com/devops-ia/helm-steampipe
helm repo update
```

## Install Helm chart (repository mode)

```console
helm install [RELEASE_NAME] steampipesteampipe
```

This install all the Kubernetes components associated with the chart and creates the release.

_See [helm install](https://helm.sh/docs/helm/helm_install/) for command documentation._

## Install Helm chart (OCI mode)

Charts are also available in OCI format. The list of available charts can be found [here](https://github.com/devops-ia/helm-steampipe/pkgs/container/helm-steampipe%2Fsteampipe).

```console
helm install [RELEASE_NAME] oci://ghcr.io/devops-ia/helm-steampipe/steampipe --version=[version]
```

## Uninstall Helm chart

```console
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
| affinity | object | `{}` | Affinity for pod assignment |
| args | list | `["--foreground","--show-password"]` | Arguments for Pod |
| bbdd | object | `{"enabled":false,"listen":"network","port":9193,"svcAnnotations":{}}` | Configure BBDD for Steampipe |
| command | list | `[]` | Command for Pod |
| dashboard | object | `{"enabled":false,"listen":"network","port":9194,"svcAnnotations":{}}` | Enable dashboard for Steampipe |
| deploymentAnnotations | object | `{}` | Deployment annotations |
| env | list | `[{"name":"STEAMPIPE_LOG_LEVEL","value":"TRACE"}]` | Environment variables to configure application |
| envFrom | list | `[]` | Variables from file |
| extraConfig | object | `{"configMaps":{"config":[{"data":{"openshift.spc":"connection \"openshift\" {\n  plugin      = \"openshift\"\n  config_path = \"~/.kube/config\"\n}\n"},"name":"openshift-connection","type":"Opaque"}],"enabled":false},"secrets":{"config":[{"data":{"azure.spc":"connection \"azure\" {\n  plugin          = \"azure\"\n  environment     = \"AZUREPUBLICCLOUD\"\n  tenant_id       = \"00000000-0000-0000-0000-000000000000\"\n  subscription_id = \"00000000-0000-0000-0000-000000000000\"\n  client_id       = \"00000000-0000-0000-0000-000000000000\"\n  client_secret   = \"~dummy@3password\"\n}\n"},"name":"azure-connection","type":"Opaque"},{"data":{"config":"current-context: federal-context\napiVersion: v1\nclusters:\n- cluster:\n    certificate-authority: path/to/my/cafile\n    server: https://horse.org:4443\n  name: horse-cluster\ncontexts:\n- context:\n    cluster: horse-cluster\n    namespace: chisel-ns\n    user: green-user\n  name: federal-context\nkind: Config\nusers:\n- name: green-user\n  user:\n    client-certificate: path/to/my/client/cert\n    client-key: path/to/my/client/key\n"},"name":"openshift-kubeconfig","type":"Opaque"}],"enabled":false}}` | Extra configuration for Steampipe |
| extraContainers | list | `[]` | Extra containers to add to the pod |
| extraObjects | list | `[]` | Extra Kubernetes manifests to deploy |
| extraVolumeMount | list | `[]` | Mount extra volumes |
| extraVolumes | list | `[]` | Reference volumes |
| fullnameOverride | string | `""` | String to fully override steampipe.fullname template |
| image | object | `{"pullPolicy":"IfNotPresent","repository":"ghcr.io/turbot/steampipe","tag":""}` | Image registry |
| imagePullSecrets | list | `[]` | Registry secret names as an array |
| ingress | object | `{"annotations":{},"className":"","enabled":false,"hosts":[{"host":"chart-example.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}],"tls":[]}` | Ingress configuration to expose app |
| initContainer | object | `{"extraInitVolumeMount":[],"image":{"pullPolicy":"IfNotPresent","repository":"ghcr.io/turbot/steampipe","tag":""},"mods":[],"plugins":[],"resources":{},"securityContext":{"runAsNonRoot":true,"runAsUser":9193}}` | Configure initContainers |
| initContainer.mods | list | `[]` | Configure Steampipe mods Ref: https://hub.steampipe.io/mods |
| initContainer.plugins | list | `[]` | Configure Steampipe plugins Ref: https://hub.steampipe.io/plugins |
| initContainer.resources | object | `{}` | The resources limits and requested |
| livenessProbe | object | `{}` | Configure liveness Ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-startup-probes |
| nameOverride | string | `""` | String to partially override steampipe.fullname template (will maintain the release name) |
| nodeSelector | object | `{}` | Node labels for pod assignment |
| oauth2-proxy | object | `{"alphaConfig":{"annotations":{},"configData":{},"configFile":"","enabled":false,"existingConfig":null,"existingSecret":null,"metricsConfigData":{},"serverConfigData":{}},"authenticatedEmailsFile":{"annotations":{},"enabled":false,"persistence":"configmap","restrictedUserAccessKey":"","restricted_access":"","template":""},"autoscaling":{"annotations":{},"enabled":false,"maxReplicas":10,"minReplicas":1,"targetCPUUtilizationPercentage":80},"checkDeprecation":true,"config":{"annotations":{},"clientID":"XXXXXXX","clientSecret":"XXXXXXXX","configFile":"email_domains = [ \"*\" ]\nupstreams = [ \"file:///dev/null\" ]","cookieName":"","cookieSecret":"XXXXXXXXXXXXXXXX","google":{}},"customLabels":{},"deploymentAnnotations":{},"envFrom":[],"extraArgs":{},"extraContainers":[],"extraEnv":[],"extraObjects":[],"extraVolumeMounts":[],"extraVolumes":[],"hostAliases":[],"htpasswdFile":{"enabled":false,"entries":[],"existingSecret":""},"httpScheme":"http","image":{"pullPolicy":"IfNotPresent","repository":"quay.io/oauth2-proxy/oauth2-proxy","tag":""},"ingress":{"enabled":false,"labels":{},"path":"/","pathType":"ImplementationSpecific"},"initContainers":{"waitForRedis":{"enabled":true,"image":{"pullPolicy":"IfNotPresent","repository":"alpine","tag":"latest"},"kubectlVersion":"","resources":{},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"enabled":true,"readOnlyRootFilesystem":true,"runAsGroup":65534,"runAsNonRoot":true,"runAsUser":65534,"seccompProfile":{"type":"RuntimeDefault"}},"timeout":180}},"kubeVersion":null,"livenessProbe":{"enabled":true,"initialDelaySeconds":0,"timeoutSeconds":1},"metrics":{"enabled":true,"port":44180,"service":{"appProtocol":"http"},"serviceMonitor":{"annotations":{},"bearerTokenFile":"","enabled":false,"interval":"60s","labels":{},"metricRelabelings":[],"namespace":"","prometheusInstance":"default","relabelings":[],"scheme":"","scrapeTimeout":"30s","tlsConfig":{}}},"namespaceOverride":"","nodeSelector":{},"podAnnotations":{},"podDisruptionBudget":{"enabled":true,"minAvailable":1},"podLabels":{},"podSecurityContext":{},"priorityClassName":"","proxyVarsAsSecrets":true,"readinessProbe":{"enabled":true,"initialDelaySeconds":0,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":5},"redis":{"enabled":false},"replicaCount":1,"resources":{},"revisionHistoryLimit":10,"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"enabled":true,"readOnlyRootFilesystem":true,"runAsGroup":2000,"runAsNonRoot":true,"runAsUser":2000,"seccompProfile":{"type":"RuntimeDefault"}},"service":{"annotations":{},"appProtocol":"http","externalTrafficPolicy":"","internalTrafficPolicy":"","portNumber":80,"type":"ClusterIP"},"serviceAccount":{"annotations":{},"automountServiceAccountToken":true,"enabled":true,"name":null},"sessionStorage":{"redis":{"clientType":"standalone","cluster":{"connectionUrls":[]},"existingSecret":"","password":"","passwordKey":"redis-password","sentinel":{"connectionUrls":[],"existingSecret":"","masterName":"","password":"","passwordKey":"redis-sentinel-password"},"standalone":{"connectionUrl":""}},"type":"cookie"},"strategy":{},"tolerations":[]}` | Configuration for oauth2-proxy Ref: https://github.com/oauth2-proxy/manifests/tree/oauth2-proxy-7.7.9/helm/oauth2-proxy |
| oauth2-proxy.alphaConfig | object | `{"annotations":{},"configData":{},"configFile":"","enabled":false,"existingConfig":null,"existingSecret":null,"metricsConfigData":{},"serverConfigData":{}}` | Enable alpha features |
| oauth2-proxy.authenticatedEmailsFile | object | `{"annotations":{},"enabled":false,"persistence":"configmap","restrictedUserAccessKey":"","restricted_access":"","template":""}` | To authorize individual email addresses That is part of extraArgs but since this needs special treatment we need to do a separate section |
| oauth2-proxy.autoscaling | object | `{"annotations":{},"enabled":false,"maxReplicas":10,"minReplicas":1,"targetCPUUtilizationPercentage":80}` | Horizontal Pod Autoscaling Ref: https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/ |
| oauth2-proxy.checkDeprecation | bool | `true` | Enables apiVersion deprecation checks |
| oauth2-proxy.config | object | `{"annotations":{},"clientID":"XXXXXXX","clientSecret":"XXXXXXXX","configFile":"email_domains = [ \"*\" ]\nupstreams = [ \"file:///dev/null\" ]","cookieName":"","cookieSecret":"XXXXXXXXXXXXXXXX","google":{}}` | Oauth client configuration specifics |
| oauth2-proxy.config.configFile | string | `"email_domains = [ \"*\" ]\nupstreams = [ \"file:///dev/null\" ]"` | Default configuration, to be overridden |
| oauth2-proxy.customLabels | object | `{}` | Custom labels to add into metadata |
| oauth2-proxy.deploymentAnnotations | object | `{}` | Add Deployment annotations |
| oauth2-proxy.envFrom | list | `[]` | Variables from file |
| oauth2-proxy.extraArgs | object | `{}` | Extra arguments |
| oauth2-proxy.extraContainers | list | `[]` | Additional containers to be added to the pod. |
| oauth2-proxy.extraEnv | list | `[]` | Extra enviroments |
| oauth2-proxy.extraObjects | list | `[]` | Extra Kubernetes manifests to deploy |
| oauth2-proxy.extraVolumeMounts | list | `[]` | Mount extra volumes |
| oauth2-proxy.extraVolumes | list | `[]` | Extra volumes |
| oauth2-proxy.hostAliases | list | `[]` | hostAliases is a list of aliases to be added to /etc/hosts for network name resolution |
| oauth2-proxy.htpasswdFile | object | `{"enabled":false,"entries":[],"existingSecret":""}` | Additionally authenticate against a htpasswd file. Entries must be created with "htpasswd -B" for bcrypt encryption. Alternatively supply an existing secret which contains the required information. |
| oauth2-proxy.httpScheme | string | `"http"` | Whether to use http or https |
| oauth2-proxy.image | object | `{"pullPolicy":"IfNotPresent","repository":"quay.io/oauth2-proxy/oauth2-proxy","tag":""}` | Image registry |
| oauth2-proxy.ingress | object | `{"enabled":false,"labels":{},"path":"/","pathType":"ImplementationSpecific"}` | Ingress configuration to expose app |
| oauth2-proxy.initContainers | object | `{"waitForRedis":{"enabled":true,"image":{"pullPolicy":"IfNotPresent","repository":"alpine","tag":"latest"},"kubectlVersion":"","resources":{},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"enabled":true,"readOnlyRootFilesystem":true,"runAsGroup":65534,"runAsNonRoot":true,"runAsUser":65534,"seccompProfile":{"type":"RuntimeDefault"}},"timeout":180}}` | Configure initContainers |
| oauth2-proxy.kubeVersion | string | `nil` | Force the target Kubernetes version (it uses Helm `.Capabilities` if not set). This is especially useful for `helm template` as capabilities are always empty due to the fact that it doesn't query an actual cluster |
| oauth2-proxy.livenessProbe | object | `{"enabled":true,"initialDelaySeconds":0,"timeoutSeconds":1}` | Configure livenessProbe Ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/ Disable both when deploying with Istio 1.0 mTLS. https://istio.io/help/faq/security/#k8s-health-checks |
| oauth2-proxy.metrics | object | `{"enabled":true,"port":44180,"service":{"appProtocol":"http"},"serviceMonitor":{"annotations":{},"bearerTokenFile":"","enabled":false,"interval":"60s","labels":{},"metricRelabelings":[],"namespace":"","prometheusInstance":"default","relabelings":[],"scheme":"","scrapeTimeout":"30s","tlsConfig":{}}}` | Enable metrics for Prometheus |
| oauth2-proxy.metrics.serviceMonitor.annotations | object | `{}` | Used to pass annotations that are used by the Prometheus installed in your cluster to select Service Monitors to work with Ref: https://github.com/coreos/prometheus-operator/blob/master/Documentation/api.md#prometheusspec |
| oauth2-proxy.metrics.serviceMonitor.bearerTokenFile | string | `""` | bearerTokenFile: Path to bearer token file. |
| oauth2-proxy.metrics.serviceMonitor.metricRelabelings | list | `[]` | [Metric Relabeling](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#metric_relabel_configs) |
| oauth2-proxy.metrics.serviceMonitor.relabelings | list | `[]` | [Relabeling](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#relabel_config) |
| oauth2-proxy.metrics.serviceMonitor.scheme | string | `""` | scheme: HTTP scheme to use for scraping. Can be used with `tlsConfig` for example if using istio mTLS. |
| oauth2-proxy.metrics.serviceMonitor.tlsConfig | object | `{}` | Of type: https://github.com/coreos/prometheus-operator/blob/master/Documentation/api.md#tlsconfig |
| oauth2-proxy.namespaceOverride | string | `""` | Override the deployment namespace |
| oauth2-proxy.nodeSelector | object | `{}` | Node labels for pod assignment Ref: https://kubernetes.io/docs/user-guide/node-selection/ |
| oauth2-proxy.podAnnotations | object | `{}` | Add Pod annotations |
| oauth2-proxy.podDisruptionBudget | object | `{"enabled":true,"minAvailable":1}` | PodDisruptionBudget settings Ref: https://kubernetes.io/docs/concepts/workloads/pods/disruptions/ |
| oauth2-proxy.podLabels | object | `{}` | Add Pod labels |
| oauth2-proxy.podSecurityContext | object | `{}` | Configure Kubernetes security context for pod Ref: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/ |
| oauth2-proxy.priorityClassName | string | `""` | mportance of a Pod relative to other Pods. |
| oauth2-proxy.proxyVarsAsSecrets | bool | `true` | Whether to use secrets instead of environment values for setting up OAUTH2_PROXY variables |
| oauth2-proxy.readinessProbe | object | `{"enabled":true,"initialDelaySeconds":0,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":5}` | Configure readinessProbe Ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-startup-probes |
| oauth2-proxy.redis | object | `{"enabled":false}` | Enables and configure the automatic deployment of the redis subchart |
| oauth2-proxy.replicaCount | int | `1` | Number of replicas |
| oauth2-proxy.resources | object | `{}` | The resources limits and requested |
| oauth2-proxy.revisionHistoryLimit | int | `10` | Max save Helm release revision |
| oauth2-proxy.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"enabled":true,"readOnlyRootFilesystem":true,"runAsGroup":2000,"runAsNonRoot":true,"runAsUser":2000,"seccompProfile":{"type":"RuntimeDefault"}}` | Configure Kubernetes security context for container Ref: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/ |
| oauth2-proxy.service | object | `{"annotations":{},"appProtocol":"http","externalTrafficPolicy":"","internalTrafficPolicy":"","portNumber":80,"type":"ClusterIP"}` | Kubernetes service to expose Pod |
| oauth2-proxy.serviceAccount | object | `{"annotations":{},"automountServiceAccountToken":true,"enabled":true,"name":null}` | Create or use ServiceAccount |
| oauth2-proxy.serviceAccount.enabled | bool | `true` | Specifies whether a ServiceAccount should be created |
| oauth2-proxy.serviceAccount.name | string | `nil` | If not set and create is true, a name is generated using the fullname template |
| oauth2-proxy.sessionStorage | object | `{"redis":{"clientType":"standalone","cluster":{"connectionUrls":[]},"existingSecret":"","password":"","passwordKey":"redis-password","sentinel":{"connectionUrls":[],"existingSecret":"","masterName":"","password":"","passwordKey":"redis-sentinel-password"},"standalone":{"connectionUrl":""}},"type":"cookie"}` | Configure the session storage type, between cookie and redis |
| oauth2-proxy.strategy | object | `{}` | Configure strategy to update deployment Ref: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy |
| oauth2-proxy.tolerations | list | `[]` | Tolerations for pod assignment Ref: https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/ |
| oauth2Proxy | object | `{"enabled":false}` | Deploys oauth2-proxy, a reverse proxy that provides authentication with Google, Github or other providers |
| podAnnotations | object | `{}` | Pod annotations |
| podSecurityContext | object | `{"fsGroup":9193,"runAsGroup":65534,"runAsUser":9193}` | Privilege and access control settings for a Pod or Container |
| readinessProbe | object | `{}` | Configure readinessProbe Ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-startup-probes |
| replicaCount | int | `1` | Number of replicas |
| resources | object | `{}` | The resources limits and requested |
| securityContext | object | `{"runAsNonRoot":true,"runAsUser":9193}` | Privilege and access control settings |
| serviceAccount | object | `{"annotations":{},"automountServiceAccountToken":false,"create":true,"name":""}` | Enable creation of ServiceAccount |
| startupProbe | object | `{}` | Configure startupProbe Ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-startup-probes |
| tolerations | list | `[]` | Tolerations for pod assignment |
