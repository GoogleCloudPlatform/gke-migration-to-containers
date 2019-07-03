/*
Copyright 2018 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

// Provides access to available Google Container Engine versions in a zone for a given project.
// https://www.terraform.io/docs/providers/google/d/google_container_engine_versions.html
data "google_container_engine_versions" "on-prem" {
  zone    = "${var.zone}"
  project = "${var.project}"
}

// https://www.terraform.io/docs/providers/template/index.html
// This block defines the startup script used to pull a container
// image from a private repo and install it as a systemd service.
data "template_file" "startup_script" {
  template = <<EOF
  #cloud-config

  users:
  - name: appuser
    uid: 2000

  write_files:
  - path: /etc/systemd/system/flaskservice.service
    permissions: 0644
    owner: root
    content: |
      [Unit]
      Description=Start the flaskservice
      Wants=gcr-online.target
      After=gcr-online.target

      [Service]
      Environment="HOME=/home/appuser"
      ExecStartPre=/usr/bin/docker-credential-gcr configure-docker
      ExecStart=/usr/bin/docker run --rm --name=flaskservice -p 8080:8080 gcr.io/$${project}/prime-flask:$${version}
      ExecStop=/usr/bin/docker stop flaskservice
      ExecStopPost=/usr/bin/docker rm flaskservice

  - path: /home/appuser/.docker/config.json
    permissions: 0644
    owner: appuser
    content: |
      {
        "auths": {},
        "credHelpers": {
                "asia.gcr.io": "gcr",
                "eu.gcr.io": "gcr",
                "gcr.io": "gcr",
                "staging-k8s.gcr.io": "gcr",
                "us.gcr.io": "gcr"
        }
      }

  - path: /home/appuser/start.sh
    permissions: 0755
    owner: appuser
    content: |
      #!/bin/env bash
      docker run --rm -d --name=appuser -p 8080:8080 gcr.io/$${project}/prime-flask:$${version}

  runcmd:
  - usermod -aG docker appuser
  - systemctl daemon-reload
  - systemctl start flaskservice.service
EOF

  vars {
    project      = "${var.project}"
    version      = "${var.ver}"
  }
}

// https://www.terraform.io/docs/providers/google/r/compute_instance.html
// The ContainerOS deployment instance definition which will
// run the container instead of as the interpreted python code.
resource "google_compute_instance" "container_server" {
  name         = "cos-vm"
  machine_type = "${var.machine_type}"
  zone         = "${var.zone}"
  project      = "${var.project}"

  tags          = ["flask-web"]

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"
    }
  }

  metadata {
    user-data = "${data.template_file.startup_script.rendered}"
  }
  //metadata_startup_script = "${data.template_file.startup_script.rendered}"
  network_interface {
    network = "default"
    access_config {
      // leave this block empty to get an automatically generated ephemeral
      // external IP
    }
  }

  service_account {
    scopes = ["storage-ro"]
  }

}

// The Kubernetes Engine cluster used to deploy the application
// https://www.terraform.io/docs/providers/google/r/container_cluster.html
resource "google_container_cluster" "prime_cluster" {
  name                = "${var.cluster_name}"
  zone                = "${var.zone}"
  project             = "${var.project}"
  min_master_version  = "${data.google_container_engine_versions.on-prem.latest_master_version}"
  initial_node_count  = 2
}

// Create a deployment manifest with the appropriate values
// https://www.terraform.io/docs/providers/template/d/file.html
data "template_file" "deployment_manifest" {
  template = <<EOF
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: prime-server
    labels:
      app: prime-server
  spec:
    replicas: $${replicas}
    selector:
      matchLabels:
        app: prime-server
    template:
      metadata:
        labels:
          app: prime-server
      spec:
        containers:
        - name: prime-server
          image: gcr.io/$${project}/prime-flask:$${version}
          env:
          ports:
          - containerPort: 8080
            name: http
          livenessProbe:
            httpGet:
              path: /
              port: http
            initialDelaySeconds: 10
          readinessProbe:
            httpGet:
              path: /
              port: http
            initialDelaySeconds: 10
EOF

  vars {
    project   = "${var.project}"
    version   = "${var.ver}"
    replicas  = "${var.replicas}"
  }
}

// Render the deployment manifest on the local filesystem using a null resource
// https://www.terraform.io/docs/provisioners/null_resource.html
resource "null_resource" "deployment_manifest" {
  triggers {
    template = "${data.template_file.deployment_manifest.rendered}"
  }

  provisioner "local-exec" {
    command = "echo \"${data.template_file.deployment_manifest.rendered}\" > ${path.module}/manifests/prime-server-deployment.yaml"
  }

}

resource "null_resource" "local_config" {

  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials prime-server-cluster --project ${var.project}"
  }
  depends_on = [
    "google_container_cluster.prime_cluster"
  ]
}

// This bucket will hold the deployment artifact, the tar file containing the
// prime-server
//
resource "google_storage_bucket" "artifact_store" {
  name          = "${var.project}-vm-artifacts"
  project       = "${var.project}"
  # force_destroy = true
}

// https://www.terraform.io/docs/providers/google/r/storage_bucket_object.html
resource "google_storage_bucket_object" "artifact" {
  name          = "${var.ver}/flask-prime.tgz"
  source        = "../build/flask-prime.tgz"
  bucket        = "${google_storage_bucket.artifact_store.name}"
  // TODO: ignore lifecycle something so old versions don't get deleted
}

data "template_file" "web_init" {
  template = "${file("${path.module}/web-init.sh.tmpl")}"
  vars {
    bucket  = "${var.project}-vm-artifacts"
    version = "${var.ver}"
  }
}

// https://www.terraform.io/docs/providers/google/r/compute_instance.html
resource "google_compute_instance" "web_server" {
  project       = "${var.project}"
  name          = "vm-webserver"
  machine_type  = "${var.machine_type}"
  zone          = "${var.zone}"

  tags          = ["flask-web"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = "default"
    access_config {
      // leave this block empty to get an automatically generated ephemeral
      // external IP
    }
  }

  // install pip and flask
  metadata_startup_script = "${data.template_file.web_init.rendered}"

  service_account {
    scopes = ["storage-ro"]
  }

  depends_on = [
    "google_storage_bucket.artifact_store",
    "google_storage_bucket_object.artifact"
  ]
}

// https://www.terraform.io/docs/providers/google/r/compute_firewall.html
resource "google_compute_firewall" "flask_web" {
  name    = "flask-web"
  network = "default"
  project = "${var.project}"
  allow {
    protocol  = "tcp"
    ports     = ["8080"]
  }

  source_ranges = ["0.0.0.0/0"]
  source_tags   = ["flask-web"]
}
