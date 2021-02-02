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
