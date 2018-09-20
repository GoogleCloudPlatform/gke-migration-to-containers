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

# This script should be run from directory that contains the terraform directory.
# The purpose is to populate defaults for subsequent terraform commands.

# Terraform is required for this demo
command -v terraform >/dev/null 2>&1 || { \
echo >&2 "I require terraform but it's not installed.  Aborting."; exit 1; }


# Use git to find the top-level directory and confirm
# by looking for the 'terraform' directory
PROJECT_DIR="$(git rev-parse --show-toplevel)"
if [[ -d "./terraform" ]]; then
PROJECT_DIR="$(pwd)"
fi
if [[ -z "${PROJECT_DIR}" ]]; then
    echo "Could not identify project base directory." 1>&2
    echo "Please re-run from a project directory and ensure" 1>&2
    echo "the .git directory exists." 1>&2
    exit 1;
fi

./enable-apis.sh

./build.sh

# Cloud Build!
cd "${PROJECT_DIR}/container"
./cloudbuild.sh
cd "${PROJECT_DIR}/"
# Terraform steps:
TFVARS_FILE="./terraform/terraform.tfvars"

# Remove a pre-existing tfvars file, if it exists
if [[ -f "${TFVARS_FILE}" ]]
then
  rm ${TFVARS_FILE}
fi

./generate-tfvars.sh

cd "${PROJECT_DIR}/terraform"
./setup.sh

kubectl apply -f ./manifests/ --namespace default
cd "${PROJECT_DIR}"
./wait_for_cluster.sh

