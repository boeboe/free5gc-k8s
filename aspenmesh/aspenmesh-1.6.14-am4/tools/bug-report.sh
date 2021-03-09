#!/usr/bin/env bash

set -euEo pipefail

BR_TGZ=$(mktemp -t "aspen-mesh-bug-report")

if command -v curl &> /dev/null; then
  DL_CMD="curl --silent --output $BR_TGZ"
elif command -v wget &> /dev/null; then
  DL_CMD="wget --quiet --output-document=$BR_TGZ"
else
  echo "Either curl or wget must be installed"
  exit 1
fi

PF_PID=""
PF_OUT=""
cleanup() {
  if [ -n "$PF_PID" ]; then
    kill "$PF_PID"
  fi
  if [ -n "$PF_OUT" ]; then
    rm "$PF_OUT"
  fi
}

trap cleanup SIGINT SIGTERM EXIT

CP_POD=$(kubectl get pod -n istio-system \
  -l app=aspen-mesh-controlplane \
  -o jsonpath='{.items[0].metadata.name}')

PF_OUT=$(mktemp -t "aspen-mesh-bug-report-port-forward")

kubectl port-forward -n istio-system "$CP_POD" :21001 > "$PF_OUT" 2>&1 &
PF_PID=$!

PF_PORT=""
for (( n=0; n<=10; n++ )); do
  if [[ $(grep "Forwarding from" "$PF_OUT" | head -1) =~ 127\.0\.0\.1:([0-9]+)\ \-\> ]]; then
    PF_PORT="${BASH_REMATCH[1]}"
    break
  fi
  sleep 1
done

if [ -z "$PF_PORT" ]; then
  echo "Timeout waiting for port forward"
  exit 1
fi

echo "Generating bug report..."
$DL_CMD "http://localhost:$PF_PORT"

if [ ! -s "$BR_TGZ" ]; then
  echo "Error generating bug report"
  exit 1
fi

TGZ="./bug-report.tgz"
REV=0
while true; do
  if [ ! -f "$TGZ" ]; then
    mv "$BR_TGZ" $TGZ
    echo "Bug report complete"
    echo "Location: $TGZ"
    break
  fi
  (( REV++ ))
  TGZ="./bug-report-$REV.tgz"
done
