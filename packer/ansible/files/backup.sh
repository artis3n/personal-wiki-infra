#!/usr/bin/env bash

set -eo pipefail
eval '$(ssh-agent -s)'
trap 'kill $SSH_AGENT_PID' EXIT
ssh-add /home/wiki/.ssh/wiki_deploy_key
cd /opt/wiki
git pull origin main
git push origin main
