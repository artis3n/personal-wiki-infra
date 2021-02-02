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
