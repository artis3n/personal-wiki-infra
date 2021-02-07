# "timestamp" template function replacement
locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

variable "ami_name" {
  type        = string
  description = "The name of the AMI that gets generated."
  default     = "packer-gollum-wiki"
}

variable "architecture" {
  type        = string
  description = "The type of source AMI architecture: either x86_64 or arm64."
  default     = "arm64"
}

variable "instance_type" {
  type        = map(string)
  description = "The type of EC2 instance to create. Defaults are set for x86_64 and arm64 architectures. Overwrite the one that you want by architecture."
  default = {
    "x86_64" : "t3.micro",
    "arm64" : "t4g.micro"
  }
}

variable "aws_region" {
  type        = string
  description = "The AWS region to create the image in. Defaults to us-east-2."
  default     = "us-east-2"
}

variable "disk_size" {
  type        = number
  description = "The size of the EBS volume to create."
  default     = 15
}

variable "aws_access_key" {
  type        = string
  description = "AWS_ACCESS_KEY_ID env var."
  default     = env("AWS_ACCESS_KEY_ID")
}

variable "aws_secret_key" {
  type        = string
  description = "AWS_SECRET_ACCESS_KEY env var."
  default     = env("AWS_SECRET_ACCESS_KEY")
  sensitive   = true
}

variable "disk_type" {
  type        = string
  description = "The type of EBS volume to create. Defaults to gp3."
  default     = "gp3"
}

variable "disk_throughput" {
  type        = number
  description = "The MB/s of throughput for the EBS volume. For GP3 volumes, this defaults to 125."
  default     = 125
}

variable "disk_iops" {
  type        = number
  description = "The IOPS for the EBS volume. For GP3 volumes, this defaults to 3000."
  default     = 3000
}

variable "iam_instance_profile" {
  type        = string
  default     = "AmazonSSMRoleForInstancesQuickSetup"
  description = "IAM instance profile configured for AWS Session Manager. Defaults to the default AWS role for Session Manager."
}

variable "kms_key_id_or_alias" {
  type        = string
  description = "The KMS key ID or alias to encrypt the AMI with. Defaults to the default EBS key alias."
  default     = "alias/aws/ebs"
}

variable "ansible_vault_pwd_file" {
  type        = string
  description = "The relative or absolute path to the Ansible Vault password file."
  default     = env("ANSIBLE_VAULT_PASSWORD_FILE")
}

variable "ec2_username" {
  type        = string
  description = "The username of the default user on the EC2 instance."
  default     = "ec2-user"
}

source "amazon-ebs" "wiki" {
  access_key              = var.aws_access_key
  secret_key              = var.aws_secret_key
  ami_description         = "Gollum wiki hosted on AWS"
  ami_name                = "${var.ami_name}-${local.timestamp}"
  ami_virtualization_type = "hvm"
  iam_instance_profile    = var.iam_instance_profile
  instance_type           = var.instance_type[var.architecture]
  region                  = var.aws_region
  // Until https://github.com/hashicorp/packer/issues/10584 is fixed, rely on traditional SSH
  //  ssh_interface           = "session_manager"
  ssh_username = var.ec2_username

  launch_block_device_mappings {
    delete_on_termination = true
    device_name           = "/dev/xvda"
    encrypted             = true
    kms_key_id            = var.kms_key_id_or_alias
    volume_size           = var.disk_size
    volume_type           = var.disk_type
    throughput            = var.disk_throughput
    iops                  = var.disk_iops
  }

  source_ami_filter {
    filters = {
      architecture        = var.architecture
      name                = "amzn2-ami-hvm*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }

  tags = {
    Base_AMI      = "{{ .SourceAMI }}"
    Base_AMI_Name = "{{ .SourceAMIName }}"
  }
}

build {
  sources = ["source.amazon-ebs.wiki"]
  name    = "Personal Wiki"

  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
      "echo Beginning to build ${build.ID}",
      "echo Connected via SSM at '${build.User}@${build.Host}:${build.Port}'",
      "sudo yum update -y",
      "sudo yum install -y python3 python3-pip python3-wheel python3-setuptools coreutils shadow-utils yum-utils"
    ]
  }

  provisioner "ansible" {
    galaxy_file      = "packer/ansible/requirements.yml"
    host_alias       = "wiki"
    playbook_file    = "packer/ansible/main.yml"
    user             = var.ec2_username
    ansible_env_vars = ["ANSIBLE_VAULT_PASSWORD_FILE=${var.ansible_vault_pwd_file}"]
  }

  provisioner "shell" {
    inline            = ["sudo reboot"]
    expect_disconnect = true
  }

  provisioner "shell" {
    inline       = ["echo ${build.ID} rebooted, done provisioning"]
    pause_before = "1m"
  }

}
