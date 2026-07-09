#  Copyright (c) 2026 Contributors to the Eclipse Foundation
#
#  See the NOTICE file(s) distributed with this work for additional
#  information regarding copyright ownership.
#
#  This program and the accompanying materials are made available under the
#  terms of the Apache License, Version 2.0 which is available at
#  https://www.apache.org/licenses/LICENSE-2.0.
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#  License for the specific language governing permissions and limitations
#  under the License.
#
#  SPDX-License-Identifier: Apache-2.0

locals {
  project     = "tx-umbrella"
  environment = "test"
  region      = "germanywestcentral"

  resource_group_name   = "tx-umbrella"
  create_resource_group = false

  dns_zone_name       = "test.tx-umbrella.com"
  kubernetes_version  = "1.36"
  address_space       = ["10.11.0.0/16"]
  aks_subnet_prefixes = ["10.11.1.0/24"]

  # Node pools
  system_vm_size       = "Standard_D2s_v3"
  node_count_system    = 1
  workloads_vm_size    = "Standard_D4s_v3"
  node_count_workloads = 1

  # AKS control plane
  sku_tier = "Free" # Free = no SLA, Standard = SLA-backed control plane
}
