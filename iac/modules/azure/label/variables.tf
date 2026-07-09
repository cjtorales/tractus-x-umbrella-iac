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

variable "resource_type" {
  type        = string
  description = "The type of the resource for which the name is being generated (e.g. azurerm_resource_group)."
}

variable "app_name" {
  type        = string
  description = "The name of the application / project."
}

variable "stage" {
  type        = string
  description = "The deployment stage (e.g. dev, staging, prod)."
}

variable "location" {
  type        = string
  description = "The Azure region; appended as a short geo code."
  default     = ""
}

variable "spec_chars_allowed" {
  type        = bool
  description = "Whether special characters (-, _) are allowed in the name."
  default     = true
}

variable "naming_convention" {
  type        = string
  description = "Case/separator convention for the name."
  default     = "kebab"
  validation {
    condition = contains([
      "pascal", "camel", "snake", "kebab", "flat", "upper_flat",
      "pascal_snake", "camel_snake", "screaming_snake", "train", "cobol"
    ], var.naming_convention)
    error_message = "naming_convention must be one of: pascal, camel, snake, kebab, flat, upper_flat, pascal_snake, camel_snake, screaming_snake, train, cobol."
  }
}
