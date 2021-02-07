#!/usr/bin/env make

.PHONY: install
install:
	pipenv install --dev
	pipenv run ansible-galaxy role install --force-with-deps --role-file packer/ansible/requirements.yml
	pipenv run ansible-galaxy collection install --force-with-deps --requirements-file packer/ansible/requirements.yml

.PHONY: lint
lint:
	cd packer/ansible && pipenv run ansible-lint

.PHONY: validate
validate:
	pipenv run packer validate packer/wiki.pkr.hcl

.PHONY: format
format:
	cd terraform && terraform fmt
	pipenv run packer fmt packer/wiki.pkr.hcl

.PHONY: test
test:
	cd packer/ansible && pipenv run molecule test

.PHONY: build
build:
	ANSIBLE_VAULT_PASSWORD_FILE=packer/ansible/.vaultpass pipenv run packer build packer/wiki.pkr.hcl

.PHONY: init
init:
	cd terraform && terraform init

.PHONY: plan
plan: init
	cd terraform && terraform plan

.PHONY: apply
apply: init
	cd terraform && terraform apply

.PHONY: destroy
destroy: init
	cd terraform && terraform destroy

.PHONY: check-env
check-env:
ifndef INSTANCE_ID
	$(error "INSTANCE_ID is undefined. Set this environment variable from the output of 'make apply'.")
endif

.PHONY: ip
ip: check-env
	aws --region "$${AWS_REGION:-us-east-2}" ssm send-command --instance-ids "$${INSTANCE_ID}" --document-name "AWS-RunShellScript" --parameters commands="tailscale netcheck | grep IPv4 | awk '{ print $4 }' | cut -d ':' -f1" --output text
