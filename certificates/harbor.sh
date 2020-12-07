#!/usr/bin/env bash

CA_CERT_DIR=./ca
HARBOR_CERT_DIR=./harbor
CERT_DOMAIN_NAME=harbor.udf-demo.org

echo "Generate a Server Certificate for harbor"
openssl genrsa -out ${HARBOR_CERT_DIR}/harbor.key 4096
openssl req -sha512 -new \
    -subj "/C=BE/ST=Mechelen/L=Hever/O=F5/OU=Presales/CN=${CERT_DOMAIN_NAME}" \
    -key ${HARBOR_CERT_DIR}/harbor.key \
    -out ${HARBOR_CERT_DIR}/harbor.csr
cat > ${HARBOR_CERT_DIR}/harbor-v3.ext <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1=harbor.udf-demo.org
DNS.2=udf-demo.org
DNS.3=harbor
DNS.4=localhost
IP.1=10.1.1.4
IP.2=10.1.10.4
IP.3=127.0.0.1
EOF
openssl x509 -req -sha512 -days 3650 \
    -extfile ${HARBOR_CERT_DIR}/harbor-v3.ext \
    -CA ${CA_CERT_DIR}/ca.crt \
    -CAkey ${CA_CERT_DIR}/ca.key \
    -CAcreateserial \
    -in ${HARBOR_CERT_DIR}/harbor.csr \
    -out ${HARBOR_CERT_DIR}/harbor.crt
    
openssl x509 -inform PEM -in ${HARBOR_CERT_DIR}/harbor.crt -out ${HARBOR_CERT_DIR}/harbor.cert



