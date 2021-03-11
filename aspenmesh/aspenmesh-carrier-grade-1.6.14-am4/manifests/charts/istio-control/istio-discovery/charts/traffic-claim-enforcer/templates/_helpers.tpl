{{- define "traffic-claim-enforcer.imagePath" -}}
{{- if .Values.imagePath -}}
    {{- printf "%s" .Values.imagePath -}}
{{- else -}}
    {{- printf "%s:%s" .Values.global.hub .Values.image -}}
{{- end -}}
{{- end -}}