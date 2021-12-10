{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "aspen-mesh-metrics-collector.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "aspen-mesh-metrics-collector.fullname" -}}
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
{{- define "aspen-mesh-metrics-collector.chart" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "aspen-mesh-metrics-collector.proxyImagePath" -}}
{{- if .Values.proxyImagePath -}}
    {{- printf "%s" .Values.proxyImagePath -}}
{{- else -}}
    {{- printf "%s:%s" .Values.global.hub .Values.proxyImage -}}
{{- end -}}
{{- end -}}

{{- define "aspen-mesh-metrics-collector.serviceImagePath" -}}
{{- if .Values.serviceImagePath -}}
    {{- printf "%s" .Values.serviceImagePath -}}
{{- else -}}
    {{- printf "%s:%s" .Values.global.hub .Values.serviceImage -}}
{{- end -}}
{{- end -}}

{{- define "aspen-mesh-metrics-collector.controlPlaneInstance" -}}
{{- if .Values.controlPlaneInstance -}}
    {{- printf "%s" .Values.controlPlaneInstance -}}
{{- else -}}
    {{- printf "aspen-mesh-controlplane.%s:19005" .Release.Namespace -}}
{{- end -}}
{{- end -}}
