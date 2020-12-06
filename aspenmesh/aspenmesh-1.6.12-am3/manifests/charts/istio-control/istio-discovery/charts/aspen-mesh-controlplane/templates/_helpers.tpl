{{- define "aspen-mesh-controlplane.internalAuthType" -}}
{{- if eq .Values.userAuth.type "oauthOpenshift" -}}
    none
{{- else -}}
    {{- printf "%s" .Values.userAuth.type }}
{{- end -}}
{{- end -}}
{{- define "aspen-mesh-controlplane.imagePath" -}}
{{- if .Values.imagePath -}}
    {{- printf "%s" .Values.imagePath -}}
{{- else -}}
    {{- printf "%s:%s" .Values.global.hub .Values.image -}}
{{- end -}}
{{- end -}}
{{- define "aspen-mesh-controlplane.modelruntimeImagePath" -}}
{{- if .Values.modelruntimeImagePath -}}
    {{- printf "%s" .Values.modelruntimeImagePath -}}
{{- else -}}
    {{- printf "%s:%s" .Values.global.hub .Values.modelruntimeImage -}}
{{- end -}}
{{- end -}}
{{- define "aspen-mesh-controlplane.httpListenAddr" -}}
{{- if eq .Values.userAuth.type "oauthOpenshift" -}}
    127.0.0.1
{{- else -}}
    0.0.0.0
{{- end -}}
{{- end -}}
{{- define "aspen-mesh-controlplane.httpListenPort" -}}
{{- if eq .Values.userAuth.type "oauthOpenshift" -}}
    19002
{{- else -}}
    19001
{{- end -}}
{{- end -}}
{{- define "aspen-mesh-controlplane.httpTargetPort" -}}
{{- if eq .Values.userAuth.type "oauthOpenshift" -}}
    oauth-proxy
{{- else -}}
    http
{{- end -}}
{{- end -}}
{{- define "aspen-mesh-controlplane.validationPort" -}}
    19006
{{- end -}}
