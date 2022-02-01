variable "project" {
  description = "Google Cloud Platform project name, eg. todolist-staging"
}
variable "environment" {
  description = "Unique environment name, lowercase, hyphenated and short"
}

variable "region" {
  description = "Default project region"
  default     = "europe-west2"
}
