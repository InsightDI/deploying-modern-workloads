variable "hub_resource_group" {
  description = "The name of the resource group where hub resources will live"
  type        = string
}

variable "spoke_resource_group" {
  description = "The name of the resource group where spoke resources will live"
  type        = string
}

variable "prefix" {
  description = "A name prefix used to prefix resource names"
  type        = string

  validation {
    condition = (
      length(var.prefix) < 15 &&
      length(var.prefix) > 0
    )
    error_message = "The length of the prefix must be between 1 and 15 characters."
  }
}

variable "location" {
  description = "The region where all resources will be deployed"
  type        = string
  default     = "eastus2"
}

