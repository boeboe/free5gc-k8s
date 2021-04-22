{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "free5gc.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "free5gc.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create unified labels for free5gc components
*/}}
{{- define "free5gc.common.matchLabels" -}}
app: {{ template "free5gc.name" . }}
release: {{ .Release.Name }}
{{- end -}}

{{- define "free5gc.common.metaLabels" -}}
chart: {{ template "free5gc.chart" . }}
heritage: {{ .Release.Service }}
{{- end -}}

{{- define "free5gc.f5gc-amf.matchLabels" -}}
component: {{ .Values.f5gc-amf.name | quote }}
{{ include "free5gc.common.matchLabels" . }}
{{- end -}}

{{- define "free5gc.f5gc-amf.labels" -}}
{{ include "free5gc.f5gc-amf.matchLabels" . }}
{{ include "free5gc.common.metaLabels" . }}
{{- end -}}



{{/*
Create a fully qualified f5gc-amf name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "free5gc.f5gc-amf.fullname" -}}
{{- if .Values.f5gc-amf.fullnameOverride -}}
{{- .Values.f5gc-amf.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- printf "%s-%s" .Release.Name .Values.f5gc-amf.name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.f5gc-amf.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}



{{/*
Return the appropriate apiVersion for deployment.
*/}}
{{- define "prometheus.deployment.apiVersion" -}}
{{- print "apps/v1" -}}
{{- end -}}
{{/*
Return the appropriate apiVersion for rbac.
*/}}
{{- define "rbac.apiVersion" -}}
{{- if .Capabilities.APIVersions.Has "rbac.authorization.k8s.io/v1" }}
{{- print "rbac.authorization.k8s.io/v1" -}}
{{- else -}}
{{- print "rbac.authorization.k8s.io/v1beta1" -}}
{{- end -}}
{{- end -}}



{{/*
Create the name of the service account to use for the f5gc-amf component
*/}}
{{- define "free5gc.serviceAccountName.f5gc-amf" -}}
{{- if .Values.serviceAccounts.f5gc-amf.create -}}
    {{ default (include "free5gc.f5gc-amf.fullname" .) .Values.serviceAccounts.f5gc-amf.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccounts.f5gc-amf.name }}
{{- end -}}
{{- end -}}



{{/*
Define the free5gc.namespace template if set with forceNamespace or .Release.Namespace is set
*/}}
{{- define "free5gc.namespace" -}}
{{- if .Values.forceNamespace -}}
{{ printf "namespace: %s" .Values.forceNamespace }}
{{- else -}}
{{ printf "namespace: %s" .Release.Namespace }}
{{- end -}}
{{- end -}}

