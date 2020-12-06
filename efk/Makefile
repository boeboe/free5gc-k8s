# Makefile

.PHONY: help

help: ## This help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

CHART_DIR=./charts
ES_OPERATOR_NAMESPACE=es-operator
ES_LOGGING_NAMESPACE=logging

deploy:  ## Deploy EFK stack
	kubectl apply -f 00_namespace.yaml
	helm install elasticsearch-operator ${CHART_DIR}/elasticsearch-operator --wait \
		--set rbac.enabled=True \
		--namespace ${ES_OPERATOR_NAMESPACE}
	helm install elasticsearch ${CHART_DIR}/elasticsearch --wait \
		--set kibana.enabled=true \
		--set cerebro.enabled=true \
		--set clientReplicas=1,masterReplicas=1,dataReplicas=1 \
		--namespace ${ES_LOGGING_NAMESPACE}
	helm install fluent-bit ${CHART_DIR}/fluent-bit --wait \
		--set metrics.enabled=true \
		--set backend.type=es \
		--set backend.es.time_key='@ts' \
		--set backend.es.host=elasticsearch-elasticsearch-cluster \
		--set backend.es.tls=off \
		--set backend.es.tls_verify=off \
		--namespace=${ES_LOGGING_NAMESPACE}
		 
undeploy:  ## Undeploy EFK stack
	helm uninstall fluent-bit --namespace=${ES_LOGGING_NAMESPACE} || true
	helm uninstall elasticsearch --namespace=${ES_LOGGING_NAMESPACE} || true
	helm uninstall elasticsearch-operator --namespace=${ES_OPERATOR_NAMESPACE} || true
	kubectl delete -f 00_namespace.yaml || true
