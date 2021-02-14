resource "aws_spot_instance_request" "wiki" {
  ami                  = data.aws_ami.wiki.id
  instance_type        = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.wiki.id
  user_data            = file("${path.module}/userdata/userdata.sh")
  vpc_security_group_ids = [
    aws_security_group.wiki.id
  ]

  root_block_device {
    encrypted   = true
    volume_size = var.disk_size
    volume_type = "gp3"
    iops        = var.disk_iops
    throughput  = var.disk_throughput
    kms_key_id  = data.aws_kms_key.aws-ebs.arn
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "required"
  }

  wait_for_fulfillment = true
  spot_type            = "persistent"

  tags = {
    Name = var.server_name
  }

  provisioner "local-exec" {
    command = "aws --region ${var.aws-region} ec2 create-tags --resources ${self.spot_instance_id} --tags Key=Name,Value=${self.tags.Name}"
  }

  provisioner "local-exec" {
    command = "aws --region ${var.aws-region} ec2 wait instance-running --instance-ids ${self.spot_instance_id}"
  }
}

resource "aws_security_group" "wiki" {
  name        = "terraform-wiki"
  description = "Security group rules for the Gollum wiki."
  vpc_id      = data.aws_vpc.default-public.id

  // Intentionally no ingress
  // Use Session Manager to establish a connection

  egress {
    description = "Enable all outbound traffic"
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_instance_profile" "wiki" {
  name = "gollum-wiki-instance-profile"
  role = aws_iam_role.wiki.name
}

resource "aws_iam_role" "wiki" {
  name               = "gollum-wiki-server-role"
  assume_role_policy = data.aws_iam_policy_document.wiki-assume.json
}

resource "aws_iam_policy_attachment" "wiki" {
  policy_arn = data.aws_iam_policy.ssm.arn
  roles      = [aws_iam_role.wiki.id]
  name       = "gollum-wiki-ssm"
}

resource "aws_iam_role_policy" "wiki-secrets" {
  policy = data.aws_iam_policy_document.wiki-secrets.json
  role   = aws_iam_role.wiki.id
}

data "aws_iam_policy" "ssm" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "wiki-assume" {
  version = var.iam-policy-version
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "wiki-secrets" {
  version = var.iam-policy-version
  statement {
    effect = "Allow"
    actions = [
      "ssm:DescribeParameters",
    ]

    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameters"
    ]
    resources = [
      data.aws_ssm_parameter.tailscale-key.arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
    ]

    resources = [
      data.aws_kms_key.ssm.arn,
      data.aws_kms_key.aws-ebs.arn,
    ]
  }
}

data "aws_ami" "wiki" {
  owners      = ["self"]
  most_recent = true

  filter {
    name   = "name"
    values = ["packer-gollum-wiki*"]
  }
}

data "aws_kms_key" "aws-ebs" {
  key_id = "alias/aws/ebs"
}

data "aws_kms_key" "ssm" {
  key_id = "alias/aws/ssm"
}

data "aws_ssm_parameter" "tailscale-key" {
  name            = "tailscale"
  with_decryption = false
}

data "aws_vpc" "default-public" {
  id = var.default-vpc-id
}

data "aws_caller_identity" "current" {}
