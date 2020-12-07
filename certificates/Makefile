# Makefile

.PHONY: help

help: ## This help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

.PHONY: all ca f5gc-webui harbor mongo-express wildcard


all: ca f5gc-webui harbor mongo-express wildcard ## Generate root CA cert and leaf certs

ca: ## Generate root CA cert
	./ca.sh

f5gc-webui: ## Generate f5gc webui cert
	./f5gc-webui.sh

harbor: ## Generate harbor cert
	./harbor.sh

mongo-express: ## Generate mongo express cert
	./mongo-express.sh

wildcard: ## Generate wildcard cert
	./wildcard.sh

view: ## View certificate information
	echo "Execute the following command to view certificate information: "
	echo "openssl x509 -text -noout -in certificate.crt"

install-ca: ## Install CA on your host system
	sudo cp ./ca/ca.crt /usr/local/share/ca-certificates/udf-demo.org.crt
	sudo update-ca-certificates
