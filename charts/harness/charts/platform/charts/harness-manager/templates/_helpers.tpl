{{/*
Expand the name of the chart.
*/}}
{{- define "harness-manager.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "harness-manager.fullname" -}}
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
{{- define "harness-manager.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "harness-manager.labels" -}}
helm.sh/chart: {{ include "harness-manager.chart" . }}
{{ include "harness-manager.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "harness-manager-iterator.labels" -}}
helm.sh/chart: {{ include "harness-manager.chart" . }}
{{ include "harness-manager-iterator.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}-iterator
{{- end }}

{{/*
Selector labels
*/}}
{{- define "harness-manager.selectorLabels" -}}
app.kubernetes.io/name: {{ include "harness-manager.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "harness-manager-iterator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "harness-manager.name" . }}-iterator
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "harness-manager.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "harness-manager.name" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the delegate image to use
*/}}
{{- define "harness-manager.delegate_docker_image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.delegate_docker_image.image "global" .Values.global) }}
{{- end }}

{{/*
Create the name of the immutable delegate image to use
*/}}
{{- define "harness-manager.immutable_delegate_docker_image" -}}
{{- $tag := printf "%s" .Values.immutable_delegate_docker_image.image.tag }}
{{- if .Values.global.useMinimalDelegateImage }}
{{- $tag = printf "%s.minimal" $tag }}
{{- end }}
{{- $image := dict "registry" .Values.immutable_delegate_docker_image.image.registry "repository" .Values.immutable_delegate_docker_image.image.repository "tag" $tag "digest" .Values.immutable_delegate_docker_image.image.digest -}}
{{ include "common.images.image" (dict "imageRoot" $image "global" .Values.global) }}
{{- end }}

{{/*
Create the name of the delegate upgrader image to use
*/}}
{{- define "harness-manager.upgrader_docker_image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.upgrader_docker_image.image "global" .Values.global) }}
{{- end }}


## Generate ffString based of feature flag values and globally enabled features
{{- define "harness-manager.ffString" -}}
{{- $flags := .Values.featureFlags.Base }}
{{- if .Values.global.gitops.enabled }}
{{- $flags = printf "%s,%s" $flags $.Values.featureFlags.GitOps }}
{{- end }}
{{- if .Values.global.opa.enabled }}
{{- $flags = printf "%s,%s" $flags $.Values.featureFlags.OPA }}
{{- end }}
{{- if .Values.global.cd.enabled }}
{{- $flags = printf "%s,%s" $flags .Values.featureFlags.CD }}
{{- end }}
{{- if .Values.global.ci.enabled }}
{{- $flags = printf "%s,%s" $flags .Values.featureFlags.CI }}
{{- end }}
{{- if .Values.global.sto.enabled }}
{{- $flags = printf "%s,%s" $flags .Values.featureFlags.STO }}
{{- end }}
{{- if .Values.global.cd.enabled }}
{{- $flags = printf "%s,%s" $flags .Values.featureFlags.SRM }}
{{- end }}
{{- if .Values.global.ngcustomdashboard.enabled }}
{{- $flags = printf "%s,%s" $flags .Values.featureFlags.CDB }}
{{- end }}
{{- if .Values.global.ff.enabled }}
{{- $flags = printf "%s,%s" $flags .Values.featureFlags.FF }}
{{- end }}
{{- if .Values.global.ccm.enabled }}
{{- $flags = printf "%s,%s" $flags .Values.featureFlags.CCM }}
{{- end }}
{{- if .Values.global.saml.autoaccept }}
{{- $flags = printf "%s,%s" $flags .Values.featureFlags.SAMLAutoAccept }}
{{- end }}
{{- $globalLicenseESOSecretIdentifier := include "harnesscommon.secrets.globalESOSecretCtxIdentifier" (dict "ctx" $  "ctxIdentifier" "license") }}
{{- $ngLicenseENV := include "harnesscommon.secrets.manageEnv" (dict "ctx" $ "variableName" "NG_LICENSE" "overrideEnvName" "SMP_LICENSE" "providedSecretValues" (list "global.license.ng") "extKubernetesSecretCtxs" (list .Values.global.license.secrets.kubernetesSecrets) "esoSecretCtxs" (list (dict "secretCtxIdentifier" $globalLicenseESOSecretIdentifier "secretCtx" .Values.global.license.secrets.secretManagement.externalSecretsOperator)))}}
{{- if $ngLicenseENV }}
{{- $flags = printf "%s,%s" $flags .Values.featureFlags.LICENSE }}
{{- end }}
{{- if .Values.global.ng.enabled }}
{{- $flags = printf "%s,%s" $flags .Values.featureFlags.NG }}
{{- end }}
{{- if .Values.global.chaos.enabled }}
{{- $flags = printf "%s,%s" $flags .Values.featureFlags.CHAOS }}
{{- end }}
{{- if .Values.global.servicediscoverymanager.enabled }}
{{- $flags = printf "%s,%s" $flags .Values.featureFlags.SDM }}
{{- end }}
{{- if .Values.global.ssca.enabled }}
{{- $flags = printf "%s,%s" $flags .Values.featureFlags.SSCA }}
{{- end }}
{{- if .Values.global.idp.enabled }}
{{- $flags = printf "%s,%s" $flags .Values.featureFlags.IDP }}
{{- end }}
{{- if .Values.global.dbops.enabled }}
{{- $flags = printf "%s,%s" $flags .Values.featureFlags.DBOPS }}
{{- end }}
{{- $length2 := len .Values.featureFlags.ADDITIONAL }}
{{- if gt $length2 0}}
{{- $flags = printf "%s,%s" $flags .Values.featureFlags.ADDITIONAL }}
{{- end }}
{{- printf "%s" $flags }}
{{- end }}

{{- define "harness-manager.pullSecrets" -}}
{{- if .Values.waitForInitContainer }}
    {{ include "common.images.pullSecrets" (dict "images" (list .Values.image .Values.waitForInitContainer.image) "global" .Values.global ) }}
{{- else }}
    {{ include "common.images.pullSecrets" (dict "images" (list .Values.image .Values.global.waitForInitContainer.image) "global" .Values.global ) }}
{{- end }}
{{- end -}}
{{/*
Manage Harness Manager Secrets

USAGE:
{{- "harness-manager.generateSecrets" (dict "ctx" $)}}
*/}}
{{- define "harness-manager.generateSecrets" }}
    {{- $ := .ctx }}
    {{- $hasAtleastOneSecret := false }}
    {{- $localESOSecretCtxIdentifier := (include "harnesscommon.secrets.localESOSecretCtxIdentifier" (dict "ctx" $ )) }}
    {{- if eq (include "harnesscommon.secrets.isDefaultAppSecret" (dict "ctx" $ "variableName" "LOG_STREAMING_SERVICE_TOKEN")) "true" }}
    {{- $hasAtleastOneSecret = true }}
LOG_STREAMING_SERVICE_TOKEN: {{ .ctx.Values.secrets.default.LOG_STREAMING_SERVICE_TOKEN | b64enc }}
    {{- end }}
    {{- if eq (include "harnesscommon.secrets.isDefaultAppSecret" (dict "ctx" $ "variableName" "VERIFICATION_SERVICE_SECRET")) "true" }}
    {{- $hasAtleastOneSecret = true }}
VERIFICATION_SERVICE_SECRET: {{ .ctx.Values.secrets.default.VERIFICATION_SERVICE_SECRET | b64enc }}
    {{- end }}
    {{- if eq (include "harnesscommon.secrets.isDefaultAppSecret" (dict "ctx" $ "variableName" "CF_CLIENT_API_KEY")) "true" }}
    {{- $hasAtleastOneSecret = true }}
CF_CLIENT_API_KEY: {{ .ctx.Values.secrets.default.CF_CLIENT_API_KEY | b64enc }}
    {{- end }}

    {{- if not $hasAtleastOneSecret }}
{}
    {{- end }}
{{- end }}

{{/*
Manage Harness Manager Iterator Configs
USAGE:
{{- include "harness-manager.generateIteratorConfig" (dict "ctx" $ "iteratorList" .Values.iterator.iteratorList)}}
*/}}
{{- define "harness-manager.generateIteratorConfig" }}
{{- $ := .ctx }}
{{- $iteratorObjectsToJson := list }}
{{- range $k, $v := .iteratorList }}
{{- $_ := set $v "name" $k }}
{{- $iteratorObjectsToJson = append $iteratorObjectsToJson $v }}
{{- end }}
{{- $iteratorObjectsToJson | toPrettyJson }}
{{- end }}
