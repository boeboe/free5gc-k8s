# Makefile

.PHONY: help

help: ## This help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

HELM_REPO=https://raw.githubusercontent.com/upmc-enterprises/elasticsearch-operator/master/charts/
ES_OPERATOR_NAMESPACE=es-operator
ES_LOGGING_NAMESPACE=logging

deploy:  ## Deploy EFK stack
	helm repo add es-operator ${HELM_REPO}
	helm install elasticsearch-operator es-operator/elasticsearch-operator --wait \
		--set rbac.enabled=True \
		--namespace ${ES_OPERATOR_NAMESPACE}
	sleep 20
	helm install elasticsearch es-operator/elasticsearch --wait \
		--set kibana.enabled=true \
		--set cerebro.enabled=true \
		--set clientReplicas=1,masterReplicas=1,dataReplicas=1 \
		--namespace ${ES_LOGGING_NAMESPACE}
	sleep 120
	helm install fluent-bit stable/fluent-bit --wait \
		--set metrics.enabled=true \
		--set backend.type=es \
		--set backend.es.time_key='@ts' \
		--set backend.es.host=elasticsearch-elasticsearch-cluster \
		--set backend.es.tls=off \
		--set backend.es.tls_verify=off \
		--namespace=${ES_LOGGING_NAMESPACE}
		 
undeploy:  ## Undeploy EFK stack
	helm uninstall fluent-bit --namespace=${ES_LOGGING_NAMESPACE}
	helm uninstall elasticsearch --namespace=${ES_LOGGING_NAMESPACE}
	helm uninstall elasticsearch-operator --namespace=${ES_OPERATOR_NAMESPACE}
