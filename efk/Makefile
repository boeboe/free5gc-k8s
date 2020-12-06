# Makefile

.PHONY: help

help: ## This help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

CHART_DIR=./charts
LOGGING_NAMESPACE=logging
FLUENT_BIT_VALUES=./fluentbit-udf-values.yaml

deploy:  ## Deploy EFK stack
	kubectl apply -f 00_namespace.yaml
	helm install fluent-bit ${CHART_DIR}/fluent-bit --values ${FLUENT_BIT_VALUES}	--namespace=${LOGGING_NAMESPACE} --wait

undeploy:  ## Undeploy EFK stack
	helm uninstall fluent-bit --namespace=${LOGGING_NAMESPACE} || true
	kubectl delete -f 00_namespace.yaml || true
