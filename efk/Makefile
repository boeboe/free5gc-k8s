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
	sudo systemctl start kibana
	sudo systemctl enable kibana

config-es-kibana:  ## Install elasticsearch and kibana
	sudo cp ./elasticsearch.yml /etc/elasticsearch/elasticsearch.yml
	sudo chown root:elasticsearch /etc/elasticsearch/elasticsearch.yml
	sudo chmod 660 /etc/elasticsearch/elasticsearch.yml
	sudo cp ./kibana.yml /etc/kibana/kibana.yml
	sudo chown root:kibana /etc/kibana/kibana.yml
	sudo chmod 660 /etc/kibana/kibana.yml
	sudo systemctl restart elasticsearch
	sudo systemctl restart kibana

install-cerebro:  ## Install elasticsearch web admin tool cerebro
	sudo docker run -d \
		-p 9000:9000 \
		--restart=always \
		--name cerebro \
		--privileged \
		lmenezes/cerebro:latest

uninstall-cerebro:  ## Unistall elasticsearch web admin tool cerebro
	sudo docker kill cerebro
	sudo docker rm cerebro
	sudo docker rmi lmenezes/cerebro:latest

deploy-fluentbit:  ## Deploy EFK stack
	kubectl apply -f 00_namespace.yaml
	helm install fluent-bit ${CHART_DIR}/fluent-bit --values ${FLUENT_BIT_VALUES}	--namespace=${LOGGING_NAMESPACE} --wait


undeploy-fluentbit:  ## Undeploy EFK stack
	helm uninstall fluent-bit --namespace=${LOGGING_NAMESPACE} || true
	kubectl delete -f 00_namespace.yaml || true
