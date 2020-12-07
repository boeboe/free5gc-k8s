#!/usr/bin/env bash

CA_CERT_DIR=./ca
MONGO_EXPRESS_CERT_DIR=./mongo-express
CERT_DOMAIN_NAME=mongo-express.udf-demo.org

echo "Generate a Server Certificate for mongo-express"
openssl genrsa -out ${MONGO_EXPRESS_CERT_DIR}/mongo-express.key 4096
openssl req -sha512 -new \
    -subj "/C=BE/ST=Mechelen/L=Hever/O=F5/OU=Presales/CN=${CERT_DOMAIN_NAME}" \
    -key ${MONGO_EXPRESS_CERT_DIR}/mongo-express.key \
    -out ${MONGO_EXPRESS_CERT_DIR}/mongo-express.csr
cat > ${MONGO_EXPRESS_CERT_DIR}/mongo-express-v3.ext <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1=udf-demo.org
DNS.2=mongo-express
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
    -extfile ${MONGO_EXPRESS_CERT_DIR}/mongo-express-v3.ext \
    -CA ${CA_CERT_DIR}/ca.crt \
    -CAkey ${CA_CERT_DIR}/ca.key \
    -CAcreateserial \
    -in ${MONGO_EXPRESS_CERT_DIR}/mongo-express.csr \
    -out ${MONGO_EXPRESS_CERT_DIR}/mongo-express.crt
    
openssl x509 -inform PEM -in ${MONGO_EXPRESS_CERT_DIR}/mongo-express.crt -out ${MONGO_EXPRESS_CERT_DIR}/mongo-express.cert



