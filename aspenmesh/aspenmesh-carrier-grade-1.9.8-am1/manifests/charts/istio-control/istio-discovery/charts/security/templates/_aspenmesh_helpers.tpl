{{- define "security.customDnsNames" -}}
{{- if .Values.global.customDnsNames -}}
    {{- range $index, $secretdns := .Values.global.customDnsNames -}}
        {{- printf ",%s.%s:%s" $secretdns.serviceAccountName $secretdns.serviceAccountNamespace $secretdns.dnsName }}
    {{- end -}}
{{- end -}}
{{- end -}}
