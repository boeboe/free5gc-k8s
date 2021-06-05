{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "cassandra.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "cassandra.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "cassandra.dnsDomain" -}}
{{- if .Values.global.proxy.clusterDomain -}}
    {{- printf "%s" .Values.global.proxy.clusterDomain -}}
{{- else -}}
    cluster.local
{{- end -}}
{{- end -}}
