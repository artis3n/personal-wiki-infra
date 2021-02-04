#!/usr/bin/env make

.PHONY: install
install:
	pipenv install --dev
	pipenv run ansible-galaxy role install --force-with-deps --role-file packer/ansible/requirements.yml
	pipenv run ansible-galaxy collection install --force-with-deps --requirements-file packer/ansible/requirements.yml

.PHONY: test
test:
	cd packer/ansible && pipenv run molecule test

.PHONY: build
build:
	ANSIBLE_VAULT_PASSWORD_FILE=packer/ansible/.vaultpass pipenv run packer build packer/wiki.pkr.hcl
