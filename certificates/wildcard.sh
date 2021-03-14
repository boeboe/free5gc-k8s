#!/usr/bin/env bash

ROOT_CA_CERT=./root-cert.pem
ROOT_CA_KEY=./root-key.pem
WILDCARD_CERT_DIR=./wildcard
CERT_DOMAIN_NAME=*.aspen-demo.org

echo "Generate a Server Certificate for wildcard"
openssl genrsa -out ${WILDCARD_CERT_DIR}/wildcard.key 4096
openssl req -sha512 -new \
    -subj "/C=BE/ST=Mechelen/L=Hever/O=F5/OU=Presales/CN=${CERT_DOMAIN_NAME}" \
    -key ${WILDCARD_CERT_DIR}/wildcard.key \
    -out ${WILDCARD_CERT_DIR}/wildcard.csr
cat > ${WILDCARD_CERT_DIR}/wildcard-v3.ext <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1=*.aspen-demo.org
DNS.2=aspen-demo.org
DNS.3=localhost
IP.1=10.1.1.4
IP.2=10.1.1.5
IP.3=10.1.1.6
IP.4=10.1.1.7
IP.5=10.1.1.8
IP.6=10.1.1.9
IP.7=10.1.10.4
IP.8=10.1.10.5
IP.9=10.1.10.6
IP.10=10.1.10.7
IP.11=10.1.10.8
IP.12=10.1.10.9
IP.13=127.0.0.1
EOF
openssl x509 -req -sha512 -days 3650 \
    -extfile ${WILDCARD_CERT_DIR}/wildcard-v3.ext \
    -CA ${ROOT_CA_CERT} -CAkey ${ROOT_CA_KEY} \
    -CAcreateserial \
    -in ${WILDCARD_CERT_DIR}/wildcard.csr \
    -out ${WILDCARD_CERT_DIR}/wildcard.crt
    
openssl x509 -inform PEM -in ${WILDCARD_CERT_DIR}/wildcard.crt -out ${WILDCARD_CERT_DIR}/wildcard.cert
openssl pkcs12 -export -out ${WILDCARD_CERT_DIR}/wildcard.pfx -inkey ${WILDCARD_CERT_DIR}/wildcard.key -in ${WILDCARD_CERT_DIR}/wildcard.crt
