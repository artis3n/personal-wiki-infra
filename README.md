# Personal Wiki Infrastructure

![CI](https://github.com/artis3n/personal-wiki-infra/workflows/CI/badge.svg)
![Deployment](https://github.com/artis3n/personal-wiki-infra/workflows/Apply/badge.svg)
![GitHub last commit](https://img.shields.io/github/last-commit/artis3n/personal-wiki-infra)
![GitHub](https://img.shields.io/github/license/artis3n/personal-wiki-infra)
[![GitHub followers](https://img.shields.io/github/followers/artis3n?style=social)](https://github.com/artis3n/)
[![Twitter Follow](https://img.shields.io/twitter/follow/artis3n?style=social)](https://twitter.com/Artis3n)

This repository contains all the necessary infrastructure automation to run a private [Gollum][] server in your AWS account.
Once running, the server automatically backs up and restores all wiki data to a private GitHub repository every minute.

Key Benefits:
- Git-based Markdown wiki with all the [benefits][gollum benefits] that Gollum brings
- Secure, private access via a [Tailscale][] network
- No open ingress ports on the server with terminal access via AWS Session Manager
- Easy to deploy! Fork, tweak a few variables, then run two commands to build your own AMI and deploy a private server
- Pay ~$2-3/month if running 24/7 (or less!) depending on spot instance prices

# Setup

Make sure you have Python 3.9 installed on your host system as well as [awscli v2][] and the [awscli Session Manager plugin][]. You will also need [pipenv][].

Fork this repo in order to configure it for your needs and follow the [Usage](#usage) and [Run](#run) instructions below.

# Usage

Install dependencies with `make install`.

## Initial Configuration

1. [Create a new private repo][new repo] to store your wiki content. You do not need to create any files in this repository at this time.

2. Follow [GitHub's instructions][deploy key instructions] for creating a deploy key and attaching it to your new repo.

Suggested:

```bash
ssh-keygen -t ed25519 -C wiki -f wiki_deploy_key
```

3. Change the following variables in `packer/ansible/vars.yml`:

- `wiki_repo`: The git URL to the repository to back up and restore your wiki. It is recommended that this be a private repo.
- `wiki_domain`: The intended hostname for your server. While not exposed beyond your Tailscale network, it is recommended that you use DNS validation to serve the wiki with a Let's Encrypt certificate.

4. Encrypt the private key generated from `ssh-keygen` and store in the Ansible portion of the repo.

```bash
cp wiki_deploy_key packer/ansible/files/wiki_deploy_key
pipenv run ansible-vault encrypt packer/ansible/files/wiki_deploy_key
# Optionally, store the password used to encrypt the file in packer/ansible/.vaultpass
# This file is git ignored by default
echo "PASSWORD" > packer/ansible/.vaultpass
```

5. Create the following [Actions secrets][github secrets] in your new repo:

- `AWS_ACCESS_KEY_ID`: The AWS access key ID used for Packer and Terraform to create resources in your AWS account.
- `AWS_SECRET_ACCESS_KEY`: The AWS secret access key used for Packer and Terraform to create resources in your AWS account.
- `TF_API_TOKEN`: The API token for your account in [Terraform Cloud][].
- `VAULT_PASS`: The password used to encrypt your private key file in the previous step.

6. **Optionally**, tweak the variables defined in `packer/wiki.pkr.hcl`. They are set to reasonable defaults, and you shouldn't need to change them. However, some of the more likely ones you may want to change are:

- `ami_name`: The name of the generated AMI, appended with `-<timestamp>`. Defaults to `packer-gollum-wiki`.
- `architecture`: The type of source AMI architecture. Either `x86_64` or `arm64`. This is `arm64` by default.
- `instance_type`: The type of EC2 instance to create. By default, this will be `t4g.micro` for `arm64` architecture and `t3.micro` for `x86_64` architecture.
- `aws_region`: The AWS region to deploy to. Defaults to `us-east-2`.
- `disk_size`: The size of the root volume for the wiki server. Defaults to `15` GB, which should be plenty. I would caution setting it to `10` GB or less if you are going to include images or files like audio/video. The OS will take up most of that.

There are other variables liked in `packer/wiki.pkr.hcl` which you can peruse as well.

7. You are now ready to run this project.

## Run

1. Create the AMI with `make build`.
    1. The AMI will take ~30-35 minutes to build.
2. Once the AMI is complete, deploy your server with `make apply`.
    1. This will take 1-2 minutes.
    
The output of `make apply` will give you the instance ID of your provisioned AWS spot instance. Use it to SSH via AWS Session Manager:

```bash
aws ssm start-session --target INSTANCE_ID
```

Once SSH'd in, you can run the Certbot installation of a Let's Encrypt certificate with:

```bash
> sudo -u ec2-user /bin/bash
> /home/ec2-user/cert.sh
# Follow Certbot's prompts for manual DNS validation on a domain you control.
```

You can retrieve the private IP address of this server from your Tailscale network by running `INSTANCE_ID=<INSTANCE_ID> make ip`.
You can also retrieve this from your Tailscale admin panel.

With that private IP address, follow [Tailscale's instructions][tailscale dns] to set up private or public DNS records pointing to your instance.
I use the public DNS server for my domain and set redirections to the private 10.x Tailscale address.

Navigate to `http://instance-ip:4567/` to access your Gollum server.
If you have configured your DNS records, you may also use `http://hostname/`.
If uou configured Let's encrypt, make sure you use `https://`. :smiley:

[awscli session manager plugin]: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html
[awscli v2]: https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html
[deploy key instructions]: https://docs.github.com/en/developers/overview/managing-deploy-keys#deploy-keys
[github secrets]: https://docs.github.com/en/actions/reference/encrypted-secrets
[gollum]: https://github.com/gollum/gollum
[gollum benefits]: https://github.com/gollum/gollum/wiki
[new repo]: https://github.com/new/
[pipenv]: https://pypi.org/project/pipenv/
[tailscale]: https://tailscale.com/
[tailscale dns]: https://tailscale.com/kb/1054/dns
[terraform cloud]: https://app.terraform.io/
