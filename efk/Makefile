# Makefile

.PHONY: help

help: ## This help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

CHART_DIR=./charts
LOGGING_NAMESPACE=logging
FLUENT_BIT_VALUES=./fluentbit-udf-values.yaml

install-es-kibana:  ## Install elasticsearch and kibana
	curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
	echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
	sudo apt-get update -y
	sudo apt-get install  -y elasticsearch kibana
	sudo systemctl start elasticsearch
	sudo systemctl enable elasticsearch
	sudo systemctl enable kibana
	sudo systemctl start kibana


deploy-fluentbit:  ## Deploy EFK stack
	kubectl apply -f 00_namespace.yaml
	helm install fluent-bit ${CHART_DIR}/fluent-bit --values ${FLUENT_BIT_VALUES}	--namespace=${LOGGING_NAMESPACE} --wait


undeploy-fluentbit:  ## Undeploy EFK stack
	helm uninstall fluent-bit --namespace=${LOGGING_NAMESPACE} || true
	kubectl delete -f 00_namespace.yaml || true
