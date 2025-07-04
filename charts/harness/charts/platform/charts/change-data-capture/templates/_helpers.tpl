{{/*
Expand the name of the chart.
*/}}
{{- define "change-data-capture.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Expand the name of the chart.
*/}}
{{- define "change-data-capture-pms.name" -}}
    {{ include "change-data-capture.name" . | trunc 59 | trimSuffix "-" }}-pms
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "change-data-capture.fullname" -}}
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
{{- define "change-data-capture.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "change-data-capture.labels" -}}
helm.sh/chart: {{ include "change-data-capture.chart" . }}
{{ include "change-data-capture.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "change-data-capture.selectorLabels" -}}
app.kubernetes.io/name: {{ include "change-data-capture.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "change-data-capture.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "change-data-capture.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Manage change-data-capture Secrets
USAGE:
{{- "change-data-capture.generateSecrets" (dict "ctx" $)}}
*/}}

{{- define "change-data-capture.generateSecrets" }}
    {{- $ := .ctx }}
    {{- $hasAtleastOneSecret := false }}
    {{- $localESOSecretCtxIdentifier := (include "harnesscommon.secrets.localESOSecretCtxIdentifier" (dict "ctx" $ )) }}
    {{- if not $hasAtleastOneSecret }}
{}
    {{- end }}
{{- end }}

{{- define "change-data-capture.pullSecrets" -}}
{{- if .Values.waitForInitContainer }}
    {{ include "common.images.pullSecrets" (dict "images" (list .Values.image .Values.waitForInitContainer.image) "global" .Values.global ) }}
{{- else }}
    {{ include "common.images.pullSecrets" (dict "images" (list .Values.image .Values.global.waitForInitContainer.image) "global" .Values.global ) }}
{{- end }}
{{- end -}}
