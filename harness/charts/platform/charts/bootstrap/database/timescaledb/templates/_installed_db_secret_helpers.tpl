{{/*
Check if only one valid ESO Secret is provided in the secrets context

Returns: bool

Example:
{{ include "harnesscommon.secrets.hasSingleValidESOSecret" (dict "secretsCtx" .Values.secrets) }}
*/}}
{{- define "harnesscommon.secrets.hasSingleValidESOSecret" }}
  {{- $secretsCtx := .secretsCtx }}
  {{- $hasSingleValidESOSecret := "false" }}
  {{- if and $secretsCtx $secretsCtx.secretManagement $secretsCtx.secretManagement.externalSecretsOperator (eq (len $secretsCtx.secretManagement.externalSecretsOperator) 1) }}
    {{- $externalSecret := first $secretsCtx.secretManagement.externalSecretsOperator }}
        {{- $hasSingleValidESOSecret = include "harnesscommon.secrets.hasValidESOSecret" (dict "esoSecretCtx" $externalSecret) }}
  {{- end }}
  {{- print $hasSingleValidESOSecret }}
{{- end }}

{{/*
{{ include "harnesscommon.secrets.hasValidExtK8SSecret" (dict "extKubernetesSecretCtx" .Values.secrets) }}
*/}}
{{- define "harnesscommon.secrets.hasValidExtK8SSecret" }}
  {{- $extKubernetesSecretCtx := .extKubernetesSecretCtx }}
  {{- $hasValidExtKubernetesSecret := "false" }}
  {{- if and (dig "secretName" "" $extKubernetesSecretCtx) (dig "keys" "" $extKubernetesSecretCtx) }}
    {{- range $key, $value := $extKubernetesSecretCtx.keys }}
      {{- if $value }}
          {{- $hasValidExtKubernetesSecret = "true" }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- print $hasValidExtKubernetesSecret }}
{{- end }}

{{/*
Check if only one valid External K8S Secret is provided in the secrets context

Returns: bool

Example:
{{ include "harnesscommon.secrets.hasSingleValidExtK8SSecret" (dict "secretsCtx" .Values.secrets) }}
*/}}
{{- define "harnesscommon.secrets.hasSingleValidExtK8SSecret" }}
  {{- $secretsCtx := .secretsCtx }}
  {{- $hasSingleValidExtK8SSecret := "false" }}
  {{- if and $secretsCtx $secretsCtx.kubernetesSecrets (eq (len $secretsCtx.kubernetesSecrets) 1) }}
    {{- $externalSecret := first $secretsCtx.kubernetesSecrets }}
    {{- $hasSingleValidExtK8SSecret = include "harnesscommon.secrets.hasValidExtK8SSecret" (dict "extKubernetesSecretCtx" $externalSecret) }}
  {{- end }}
  {{- print $hasSingleValidExtK8SSecret }}
{{- end }}

{{/*
Returns Name of the Secret to use for Harness Installed DB

USAGE:
{{ include "harnesscommon.secrets.TsdbArchiveDbSecret" (dict "ctx" $ "dbKey" "mongo") "defaultSecret" "mongodb-replicaset-chart" }}
*/}}
{{- define "harnesscommon.secrets.TsdbArchiveDbSecret" }}
  {{- $defaultSecret := .defaultSecret }}
  {{- $dbSecretsCtx := (dig "secrets" false .ctx) }}
  {{- if $dbSecretsCtx }}
    {{- $secretName := "" }}
    {{- if eq (include "harnesscommon.secrets.hasSingleValidESOSecret" (dict "secretsCtx" $dbSecretsCtx)) "true" }}
      {{- $secretName = include "harnesscommon.secrets.globalESOSecretCtxIdentifier" (dict "ctx" $  "ctxIdentifier" .dbKey) }}
    {{- else if eq (include "harnesscommon.secrets.hasSingleValidExtK8SSecret" (dict "secretsCtx" $dbSecretsCtx)) "true" }}
      {{- $extK8SSecret := first $dbSecretsCtx.kubernetesSecrets }}
      {{- $secretName = (dig "secretName" "" $extK8SSecret) }}
    {{- else if $defaultSecret }}
      {{- $secretName = $defaultSecret }}
    {{- end }}
    {{- print $secretName }}
  {{- end }}
{{- end }}
