{{- define "aspen-mesh-packet-inspector.imagePath" -}}
{{- if .Values.imagePath -}}
    {{- printf "%s" .Values.imagePath -}}
{{- else -}}
    {{- printf "%s:%s" .Values.global.hub .Values.image -}}
{{- end -}}
{{- end -}}
