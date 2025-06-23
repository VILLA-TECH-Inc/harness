{{/*
Expand the name of the chart.
*/}}
{{- define "policy-mgmt.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "policy-mgmt.fullname" -}}
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
{{- define "policy-mgmt.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "policy-mgmt.labels" -}}
helm.sh/chart: {{ include "policy-mgmt.chart" . }}
{{ include "policy-mgmt.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "policy-mgmt.selectorLabels" -}}
app.kubernetes.io/name: {{ include "policy-mgmt.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "policy-mgmt.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "policy-mgmt.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "policy-mgmt.pullSecrets" -}}
{{- if .Values.waitForInitContainer }}
    {{ include "common.images.pullSecrets" (dict "images" (list .Values.image .Values.waitForInitContainer.image) "global" .Values.global ) }}
{{- else }}
    {{ include "common.images.pullSecrets" (dict "images" (list .Values.image .Values.global.waitForInitContainer.image) "global" .Values.global ) }}
{{- end }}
{{- end -}}

{{/* Generates Postgres Connection string
{{ include "policy-mgmt.postgresConnection" (dict "context" $) }}
*/}}
{{- define "policy-mgmt.postgresConnection" }}
{{- $type := "postgres" }}
{{- $hosts := (pluck $type .context.Values.global.database | first ).hosts }}
{{- $dbType := upper $type }}
{{- $installed := (pluck $type .context.Values.global.database | first).installed }}
{{- if $installed  }}
{{- printf " host=postgres user=DBUSER password=DBPASSWORD dbname=policy-mgmt sslmode=disable" }}
{{- else }}
{{- $firsthostport := (index $hosts 0) -}}
{{- $hostport := split ":" $firsthostport -}}
{{- printf " host=%s user=DBUSER password=DBPASSWORD dbname=policy-mgmt sslmode=disable" $hostport._0 }}
{{- end }}
{{- end }}

{{/*
Manage policy-mgmt Secrets
USAGE:
{{- "policy-mgmt.generateSecrets" (dict "ctx" $)}}
*/}}
{{- define "policy-mgmt.generateSecrets" }}
    {{- $ := .ctx }}
    {{- $hasAtleastOneSecret := false }}
    {{- $localESOSecretCtxIdentifier := (include "harnesscommon.secrets.localESOSecretCtxIdentifier" (dict "ctx" $ )) }}
    {{- if eq (include "harnesscommon.secrets.isDefaultAppSecret" (dict "ctx" $ "variableName" "APP_TOKEN_JWT_SECRET")) "true" }}
    {{- $hasAtleastOneSecret = true }}
APP_TOKEN_JWT_SECRET: '{{ .ctx.Values.secrets.default.APP_TOKEN_JWT_SECRET | b64enc }}'
    {{- end }}
    {{- if eq (include "harnesscommon.secrets.isDefaultAppSecret" (dict "ctx" $ "variableName" "APP_INTERNAL_TOKEN_JWT_SECRET")) "true" }}
    {{- $hasAtleastOneSecret = true }}
APP_INTERNAL_TOKEN_JWT_SECRET: '{{ .ctx.Values.secrets.default.APP_INTERNAL_TOKEN_JWT_SECRET | b64enc }}'
    {{- end }}
    {{- if eq (include "harnesscommon.secrets.isDefaultAppSecret" (dict "ctx" $ "variableName" "APP_NEXT_GEN_MANAGER_JWT_SECRET")) "true" }}
    {{- $hasAtleastOneSecret = true }}
APP_NEXT_GEN_MANAGER_JWT_SECRET: '{{ .ctx.Values.secrets.default.APP_NEXT_GEN_MANAGER_JWT_SECRET | b64enc }}'
    {{- end }}
    {{- if not $hasAtleastOneSecret }}
{}
    {{- end }}
{{- end }}

