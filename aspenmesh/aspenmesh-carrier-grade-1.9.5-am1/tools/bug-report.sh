#!/usr/bin/env bash

set -euEo pipefail

TOOLS_DIR=$(dirname "$0")
BIN_DIR=$(realpath "$TOOLS_DIR/../bin")
ISTIOCTL="$BIN_DIR/istioctl"

if [ ! -x "$ISTIOCTL" ]; then
  ISTIOCTL+=".exe"
  if [ ! -x "$ISTIOCTL" ]; then
    echo "Could not find istioctl (or istioctl.exe) executable in $BIN_DIR"
    exit 1
  fi
fi

"$ISTIOCTL" bug-report "$@"
