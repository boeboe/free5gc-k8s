#!/usr/bin/env bash

CA_CERT_DIR=./ca
F5GC_WEBUI_CERT_DIR=./f5gc-webui
CERT_DOMAIN_NAME=f5gc-webui.udf-demo.org

echo "Generate a Server Certificate for f5gc-webui"
openssl genrsa -out ${F5GC_WEBUI_CERT_DIR}/f5gc-webui.key 4096
openssl req -sha512 -new \
    -subj "/C=BE/ST=Mechelen/L=Hever/O=F5/OU=Presales/CN=${CERT_DOMAIN_NAME}" \
    -key ${F5GC_WEBUI_CERT_DIR}/f5gc-webui.key \
    -out ${F5GC_WEBUI_CERT_DIR}/f5gc-webui.csr
cat > ${F5GC_WEBUI_CERT_DIR}/f5gc-webui-v3.ext <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1=udf-demo.org
DNS.2=f5gc-webui
DNS.3=localhost
IP.1=10.1.1.4
IP.2=10.1.1.5
IP.3=10.1.1.6
IP.4=10.1.1.7
IP.5=10.1.1.8
IP.6=10.1.1.9
IP.7=127.0.0.1
EOF
openssl x509 -req -sha512 -days 3650 \
    -extfile ${F5GC_WEBUI_CERT_DIR}/f5gc-webui-v3.ext \
    -CA ${CA_CERT_DIR}/ca.crt \
    -CAkey ${CA_CERT_DIR}/ca.key \
    -CAcreateserial \
    -in ${F5GC_WEBUI_CERT_DIR}/f5gc-webui.csr \
    -out ${F5GC_WEBUI_CERT_DIR}/f5gc-webui.crt
    
openssl x509 -inform PEM -in ${F5GC_WEBUI_CERT_DIR}/f5gc-webui.crt -out ${F5GC_WEBUI_CERT_DIR}/f5gc-webui.cert



