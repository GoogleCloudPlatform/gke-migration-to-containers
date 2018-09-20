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

# git is required for this tutorial
command -v terraform >/dev/null 2>&1 || { \
 echo >&2 "I require terraform but it's not installed.  Aborting."; exit 1; }

 # Use git to find the top-level directory and confirm
 # by looking for the 'terraform' directory
 PROJECT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

 cd "${PROJECT_DIR}/terraform" || exit 1
 rm -f manifests/prime-server-deployment.yaml
 ./tear-down.sh
