variable "server_name" {
  type    = string
  default = "terraform-gollum-wiki"
}

variable "aws-region" {
  type    = string
  default = "us-east-2"
}

variable "default-vpc-id" {
  type    = string
  default = "vpc-f653a79f"
}

variable "iam-policy-version" {
  type    = string
  default = "2012-10-17"
}

variable "instance_type" {
  type    = string
  default = "t4g.micro"
}

variable "tailscale_parameter_name" {
  type    = string
  default = "tailscale"
}

variable "disk_size" {
  type    = number
  default = 8
}

variable "disk_iops" {
  type    = number
  default = 3000
}

variable "disk_throughput" {
  type    = number
  default = 125
}
