# "timestamp" template function replacement
locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

variable "ami_name" {
  type    = string
  description = "The name of the AMI that gets generated."
  default = "packer-gollum-wiki-${local.timestamp}"
}

variable "architecture" {
  type    = string
  description = "The type of source AMI architecture: either x86_64 or arm64."
  default = "arm64"
}

variable "aws_access_key" {
  type    = string
  description = "AWS_ACCESS_KEY_ID env var."
  default = env("AWS_ACCESS_KEY_ID")
}

variable "aws_region" {
  type    = string
  description = "The AWS region to create the image in. Defaults to us-east-2."
  default = "us-east-2"
}

variable "aws_secret_key" {
  type      = string
  description = "AWS_SECRET_ACCESS_KEY env var."
  default   = env("AWS_SECRET_ACCESS_KEY")
  sensitive = true
}

variable "disk_size" {
  type    = number
  description = "The size of the EBS volume to create."
  default = 15
}

variable "disk_type" {
  type = string
  description = "The type of EBS volume to create. Defaults to gp3."
  default = "gp3"
}

variable "iam_instance_profile" {
  type    = string
  default = "AmazonSSMRoleForInstancesQuickSetup"
  description = "IAM instance profile configured for AWS Session Manager. Defaults to the default AWS role for Session Manager."
}

variable "instance_type" {
  type    = map(string)
  description = "The type of EC2 instance to create. Defaults are set for x86_64 and arm64 architectures. Overwrite the one that you want by architecture."
  default = {
    "x86_64": "t3.micro",
    "arm64": "t4g.micro"
  }
}

variable "kms_key_id_or_alias" {
  type    = string
  description = "The KMS key ID or alias to encrypt the AMI with. Defaults to the default EBS key alias."
  default = "alias/aws/ebs"
}
