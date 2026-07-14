variable "project_name" {
  type    = string
  default = "hub-cloud"
}

variable "environments" {
  type    = list(string)
  default = ["dev", "staging", "prod"]
}

variable "vpc_cidr_blocks" {
  type = map(string)
  default = {
    dev     = "10.10.0.0/16"
    staging = "10.20.0.0/16"
    prod    = "10.30.0.0/16"
  }
}