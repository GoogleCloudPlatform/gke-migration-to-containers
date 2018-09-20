#!/usr/bin/env bash

# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Stop immediately if something goes wrong
set -euo pipefail

# Provisioning a Kubernetes Engine ingress can take some time as a Layer 7
# http load balancer must be configured.  This script will check and loop-retry
# getting the external ip address associated with the load balancer then check
# and loop-retry waiting for the endpoint to become healthy.

echo "===================================================="
echo "Initializing the test application. Please be patient, it takes a few \
minutes to complete."
echo "===================================================="

# The outer loop checks for the external IP address associated with the
# HTTP load balancer created by the Kubernetes Engine prime-server ingress.  It
# should be created relatively quickly so the loop sleeps for 10 seconds and
# error times out after 100 seconds.
ELAPSED=0
SLEEP=10
MAX_TIME=100
while true; do

  IP_ADDRESS=$(kubectl get ingress prime-server --namespace \
    default -o jsonpath='{.status.loadBalancer.ingress..ip}')
  if [[ -n "$IP_ADDRESS" ]]; then
    SERVER_ADDRESS="http://${IP_ADDRESS}"
    echo "$SERVER_ADDRESS provisioned!"

    # This inner loop is to wait for the server to respond to a health check.
    # This can take much longer so we animate the cursor to ensure that the
    # user can see that the script has not timed out.  We do not have an error
    # timeout for acquiring a health check because sometimes this step takes
    # unusually long.
    while true; do
      echo -ne 'waiting for endpoint to become healthy: |\r'
      sleep 1
      echo -ne 'waiting for endpoint to become healthy: /\r'
      sleep 1
      echo -ne 'waiting for endpoint to become healthy: -\r'
      sleep 1
      echo -ne 'waiting for endpoint to become healthy: \\\r'
      sleep 1
      if [[ "$(curl -s -o /dev/null -w "%{http_code}" "$SERVER_ADDRESS"/)" == \
       "200" ]]; then
        break
      fi
    done
    echo ""
    echo "SUCCESS! $SERVER_ADDRESS is now healthy"
    exit 0
  fi
  if [[ "${ELAPSED}" -gt "${MAX_TIME}" ]]; then
    echo "ERROR: ${MAX_TIME} seconds exceeded, no response from kubernetes api."
    exit 1
  fi
  echo "After ${ELAPSED} seconds, endpoint not yet provisioned, waiting..."
  sleep "$SLEEP"
  ELAPSED=$(( ELAPSED + SLEEP ))
done
