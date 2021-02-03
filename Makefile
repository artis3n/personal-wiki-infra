#!/usr/bin/env make

.PHONY: test
test:
	cd packer/ansible && pipenv run molecule test
