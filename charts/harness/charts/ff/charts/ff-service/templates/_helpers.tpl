{{/*
Expand the name of the chart.
*/}}
{{- define "ff-service.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "ff-service.fullname" -}}
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
{{- define "ff-service.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "ff-service.labels" -}}
helm.sh/chart: {{ include "ff-service.chart" . }}
{{ include "ff-service.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "ff-service.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ff-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "ff-service.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "ff-service.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the sentinet image to use
*/}}
{{- define "ff-service.securityImage" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.securityImage.image "global" .Values.global) }}
{{- end }}

{{- define "ff-service.pullSecrets" -}}
{{- if .Values.waitForInitContainer }}
    {{ include "common.images.pullSecrets" (dict "images" (list .Values.image .Values.waitForInitContainer.image  .Values.jobs.timescaledb_migrate.image .Values.jobs.postgres_migration.image ) "global" .Values.global ) }}
{{- else }}
    {{ include "common.images.pullSecrets" (dict "images" (list .Values.image .Values.global.waitForInitContainer.image  .Values.jobs.timescaledb_migrate.image .Values.jobs.postgres_migration.image ) "global" .Values.global ) }}
{{- end }}
{{- end -}}

{{/*
Manage ff-service Secrets
USAGE:
{{- "ff-service.generateSecrets" (dict "ctx" $)}}
*/}}
{{- define "ff-service.generateSecrets" }}
    {{- $ := .ctx }}
    {{- $hasAtleastOneSecret := false }}
    {{- $localESOSecretCtxIdentifier := (include "harnesscommon.secrets.localESOSecretCtxIdentifier" (dict "ctx" $ )) }}
    {{- if eq (include "harnesscommon.secrets.isDefaultAppSecret" (dict "ctx" $ "variableName" "PLATFORM_SECRET_KEY")) "true" }}
    {{- $hasAtleastOneSecret = true }}
PLATFORM_SECRET_KEY: {{ .ctx.Values.secrets.default.PLATFORM_SECRET_KEY | b64enc }}
    {{- end }}
    {{- if eq (include "harnesscommon.secrets.isDefaultAppSecret" (dict "ctx" $ "variableName" "AUTH_SECRET")) "true" }}
    {{- $hasAtleastOneSecret = true }}
AUTH_SECRET: {{ .ctx.Values.secrets.default.AUTH_SECRET | b64enc }}
    {{- end }}
    {{- if eq (include "harnesscommon.secrets.isDefaultAppSecret" (dict "ctx" $ "variableName" "POLICY_MGMT_SECRET")) "true" }}
    {{- $hasAtleastOneSecret = true }}
POLICY_MGMT_SECRET: {{ .ctx.Values.secrets.default.POLICY_MGMT_SECRET | b64enc }}
    {{- end }}
    {{- if not $hasAtleastOneSecret }}
{}
    {{- end }}
{{- end }}