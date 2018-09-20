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
# command -v gcloud >/dev/null || { echo "ERROR: gcloud not installed" && exit 1 }

REPO_HOME="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
VERSION=$(cat "${REPO_HOME}/VERSION")
BUILD_DATE=$(date)
if command -v git >/dev/null; then
  VCS_REF=$(git rev-parse HEAD)
else
  VCS_REF="NO-VCS"
fi

cd "${REPO_HOME}/container" || exit 1
echo "Building container for prime-server version $VERSION"
gcloud builds submit . \
  --config=cloudbuild.yaml \
  --substitutions _VERSION="${VERSION}",_BUILD_DATE="${BUILD_DATE}",_VCS_REF="${VCS_REF}"
