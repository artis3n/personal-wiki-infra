#!/usr/bin/env bash

eval $(ssh-agent -s)
ssh-add /home/wiki/.ssh/wiki_deploy_key
cd /opt/wiki || exit 1
export GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
git pull origin main
git push origin main
unset GIT_SSH_COMMAND

trap 'kill $SSH_AGENT_PID' EXIT
