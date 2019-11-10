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

FROM python:3.8-alpine

ARG BUILD_DATE
ARG VCS_REF

LABEL \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.docker.dockerfile="/Dockerfile" \
    org.label-schema.license="Apache License 2.0" \
    org.label-schema.name="Prime python-flask container" \
    org.label-schema.url="https://github.com/GoogleCloudPlatform/" \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-type="Git" \
    org.label-schema.vcs-url="https://github.com/GoogleCloudPlatform/gke-migration-to-containers"

COPY prime-flask-server.py requirements.txt /opt/

RUN adduser -D apprunner && \
    apk add --no-cache \
    dumb-init=1.2.2-r1 && \
    pip3 install -r /opt/requirements.txt && \
    chown -R apprunner:apprunner /opt/

WORKDIR /opt
USER apprunner
EXPOSE 8080

ENTRYPOINT ["/usr/bin/dumb-init", "/usr/local/bin/gunicorn", "--bind", "0.0.0.0:8080", "prime-flask-server"]
