{{/*
This file and its contents are licensed under the Apache License 2.0.
Please see the included NOTICE for copyright information and LICENSE for a copy of the license.
*/}}
{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "timescaledb.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "clusterName" -}}
{{- default .Release.Name .Values.clusterName | trunc 63 -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "timescaledb.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "timescaledb.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the name of the service account to use.
*/}}
{{- define "timescaledb.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "timescaledb.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{- define "socket_directory" -}}
/var/run/postgresql
{{- end -}}

{{- define "pod_environment_file" -}}
${HOME}/.pod_environment
{{- end -}}

{{- define "pgbackrest_environment_file" -}}
${HOME}/.pgbackrest_environment
{{- end -}}

{{- define "pgbackrest_bootstrap_environment_dir" -}}
/etc/pgbackrest/bootstrap
{{- end -}}

{{- define "postgres.uid" -}}
{{- default .Values.uid "1000" -}}
{{- end -}}

{{- define "data_directory" -}}
{{ printf "%s/data" .Values.persistentVolumes.data.mountPath }}
{{- end -}}

{{- define "callbacks_dir" -}}
/etc/timescaledb/callbacks
{{- end -}}

{{- define "tablespaces_dir" -}}
{{ printf "%s/tablespaces" .Values.persistentVolumes.data.mountPath }}
{{- end -}}

{{- define "scripts_dir" -}}
/etc/timescaledb/scripts
{{- end -}}

{{- define "post_init_dir" -}}
/etc/timescaledb/post_init.d
{{- end -}}

{{- define "wal_directory" -}}
{{ printf "%s/pg_wal" .Values.persistentVolumes.wal.mountPath }}
{{- end -}}

{{- define "tstune_config" -}}
{{ printf "%s/timescaledb.conf" (include "socket_directory" .) }}
{{- end -}}

{{- define "wal_status_file" -}}
{{ printf "%s/wal_status" (include "socket_directory" .) }}
{{- end -}}

{{- define "secrets_credentials" -}}
{{ tpl .Values.secrets.credentialsSecretName . | default (printf "%s-credentials" (include "clusterName" .)) | quote }}
{{- end -}}

{{- define "secrets_certificate" -}}
{{ .Values.secrets.certificateSecretName | default (printf "%s-certificate" (include "clusterName" .)) | quote }}
{{- end -}}

{{- define "secrets_pgbackrest" -}}
{{ .Values.secrets.pgbackrestSecretName | default (printf "%s-pgbackrest" (include "clusterName" .)) | quote }}
{{- end -}}

{{/*
Generate common labels to be used
*/}}
{{- define "timescaledb.labels" -}}
app: {{ include "clusterName" . }}
chart: {{ template "timescaledb.chart" . }}
release: {{ .Release.Name }}
heritage: {{ .Release.Service }}
cluster-name: {{ template "clusterName" . }}
{{- end }}

{{- define "timescaledb-helm.labels" -}}
{{ include "timescaledb.labels" . }}
app.kubernetes.io/name: {{ include "timescaledb.fullname" . | quote }}
app.kubernetes.io/version: {{ .Chart.Version }}
{{- end }}

{{- define "timescaledb.pullSecrets" -}}
{{ include "common.images.pullSecrets" (dict "images" (list .Values.image ) "global" .Values.global ) }}
{{- end -}}

{{- define "timescaledb.jobPullSecrets" -}}
{{ include "common.images.pullSecrets" (dict "images" (list .Values.curlImage ) "global" .Values.global ) }}
{{- end -}}

{{- define "timescaledb.archivePullSecrets" -}}
{{ include "common.images.pullSecrets" (dict "images" (list .Values.archiveCleanup ) "global" .Values.global ) }}
{{- end -}}

{{- define "patroni.config" -}}
{{- $updatedPatroni := .Values.patroni -}}
{{- if not .Values.archive_enabled -}}
{{- $override := (dict "bootstrap" (dict "dcs" (dict "postgresql" (dict "parameters" (dict "archive_mode" "off"))))) -}}
{{- $updatedPatroni = (mergeOverwrite .Values.patroni $override) -}}
{{- end -}}
{{ $updatedPatroni | toYaml }}
{{- end -}}