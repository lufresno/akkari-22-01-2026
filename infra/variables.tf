variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type    = string
  default = "svflix"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "key_name" {
  description = "Nombre del KeyPair existente en AWS"
  type        = string
}

