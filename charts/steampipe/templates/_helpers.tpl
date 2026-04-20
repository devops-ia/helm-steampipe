{{/*
Expand the name of the chart.
*/}}
{{- define "steampipe.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "steampipe.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "steampipe.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "steampipe.labels" -}}
helm.sh/chart: {{ include "steampipe.chart" . }}
{{ include "steampipe.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "steampipe.selectorLabels" -}}
app.kubernetes.io/name: {{ include "steampipe.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "steampipe.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "steampipe.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Fully qualified name for Powerpipe resources.
*/}}
{{- define "steampipe.powerpipe.fullname" -}}
{{- printf "%s-powerpipe" (include "steampipe.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Selector labels for Powerpipe resources.
*/}}
{{- define "steampipe.powerpipe.selectorLabels" -}}
app.kubernetes.io/name: {{ include "steampipe.name" . }}-powerpipe
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Labels for Powerpipe resources (includes chart + version metadata).
*/}}
{{- define "steampipe.powerpipe.labels" -}}
helm.sh/chart: {{ include "steampipe.chart" . }}
{{ include "steampipe.powerpipe.selectorLabels" . }}
{{- if .Values.powerpipe.image.tag }}
app.kubernetes.io/version: {{ .Values.powerpipe.image.tag | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

