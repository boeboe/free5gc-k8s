#!/bin/bash -e

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "No namespace argument was passed"
  exit 1
fi

SECRET_NAME="istio.aspen-mesh-secure-ingress"
SERVICE_NAME="aspen-mesh-secure-ingress"
SECRET_NS="$1"
CA_MARKER="__CABUNDLE__"
UID_MARKER="__UID__"
MOUNTED_WEBHOOK_CONFIG_PATH="/tmp/cert/webhook.yaml"
NEW_WEBHOOK_CONFIG_PATH="$HOME/webhook.yaml"

# Get the CA from the service account secret
_count=0
while ! kubectl get secret $SECRET_NAME -n "$SECRET_NS" \
  -o jsonpath='{.data.root-cert\.pem}' > /dev/null
do
[[ $_count -eq 6 ]] && echo "Secret CA could not be retrieved in 60 seconds" && exit 1
sleep 10
((_count++))
done

# Get the UID from the secure ingress service
_count=0
while ! kubectl get service $SERVICE_NAME -n "$SECRET_NS" \
  -o jsonpath='{.metadata.uid}' > /dev/null
do
[[ $_count -eq 6 ]] && echo "Service UID could not be retrieved in 60 seconds" && exit 1
sleep 10
((_count++))
done

SECRET_CA=$(kubectl get secret $SECRET_NAME -n "$SECRET_NS" \
  -o jsonpath='{.data.root-cert\.pem}' || true)
SERVICE_UID=$(kubectl get service $SERVICE_NAME -n "$SECRET_NS" \
  -o jsonpath='{.metadata.uid}')

# Replace the caBundle and uid placeholders in the webhook config
cp $MOUNTED_WEBHOOK_CONFIG_PATH "$NEW_WEBHOOK_CONFIG_PATH"
sed -i "s/$CA_MARKER/$SECRET_CA/g" "$NEW_WEBHOOK_CONFIG_PATH"
sed -i "s/$UID_MARKER/$SERVICE_UID/g" "$NEW_WEBHOOK_CONFIG_PATH"

# Apply the webhook configuration
kubectl apply -f "$NEW_WEBHOOK_CONFIG_PATH"
