#!/bin/bash
exit_code=1
retry_times=0
until [ $exit_code -eq 0 ]; do
    if [ $retry_times -gt 20 ];then
      echo "Timeout waiting for Cassandra"
      exit 1
    fi
    echo "Wait until Cassandra is up"
    nodetool status
    exit_code=$?
    retry_times=$((retry_times+1))
    sleep 15
done

cqlsh localhost -f /aspen-mesh-event-storage/events-ddl.cql

if [ $? -eq 0 ];then
  echo "Successfully set up Cassandra schema"
else
  echo "Failed to set up Cassandra schema. Please check the logs."
  exit 0
fi
