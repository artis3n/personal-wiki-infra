#!/bin/bash
set -euo pipefail

tailscale up -hostname "personal-wiki" -authkey "$(aws --region us-east-2 ssm get-parameters --names tailscale --with-decryption --query 'Parameters[].Value' | grep ts | xargs)"
