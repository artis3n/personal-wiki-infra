source "amazon-ebs" "wiki" {
  access_key              = var.aws_access_key
  secret_key = var.aws_secret_key
  ami_description         = "Gollum wiki hosted on AWS"
  ami_name                = var.ami_name
  ami_virtualization_type = "hvm"
  iam_instance_profile    = var.iam_instance_profile
  instance_type           = var.instance_type[var.architecture]
  region     = var.aws_region
  ssh_interface = "session_manager"

  launch_block_device_mappings {
    delete_on_termination = true
    device_name           = "/dev/xvda"
    encrypted             = true
    kms_key_id            = var.kms_key_id_or_alias
    volume_size           = var.disk_size
    volume_type = var.disk_type
  }

  source_ami_filter {
    filters = {
      architecture        = var.architecture
      name                = "amzn2-ami-hvm*"
      root-device-type    = "ebs"
      virtualization_type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }

  tags = {
    Base_AMI      = "{{ .SourceAMI }}"
    Base_AMI_Name = "{{ .SourceAMIName }}"
  }
}
