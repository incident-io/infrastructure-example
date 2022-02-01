variable "billing_account" {
  description = "Google billing account to configure Stack project against"
}

variable "org_id" {
  description = "Google project organisation ID"
}

variable "application" {
  description = "Application name that is managed by the Stack (ie. incident-io)"
}

variable "stack_name" {
  description = "Spacelift Stack name, immutable. Defaults to <application>-<instance>"
  default     = ""
}

variable "autodeploy" {
  description = "Whether the stack should be automatically deployed on merge"
  default     = false
}

locals {
  stack_name_computed = var.stack_name == "" ? "${var.application}-${var.instance}" : var.stack_name
}

variable "instance" {
  description = "Instance name, such as an environment (ie. staging)"
}

variable "google_project_id" {
  description = "GCP project name for Stack, max 30 characters (ie. incident-io-staging)"
}

variable "organisation_iam_roles" {
  description = "Grant these roles at an organisation level to the Stack manager- only for administrative stacks!"
  default     = []
}
