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
output "prime_web_server" {
  value = "http://${google_compute_instance.web_server.network_interface.0.access_config.0.assigned_nat_ip}:8080/prime"
}

output "factorial_web_server" {
  value = "http://${google_compute_instance.web_server.network_interface.0.access_config.0.assigned_nat_ip}:8080/factorial"
}

output "web_server_address" {
  value = "http://${google_compute_instance.web_server.network_interface.0.access_config.0.assigned_nat_ip}:8080"
}
output "prime_cos_server" {
  value = "http://${google_compute_instance.container_server.network_interface.0.access_config.0.assigned_nat_ip}:8080/prime"
}

output "factorial_cos_server" {
  value = "http://${google_compute_instance.container_server.network_interface.0.access_config.0.assigned_nat_ip}:8080/factorial"
}

output "cos_server_address" {
  value = "http://${google_compute_instance.container_server.network_interface.0.access_config.0.assigned_nat_ip}:8080"
}
