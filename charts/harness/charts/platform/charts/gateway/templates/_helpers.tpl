{{/*
Expand the name of the chart.
*/}}
{{- define "gateway.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "gateway.fullname" -}}
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
{{- define "gateway.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "gateway.labels" -}}
helm.sh/chart: {{ include "gateway.chart" . }}
{{ include "gateway.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "gateway.selectorLabels" -}}
app.kubernetes.io/name: {{ include "gateway.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "gateway.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "gateway.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Manage gateway Secrets
USAGE:
{{- "gateway.generateSecrets" (dict "ctx" $)}}
*/}}

{{- define "gateway.generateSecrets" }}
    {{- $ := .ctx }}
    {{- $hasAtleastOneSecret := false }}
    {{- $localESOSecretCtxIdentifier := (include "harnesscommon.secrets.localESOSecretCtxIdentifier" (dict "ctx" $ )) }}
    {{- if eq (include "harnesscommon.secrets.isDefaultAppSecret" (dict "ctx" $ "variableName" "LOG_SVC_GLOBAL_TOKEN" "extKubernetesSecretCtxs" (list $.Values.secrets.kubernetesSecrets) "esoSecretCtxs" (list (dict $localESOSecretCtxIdentifier $.Values.secrets.secretManagement.externalSecretsOperator)))) "true" }}
    {{- $hasAtleastOneSecret = true }}
LOG_SVC_GLOBAL_TOKEN: {{ .ctx.Values.secrets.default.LOG_SVC_GLOBAL_TOKEN | b64enc }}
    {{- end }}
    {{- if eq (include "harnesscommon.secrets.isDefaultAppSecret" (dict "ctx" $ "variableName" "TI_SVC_GLOBAL_TOKEN" "extKubernetesSecretCtxs" (list $.Values.secrets.kubernetesSecrets) "esoSecretCtxs" (list (dict $localESOSecretCtxIdentifier $.Values.secrets.secretManagement.externalSecretsOperator)))) "true" }}
    {{- $hasAtleastOneSecret = true }}
TI_SVC_GLOBAL_TOKEN: {{ .ctx.Values.secrets.default.TI_SVC_GLOBAL_TOKEN | b64enc }}
    {{- end }}
    {{- if eq (include "harnesscommon.secrets.isDefaultAppSecret" (dict "ctx" $ "variableName" "JWT_ADMIN_PORTAL_SECRET" "extKubernetesSecretCtxs" (list $.Values.secrets.kubernetesSecrets) "esoSecretCtxs" (list (dict $localESOSecretCtxIdentifier $.Values.secrets.secretManagement.externalSecretsOperator)))) "true" }}
    {{- $hasAtleastOneSecret = true }}
JWT_ADMIN_PORTAL_SECRET: {{ .ctx.Values.secrets.default.JWT_ADMIN_PORTAL_SECRET | b64enc }}
    {{- end }}
    {{- if eq (include "harnesscommon.secrets.isDefaultAppSecret" (dict "ctx" $ "variableName" "JWT_DATA_HANDLER_SECRET" "extKubernetesSecretCtxs" (list $.Values.secrets.kubernetesSecrets) "esoSecretCtxs" (list (dict $localESOSecretCtxIdentifier $.Values.secrets.secretManagement.externalSecretsOperator)))) "true" }}
    {{- $hasAtleastOneSecret = true }}
JWT_DATA_HANDLER_SECRET: {{ .ctx.Values.secrets.default.JWT_DATA_HANDLER_SECRET | b64enc }}
    {{- end }}
    {{- if not $hasAtleastOneSecret }}
{}
    {{- end }}
{{- end }}

{{- define "gateway.pullSecrets" -}}
{{- if .Values.waitForInitContainer }}
    {{ include "common.images.pullSecrets" (dict "images" (list .Values.image .Values.waitForInitContainer.image) "global" .Values.global ) }}
{{- else }}
    {{ include "common.images.pullSecrets" (dict "images" (list .Values.image .Values.global.waitForInitContainer.image) "global" .Values.global ) }}
{{- end }}
{{- end -}}

{{- define "gateway.managerUrl" -}}
{{- $managerUrl := (default .Values.loadbalancerURL .Values.global.loadbalancerURL) }}
{{- if .Values.global.ingress.enabled -}}
{{- $managerUrl = (default $managerUrl .Values.global.ingress.ingressGatewayServiceUrl) -}}
{{- else -}}
{{- $managerUrl = (default $managerUrl .Values.global.istio.istioGatewayServiceUrl) -}}
{{- end -}}
{{- if .Values.global.globalIngress.enabled -}}
{{- $managerUrl = "http://harness-ingress-controller" -}}
{{- end -}}
{{- printf "%s" $managerUrl -}}
{{- end -}}

{{- define "gateway.redisPort" -}}
{{- if .context.installed -}}
  {{- printf "26379" -}}
{{- else -}}
  {{- $firsthost := (index .context.hosts 0) -}}
  {{- $parts := split ":" $firsthost -}}
  {{- printf "%s" $parts._1 -}}
{{- end -}}
{{- end -}}

{{- define "gateway.redisHost" -}}
{{- $extraArgs := .context.extraArgs -}}
{{- if .context.installed -}}
  {{- $type := "redis" -}}
  {{- $hosts := list "redis-sentinel-harness-announce-0" "redis-sentinel-harness-announce-1" "redis-sentinel-harness-announce-2" }}
  {{- include "harnesscommon.dbconnection.connection" (dict "type" $type "hosts" $hosts "protocol" "" "extraArgs" $extraArgs "userVariableName" .context.userVariableName "passwordVariableName" .context.passwordVariableName "connectionType" "list") }}
{{- else -}}
  {{- $firsthost := (index .context.hosts 0) -}}
  {{- $parts := split ":" $firsthost -}}
  {{- $connectionString := (include "harnesscommon.dbconnection.singleConnectString" (dict "protocol" "" "host" $parts._0 "userVariableName" .context.userVariableName "passwordVariableName" .context.passwordVariableName) ) }}
  {{- if $extraArgs -}}
    {{- $connectionString = (printf "%s%s" $connectionString $extraArgs ) -}}
  {{- end -}}
  {{- printf "%s" $connectionString -}}
{{- end -}}
{{- end -}}