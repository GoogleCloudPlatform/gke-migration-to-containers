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

// variables.tf - this is where all variables are defined.  The user must
// provide these for any invocation of `terraform plan`, `apply`, or `destroy`.


variable "cluster_name" {
  description = "The Kubernetes Engine cluster name"
  default = "prime-server-cluster"
}
variable "machine_type" {
  default = "f1-micro"
}

variable "project" {
  type = "string"
}

variable "replicas" {
  description = "Number of prime server replicas to create"
  default = "1"
}

variable "ver" {
  type = "string"
}

variable "zone" {
  type = "string"
}
