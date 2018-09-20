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

# bash "strict-mode", fail immediately if there is a problem
set -euo pipefail

# command -v curl || { "ERROR: curl not installed!" && exit 1 }

SCRIPT_HOME=$(dirname "${BASH_SOURCE[0]}")

# terraform_output() - extracts an output from the terraform state file and
# prints to stdout the value at the given key
# usage:
# terraform_output <key>
# Where:
#   <key> is a valid key in the terraform state file
# Returns:
#     0 - when no errors
terraform_output() {
  STATE_KEY=$1
  cd "${SCRIPT_HOME}/terraform" || true
  SERVER_ADDRESS=$(terraform output "${STATE_KEY}")
  echo "$SERVER_ADDRESS"
  cd - > /dev/null
  return 0
}

# health_check() - Wait for a server to respond with a 200 status code at  a
# given endpoint.  It will periodically retry until the MAX_TIME is exceeded.
# Usage:
# health_check <server-address>
# Where:
#   <server-address> is of the form 'http://<ip-address>:<port>'
# Returns:
#   0 - when the server responds with a 200 status code
#   1 - when the MAX_TIME is exceeded before a 200 status code is returned
health_check() {
  SERVER_ADDRESS=$1
  ELAPSED=0
  SLEEP=10
  MAX_TIME=${MAX_TIME:-100}
  echo "Testing endpoint ${SERVER_ADDRESS}"
  while true; do
    HTTP_CODE=$(curl -s -o /dev/null -I --max-time 1 -w "%{http_code}" \
      "${SERVER_ADDRESS}" || true)
    if [[ "${HTTP_CODE}" == "200" ]]; then
      echo "Endpoint ${SERVER_ADDRESS} is responding."
      return 0
    fi
    if [[ "${ELAPSED}" -gt "${MAX_TIME}" ]]; then
      echo "ERROR: ${MAX_TIME} seconds exceeded, no response from ${SERVER_ADDRESS}"
      exit 1
    fi
    echo "After ${ELAPSED} seconds, endpoint not yet healthy, waiting..."
    sleep "$SLEEP"
    ELAPSED=$(( ELAPSED + SLEEP ))
  done
}

# validate_prime() - validate that the prime server returns the correct result
# Usage:
# validate_prime <server-address>
# Where:
#   <server-address> is of the form 'http://<ip-address>:<port>'
# Returns:
#   0 - when the server responds with the correct answer to sum of primes less
#       than 10
#   1 - when the server responsds with an incorrect answer
validate_prime() {
SERVER_ADDRESS=$1
# Construct the test URL
PRIME_TEST="${SERVER_ADDRESS}/prime/10"

# Test the URL
PRIME_RESPONSE=$(curl "${PRIME_TEST}" 2>/dev/null)

# Extract the answer from the server response
SUM=$(echo "${PRIME_RESPONSE}" | tr " " "\\n" | tail -n1)

# Make sure that 'Sum of primes less than 10' == 17
if [[ "${SUM}" != "17" ]]; then
  echo "ERROR: Sum of Primes less than 10 is 17, got ${SUM}"
  return 1
fi

# If we have made it this far, all is good, output the server responses.
echo "${PRIME_RESPONSE}"
return 0
}

# validate_factorial() - validate that the factorial server returns the correct
# result
# Usage:
# validate_factorial <server-address>
# Where:
#   <server-address> is of the form 'http://<ip-address>:<port>'
# Returns:
#   0 - when the server responds with the correct answer for 10!
#   1 - when the server responsds with an incorrect answer for 10!
validate_factorial() {
SERVER_ADDRESS=$1
# Construct the test URL
FACTORIAL_TEST="${SERVER_ADDRESS}/factorial/10"

# Test the URL
FACTORIAL_RESPONSE=$(curl "${FACTORIAL_TEST}" 2>/dev/null)

# Extract the answer from the server response
FACTORIAL=$(echo "${FACTORIAL_RESPONSE}" | tr " " "\\n" | tail -n1)

# Make sure that 10! == 3628800
if [[ "${FACTORIAL}" != "3628800" ]]; then
  echo "ERROR: Factorial of 10 is 3628800, got ${FACTORIAL}"
  return 1
fi

# If we have made it this far, all is good, output the server responses.
echo "${FACTORIAL_RESPONSE}"
}

# validate_deployment() - given a server address, it runs health_check(),
# validate_prime(), and validate_factorial()
validate_deployment() {
  ADDRESS=$1
  health_check "${ADDRESS}"
  validate_prime "${ADDRESS}"
  validate_factorial "${ADDRESS}"
}

# Each of the three deployments are validated
echo ""
echo "Validating Debian VM Webapp..."
SERVER_ADDRESS=$(terraform_output web_server_address)
validate_deployment "$SERVER_ADDRESS"

echo ""
echo "Validating Container OS Webapp..."
SERVER_ADDRESS=$(terraform_output cos_server_address)
validate_deployment "$SERVER_ADDRESS"

echo ""
echo "Validating Kubernetes Webapp..."
SERVER_IP=$(kubectl get ingress prime-server \
  --namespace default \
  -o jsonpath='{.status.loadBalancer.ingress..ip}')
SERVER_ADDRESS="http://${SERVER_IP}"
validate_deployment "$SERVER_ADDRESS"
