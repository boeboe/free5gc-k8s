# Makefile
.PHONY: help

help: ## This help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

hostname:
	./hostname.sh

init:
	./password.sh
	./ssh.sh
	./update.sh
	./packages.sh
	./network-2nic.sh
	./hosts.sh
	./calicoctl.sh
