#!/usr/bin/env bash

CA_CERT_DIR=./ca
CA_DOMAIN_NAME=udf-demo.org

echo "Generate a Certificate Authority Certificate"
openssl genrsa -out ${CA_CERT_DIR}/ca.key 4096
openssl req -x509 -new -nodes -sha512 -days 3650 \
 -subj "/C=BE/ST=Mechelen/L=Hever/O=F5/OU=Presales/CN=${CA_DOMAIN_NAME}" \
 -key ${CA_CERT_DIR}/ca.key \
 -out ${CA_CERT_DIR}/ca.crt

