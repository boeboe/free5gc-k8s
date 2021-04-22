# Makefile

ASPEN_NAMESPACE=istio-system
ASPEN_VERSION=1.9.1-am1
ASPEN_VALUES=./udf-values-${ASPEN_VERSION}.yaml
CHART_DIR=./aspenmesh-carrier-grade-${ASPEN_VERSION}/manifests/charts
CERT_DIR=../certificates/cluster

ISTIO_VERSION=1.9.1

ANALYSIS_EMULATOR_NAMESPACE=analysis-emulator
ANALYSIS_EMULATOR_CHART_DIR=./aspenmesh-carrier-grade-${ASPEN_VERSION}/samples/aspenmesh/analysis-emulator

HELM_ARGS=
# HELM_ARGS=--debug

.PHONY: help install upgrade uninstall istioctl post-install post-uninstall

help: ## This help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

install:  ## Install aspenmesh
	kubectl create ns ${ASPEN_NAMESPACE} || true
	kubectl create secret generic cacerts -n ${ASPEN_NAMESPACE} \
		--from-file=${CERT_DIR}/ca-cert.pem \
		--from-file=${CERT_DIR}/ca-key.pem \
		--from-file=${CERT_DIR}/root-cert.pem \
		--from-file=${CERT_DIR}/cert-chain.pem 
	helm install istio-base ${CHART_DIR}/base --namespace ${ASPEN_NAMESPACE} ${HELM_ARGS} || true
	sleep 10
	helm install istiod ${CHART_DIR}/istio-control/istio-discovery --namespace ${ASPEN_NAMESPACE} --values ${ASPEN_VALUES} ${HELM_ARGS} || true
	sleep 120
	helm install istio-ingress ${CHART_DIR}/gateways/istio-ingress --namespace ${ASPEN_NAMESPACE} --values ${ASPEN_VALUES} ${HELM_ARGS} || true
	helm install istio-egress ${CHART_DIR}/gateways/istio-egress --namespace ${ASPEN_NAMESPACE} --values ${ASPEN_VALUES} ${HELM_ARGS} || true
	kubectl apply -f ./post-install/

upgrade:  ## Upgrade aspenmesh
	helm upgrade istio-base ${CHART_DIR}/base --namespace ${ASPEN_NAMESPACE} ${HELM_ARGS} || true
	sleep 10
	helm upgrade istiod ${CHART_DIR}/istio-control/istio-discovery --namespace ${ASPEN_NAMESPACE} --values ${ASPEN_VALUES} ${HELM_ARGS} || true
	sleep 20
	helm upgrade istio-ingress ${CHART_DIR}/gateways/istio-ingress --namespace ${ASPEN_NAMESPACE} --values ${ASPEN_VALUES} ${HELM_ARGS} || true
	helm upgrade istio-egress ${CHART_DIR}/gateways/istio-egress --namespace ${ASPEN_NAMESPACE} --values ${ASPEN_VALUES} ${HELM_ARGS} || true
	kubectl apply -f ./post-install/

uninstall:  ## Uninstall aspenmesh
	kubectl delete -f ./post-install || true
	helm uninstall istio-egress --namespace ${ASPEN_NAMESPACE} || true
	helm uninstall istio-ingress --namespace ${ASPEN_NAMESPACE} || true
	helm uninstall istiod --namespace ${ASPEN_NAMESPACE} || true
	helm uninstall istio-base --namespace ${ASPEN_NAMESPACE} || true
	kubectl delete ns ${ASPEN_NAMESPACE} || true

reinstall:  post-uninstall uninstall install post-install ## Reinstall aspenmesh

istioctl:  ## Install istioctl
	curl -sL https://istio.io/downloadIstioctl | ISTIO_VERSION=${ISTIO_VERSION} sh - && \
	sudo cp ~/.istioctl/bin/istioctl /usr/local/bin

post-install:  ## Post installation steps
	helm install --namespace istio-system --set auth.strategy="anonymous" --repo https://kiali.org/helm-charts kiali-server kiali-server
	kubectl apply -f ./post-install/

post-upgrade:  ## Post upgrade steps
	helm upgrade --namespace istio-system --set auth.strategy="anonymous" --repo https://kiali.org/helm-charts kiali-server kiali-server
	kubectl apply -f ./post-install/

post-uninstall:  ## Post uninstallation steps
	helm uninstall --namespace istio-system kiali-server
	kubectl delete crd monitoringdashboards.monitoring.kiali.io
	kubectl delete -f ./post-install/

analysis-emulator-install:  ## Install aspen mesh packet capture analysis emulator
	kubectl create ns ${ANALYSIS_EMULATOR_NAMESPACE}
	kubectl label --overwrite ns ${ANALYSIS_EMULATOR_NAMESPACE} ca.istio.io/override=true
	helm install analysis-emulator --namespace ${ANALYSIS_EMULATOR_NAMESPACE} ${ANALYSIS_EMULATOR_CHART_DIR}
	kubectl label --overwrite ns ${ASPEN_NAMESPACE} ca.istio.io/override=true

analysis-emulator-upgrade:  ## Upgrade aspen mesh packet capture analysis emulator
	helm upgrade analysis-emulator --namespace ${ANALYSIS_EMULATOR_NAMESPACE} ${ANALYSIS_EMULATOR_CHART_DIR}
	kubectl label --overwrite ns ${ASPEN_NAMESPACE} ca.istio.io/override=true

analysis-emulator-patch:  ## Patch aspen mesh packet capture analysis emulator
	kubectl patch -n ${ANALYSIS_EMULATOR_NAMESPACE} deployment analysis-emulator --patch "$(cat ./post-install/analysis-emulator/patch-extra-sidecars.yaml)" 

analysis-emulator-uninstall:  ## Uninstall aspen mesh packet capture analysis emulator
	helm uninstall analysis-emulator --namespace ${ANALYSIS_EMULATOR_NAMESPACE} || true
	kubectl delete ns analysis-emulator
	kubectl label --overwrite ns ${ASPEN_NAMESPACE} ca.istio.io/override=false
