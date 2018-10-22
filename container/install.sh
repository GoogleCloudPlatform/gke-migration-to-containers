#! /usr/bin/env bash

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

# Check if required binaries exist
# Globals:
#   None
# Arguments:
#   DEPENDENCY - The command to verify is installed.
# Returns:
#   None
check_dependency_installed () {
  command -v "${1}" >/dev/null 2>&1 || { \
  echo >&2 "${1} is required but is not installed. Aborting."; exit 1; }
}

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

check_dependency_installed "python"
check_dependency_installed "pip"

pip install -r "${ROOT}/requirements.txt"
