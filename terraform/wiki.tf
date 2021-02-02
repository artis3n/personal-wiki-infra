resource "aws_spot_instance_request" "wiki" {
  ami                  = data.aws_ami.wiki.id
  instance_type        = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.wiki.id
  vpc_security_group_ids = [
    aws_security_group.wiki.id
  ]

  root_block_device {
    encrypted   = true
    volume_size = 15
    kms_key_id  = data.aws_kms_key.aws-ebs.arn
  }

  metadata_options {
    http_endpoint = "disabled"
  }

  wait_for_fulfillment = true
  spot_type            = "persistent"

  tags = {
    Name = "terraform-gollum-wiki"
  }

  provisioner "local-exec" {
    command = "aws ec2 create-tags --resources ${self.spot_instance_id} --tags Key=Name,Value=${self.tags.Name} --region us-east-1"
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
      "secretsmanager:GetSecretValue",
    ]

    resources = [
      data.aws_secretsmanager_secret.wiki-tailscale.arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
    ]

    resources = [
      data.aws_kms_key.secrets-manager.arn,
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

data "aws_kms_key" "secrets-manager" {
  key_id = "alias/secrets_manager_default"
}

data "aws_secretsmanager_secret" "wiki-tailscale" {
  name = "tailscale"
}

data "aws_vpc" "default-public" {
  id = var.default-vpc-id
}
