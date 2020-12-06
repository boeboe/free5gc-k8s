# Makefile

.PHONY: help

help: ## This help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

CHART_DIR=./charts
ES_OPERATOR_NAMESPACE=es-operator
ES_LOGGING_NAMESPACE=logging

ES_OPERATOR_VALUES=./es-operator-udf-values.yaml
ES_VALUES=./es-udf-values.yaml
FLUENT_BIT_VALUES=./fluent-bit-udf-values.yaml

deploy:  ## Deploy EFK stack
	kubectl apply -f 00_namespace.yaml
	helm install elasticsearch-operator ${CHART_DIR}/elasticsearch-operator --values ${ES_OPERATOR_VALUES} --namespace ${ES_OPERATOR_NAMESPACE} --wait
	helm install elasticsearch ${CHART_DIR}/elasticsearch  --values ${ES_VALUES} --namespace ${ES_LOGGING_NAMESPACE} --wait
	helm install fluent-bit ${CHART_DIR}/fluent-bit --values ${FLUENT_BIT_VALUES}	--namespace=${ES_LOGGING_NAMESPACE} --wait

undeploy:  ## Undeploy EFK stack
	helm uninstall fluent-bit --namespace=${ES_LOGGING_NAMESPACE} || true
	helm uninstall elasticsearch --namespace=${ES_LOGGING_NAMESPACE} || true
	helm uninstall elasticsearch-operator --namespace=${ES_OPERATOR_NAMESPACE} || true
	kubectl delete -f 00_namespace.yaml || true
