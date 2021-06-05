#!/bin/bash
set -xuo pipefail

if [[ $# -lt 1 ]]; then
  echo "No namespace argument was passed"
  exit 1
fi

NS="$1"

MOUNTED_ENVOYFILTER_PATH="/tmp/configmap/envoyhttp.yaml"

# Get the CA from the service account secret
_count=0
while [[ $_count -lt 24 ]]
do
   ret_code=0
   result=$(kubectl apply -n $NS -f $MOUNTED_ENVOYFILTER_PATH 2>&1) || ret_code=$?
   if [[ $ret_code == 0 ]]; then
     exit 0
   fi
   if [[ $result == "The EnvoyFilter \"http-capture-filter\" is invalid" ]]; then
     webhook_result=$(kubectl apply -n $NS -f $MOUNTED_ENVOYFILTER_PATH -v 9 2>&1 | grep "admission webhook" | sed 's/.*]//g')
     echo $webhook_result
     echo "Refer to Aspen Mesh documentation at my.aspenmesh.io for valid ranges for these configuration parameters."
     exit 1
   fi
   echo $result
   sleep 5
   ((_count++))
done
echo "failed to apply envoyfilter"
exit 1

