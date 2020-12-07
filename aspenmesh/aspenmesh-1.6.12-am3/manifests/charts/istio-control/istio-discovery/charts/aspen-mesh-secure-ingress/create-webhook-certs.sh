#!/bin/bash

set -xEeuo pipefail

rm -f /usr/bin/kubectl
curl -L -o /usr/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v1.18.10/bin/linux/amd64/kubectl
chmod +x /usr/bin/kubectl

# Based on https://github.com/morvencao/kube-mutating-webhook-tutorial/blob/master/deployment/webhook-patch-ca-bundle.sh

while [[ $# -gt 0 ]]; do
    case ${1} in
        --service)
            service="$2"
            shift
            ;;
        --secret)
            secret="$2"
            shift
            ;;
        --namespace)
            namespace="$2"
            shift
            ;;
        --expirationDays)
            expirationDays="$2"
            shift
            ;;
    esac
    shift
done

service=${service:-aspen-mesh-secure-ingress}
secret=${secret:-secure-ingress-webhook-certs}
namespace=${namespace:-istio-system}
csrName=${service}.${namespace}.svc
tmpdir=$(mktemp -d)

(( expirationThresholdDays=365 ))
# Expiration threshold days in seconds
(( expirationThresholdSeconds=expirationThresholdDays*60*60*24 ))
# Default expiration is 10 years
expirationDays=${expirationDays:-3650}

# Check if the webhook already exists and has a valid server certificate
currentCert=$(kubectl get validatingwebhookconfiguration "${service}" -o jsonpath='{.webhooks[0].clientConfig.caBundle}' --ignore-not-found)
if [[ ${currentCert} != '' ]]
then
  echo "Found an existing webhook certificate. Checking the certificate expiration to see if rotation is required."
  # Check if certificate is close to expiring
  echo "${currentCert}" | openssl base64 -d -A -out "${tmpdir}/current-cert.pem"
  if openssl x509 -checkend "${expirationThresholdSeconds}" -noout -in "${tmpdir}/current-cert.pem" > /dev/null
  then
    echo "Current webhook certificate is valid for at least ${expirationThresholdDays} days skipping the rotation and exiting"
    exit 0
  fi
fi

echo "Creating root cert for webhook ${service} in tmpdir ${tmpdir} with an expiration of ${expirationDays} days"

openssl genrsa -out "${tmpdir}/ca.key" 2048
openssl req -x509 -new -nodes -key "${tmpdir}/ca.key" -subj "/CN=${csrName}" -days "${expirationDays}" -out "${tmpdir}/ca.crt"

# create the secret with CA cert and server cert/key
kubectl -v5 create secret generic "${secret}" \
        --from-file=key.pem="${tmpdir}/ca.key" \
        --from-file='cert-chain.pem'="${tmpdir}/ca.crt" \
        -n "${namespace}" \
        --dry-run -o yaml |
        kubectl apply -f -

CA_MARKER="__CABUNDLE__"
UID_MARKER="__UID__"
MOUNTED_WEBHOOK_CONFIG_PATH="/tmp/cert/webhook.yaml"
NEW_WEBHOOK_CONFIG_PATH="${tmpdir}/webhook.yaml"

echo "Setting CA and service UID for webhook ${service}"
set +x
CA_CERT=$(cat "${tmpdir}/ca.crt" | base64 | tr -d '\n')
SERVICE_UID=$(kubectl get service "${service}" -n "${namespace}" \
  -o jsonpath='{.metadata.uid}')

# Replace the caBundle and uid placeholders in the webhook config
cp "${MOUNTED_WEBHOOK_CONFIG_PATH}" "${NEW_WEBHOOK_CONFIG_PATH}"
sed -i "s/${CA_MARKER}/${CA_CERT}/g" "${NEW_WEBHOOK_CONFIG_PATH}"
sed -i "s/${UID_MARKER}/${SERVICE_UID}/g" "${NEW_WEBHOOK_CONFIG_PATH}"

set -x
# Apply the webhook configuration
kubectl apply -f "${NEW_WEBHOOK_CONFIG_PATH}"

# Restart the deployment to pick up the new certificates
echo "Rolling out the pods associated with service ${service} in namespace ${namespace} to ensure new webhook credentials take effect"
kubectl rollout restart deployment/"${service}" --namespace "${namespace}"
