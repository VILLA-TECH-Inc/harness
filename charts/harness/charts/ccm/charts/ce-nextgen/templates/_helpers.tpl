{{/*
Expand the name of the chart.
*/}}
{{- define "nextgen-ce.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "nextgen-ce.fullname" -}}
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
{{- define "nextgen-ce.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "nextgen-ce.labels" -}}
helm.sh/chart: {{ include "nextgen-ce.chart" . }}
{{ include "nextgen-ce.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "nextgen-ce.selectorLabels" -}}
app.kubernetes.io/name: {{ include "nextgen-ce.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "nextgen-ce.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "nextgen-ce.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "nextgen-ce.deploymentEnv" -}}
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
        name: postgres
        key: postgres-password
- { name: APP_DATABASE_DATASOURCE, value: "{{ printf "postgres://postgres:$(DB_PASSWORD)@postgres:5432" }}" }
- { name: APP_DB_MIGRATION_DATASOURCE, value: "{{ printf "postgres://postgres:$(DB_PASSWORD)@postgres:5432" }}" }
{{- end }}

{{- define "nextgen-ce.generateMountSecrets" }}
    {{- if and (not .Values.workloadIdentity.enabled) (not .Values.secretsFromHelper.disabled) }}
    ceng-gcp-credentials: {{ include "harnesscommon.secrets.passwords.manage" (dict "secret" "ceng-secret-mount" "key" "ceng-gcp-credentials" "providedValues" (list "ceng-gcp-credentials") "length" 10 "context" $) }}
    {{- end }}
{{- end }}

{{- define "nextgen-ce.pullSecrets" -}}
{{- if .Values.waitForInitContainer }}
    {{ include "common.images.pullSecrets" (dict "images" (list .Values.image .Values.waitForInitContainer.image) "global" .Values.global ) }}
{{- else }}
    {{ include "common.images.pullSecrets" (dict "images" (list .Values.image .Values.global.waitForInitContainer.image) "global" .Values.global ) }}
{{- end }}
{{- end -}}


{{/*
Manage nextgen-ce Secrets
USAGE:
{{- "nextgen-ce.generateSecrets" (dict "ctx" $)}}
default LOG_STREAMING_SERVICE_TOKEN was c76e567a-b341-404d-a8dd-d9738714eb82 and
*/}}
{{- define "nextgen-ce.generateSecrets" }}
    {{- $ := .ctx }}
AWS_ACCESS_KEY: {{ include "harnesscommon.secrets.passwords.manage" (dict "secret" "nextgen-ce" "key" "AWS_ACCESS_KEY" "providedValues" (list "awsSecret.AWS_ACCESS_KEY") "length" 10 "context" $) }}
AWS_SECRET_KEY: {{ include "harnesscommon.secrets.passwords.manage" (dict "secret" "nextgen-ce" "key" "AWS_SECRET_KEY" "providedValues" (list "awsSecret.AWS_SECRET_KEY") "length" 10 "context" $) }}
AWS_ACCOUNT_ID: {{ include "harnesscommon.secrets.passwords.manage" (dict "secret" "nextgen-ce" "key" "AWS_ACCOUNT_ID" "providedValues" (list "awsSecret.AWS_ACCOUNT_ID") "length" 10 "context" $) }}
AWS_DESTINATION_BUCKET: {{ include "harnesscommon.secrets.passwords.manage" (dict "secret" "nextgen-ce" "key" "AWS_DESTINATION_BUCKET" "providedValues" (list "awsSecret.AWS_DESTINATION_BUCKET") "length" 10 "context" $) }}
AWS_TEMPLATE_LINK: {{ include "harnesscommon.secrets.passwords.manage" (dict "secret" "nextgen-ce" "key" "AWS_TEMPLATE_LINK" "providedValues" (list "awsSecret.AWS_TEMPLATE_LINK") "length" 10 "context" $) }}
CE_AWS_TEMPLATE_URL: {{ include "harnesscommon.secrets.passwords.manage" (dict "secret" "nextgen-ce" "key" "CE_AWS_TEMPLATE_URL" "providedValues" (list "awsSecret.CE_AWS_TEMPLATE_URL") "length" 10 "context" $) }}
AZURE_APP_CLIENT_SECRET: {{ include "harnesscommon.secrets.passwords.manage" (dict "secret" "nextgen-ce" "key" "AZURE_APP_CLIENT_SECRET" "providedValues" (list "azureSecret.AZURE_APP_CLIENT_SECRET") "length" 10 "context" $) }}
    {{- $hasAtleastOneSecret := true }}
    {{- $localESOSecretCtxIdentifier := (include "harnesscommon.secrets.localESOSecretCtxIdentifier" (dict "ctx" $ )) }}
    {{- if eq (include "harnesscommon.secrets.isDefaultAppSecret" (dict "ctx" $ "variableName" "JWT_AUTH_SECRET")) "true" }}
    {{- $hasAtleastOneSecret = true }}
JWT_AUTH_SECRET: '{{ .ctx.Values.secrets.default.JWT_AUTH_SECRET | b64enc }}'
    {{- end }}
    {{- if eq (include "harnesscommon.secrets.isDefaultAppSecret" (dict "ctx" $ "variableName" "NEXT_GEN_MANAGER_SECRET")) "true" }}
    {{- $hasAtleastOneSecret = true }}
NEXT_GEN_MANAGER_SECRET: '{{ .ctx.Values.secrets.default.NEXT_GEN_MANAGER_SECRET | b64enc }}'
    {{- end }}
    {{- if eq (include "harnesscommon.secrets.isDefaultAppSecret" (dict "ctx" $ "variableName" "JWT_IDENTITY_SERVICE_SECRET")) "true" }}
    {{- $hasAtleastOneSecret = true }}
JWT_IDENTITY_SERVICE_SECRET: '{{ .ctx.Values.secrets.default.JWT_IDENTITY_SERVICE_SECRET | b64enc }}'
    {{- end }}
    {{- if eq (include "harnesscommon.secrets.isDefaultAppSecret" (dict "ctx" $ "variableName" "NOTIFICATION_CLIENT_SECRET")) "true" }}
    {{- $hasAtleastOneSecret = true }}
NOTIFICATION_CLIENT_SECRET: '{{ .ctx.Values.secrets.default.NOTIFICATION_CLIENT_SECRET | b64enc }}'
    {{- end }}
    {{- if eq (include "harnesscommon.secrets.isDefaultAppSecret" (dict "ctx" $ "variableName" "ACCESS_CONTROL_SECRET")) "true" }}
    {{- $hasAtleastOneSecret = true }}
ACCESS_CONTROL_SECRET: '{{ .ctx.Values.secrets.default.ACCESS_CONTROL_SECRET | b64enc }}'
    {{- end }}
    {{- if not $hasAtleastOneSecret }}
{}
    {{- end }}
{{- end }}
