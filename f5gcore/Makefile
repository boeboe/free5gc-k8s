# Makefile
F5GC_BASE_NAME      ?= f5gc-build-base
F5GC_GNBSIM_NAME    ?= f5gc-gnbsim
F5GC_AMF_NAME       ?= f5gc-amf
F5GC_SMF_NAME       ?= f5gc-smf
F5GC_UPF_NAME       ?= f5gc-upf
F5GC_NRF_NAME		 		?= f5gc-nrf
F5GC_AUSF_NAME      ?= f5gc-ausf
F5GC_NSSF_NAME      ?= f5gc-nssf
F5GC_PCF_NAME       ?= f5gc-pcf
F5GC_UDM_NAME       ?= f5gc-udm
F5GC_UDR_NAME       ?= f5gc-udr
F5GC_WEBUI_NAME		 	?= f5gc-webui

FREE5GC_VERSION 		?= v3.0.5

# With or without debug tools
ifeq ($(DEBUG), true)
DOCKER_ENV          ?= DOCKER_BUILDKIT=1
DOCKER_TAG          ?= ${FREE5GC_VERSION}-dbg
DOCKER_USER       	?= boeboe
DEBUG_TOOL_LIST     ?= vim strace net-tools curl netcat-openbsd bash tree tcpdump wget httpie bind-tools iproute2
DOCKER_BUILD_ARGS   ?= --rm --build-arg DEBUG_TOOLS=true --build-arg DEBUG_TOOL_LIST="${DEBUG_TOOL_LIST}"
else
DOCKER_ENV          ?= DOCKER_BUILDKIT=1
DOCKER_TAG          ?= ${FREE5GC_VERSION}
DOCKER_USER       	?= boeboe
DOCKER_BUILD_ARGS   ?= --rm --build-arg DEBUG_TOOLS=false
endif

# Docker build names
BASE_IMAGE_NAME         ?= ${DOCKER_USER}/${F5GC_BASE_NAME}:${DOCKER_TAG}
GNBSIM_IMAGE_NAME       ?= ${DOCKER_USER}/${F5GC_GNBSIM_NAME}:${DOCKER_TAG}
AMF_IMAGE_NAME          ?= ${DOCKER_USER}/${F5GC_AMF_NAME}:${DOCKER_TAG}
SMF_IMAGE_NAME          ?= ${DOCKER_USER}/${F5GC_SMF_NAME}:${DOCKER_TAG}
UPF_IMAGE_NAME          ?= ${DOCKER_USER}/${F5GC_UPF_NAME}:${DOCKER_TAG}
NRF_IMAGE_NAME          ?= ${DOCKER_USER}/${F5GC_NRF_NAME}:${DOCKER_TAG}
AUSF_IMAGE_NAME         ?= ${DOCKER_USER}/${F5GC_AUSF_NAME}:${DOCKER_TAG}
NSSF_IMAGE_NAME         ?= ${DOCKER_USER}/${F5GC_NSSF_NAME}:${DOCKER_TAG}
PCF_IMAGE_NAME          ?= ${DOCKER_USER}/${F5GC_PCF_NAME}:${DOCKER_TAG}
UDM_IMAGE_NAME          ?= ${DOCKER_USER}/${F5GC_UDM_NAME}:${DOCKER_TAG}
UDR_IMAGE_NAME          ?= ${DOCKER_USER}/${F5GC_UDR_NAME}:${DOCKER_TAG}
WEBUI_IMAGE_NAME        ?= ${DOCKER_USER}/${F5GC_WEBUI_NAME}:${DOCKER_TAG}


# Kubernetes deployment folders
K8S_DEPLOY_DIR								?= ./manifests
GNBSIM_K8S_DEPLOY_DIR   			?= ${K8S_DEPLOY_DIR}/f5gc-gnbsim
AMF_K8S_DEPLOY_DIR      			?= ${K8S_DEPLOY_DIR}/f5gc-amf
SMF_K8S_DEPLOY_DIR      			?= ${K8S_DEPLOY_DIR}/f5gc-smf
UPF_K8S_DEPLOY_DIR      			?= ${K8S_DEPLOY_DIR}/f5gc-upf
NRF_K8S_DEPLOY_DIR      			?= ${K8S_DEPLOY_DIR}/f5gc-nrf
AUSF_K8S_DEPLOY_DIR     			?= ${K8S_DEPLOY_DIR}/f5gc-ausf
NSSF_K8S_DEPLOY_DIR     			?= ${K8S_DEPLOY_DIR}/f5gc-nssf
PCF_K8S_DEPLOY_DIR      			?= ${K8S_DEPLOY_DIR}/f5gc-pcf
UDM_K8S_DEPLOY_DIR      			?= ${K8S_DEPLOY_DIR}/f5gc-udm
UDR_K8S_DEPLOY_DIR      			?= ${K8S_DEPLOY_DIR}/f5gc-udr
WEBUI_K8S_DEPLOY_DIR    			?= ${K8S_DEPLOY_DIR}/f5gc-webui
MONGODB_K8S_DEPLOY_DIR  			?= ${K8S_DEPLOY_DIR}/f5gc-mongodb
MONGO_EXPRESS_K8S_DEPLOY_DIR	?= ${K8S_DEPLOY_DIR}/dbg-mongo-express
N6DUMMY_K8S_DEPLOY_DIR  			?= ${K8S_DEPLOY_DIR}/f5gc-n6dummy

MONGO_EXPRESS_CERT_DIR=../certificates/mongo-express
F5GC_WEBUI_CERT_DIR=../certificates/f5gc-webui
MONGO_EXPRESS_KEY=${MONGO_EXPRESS_CERT_DIR}/mongo-express.key
MONGO_EXPRESS_CERT=${MONGO_EXPRESS_CERT_DIR}/mongo-express.cert
F5GC_WEBUI_KEY=${F5GC_WEBUI_CERT_DIR}/f5gc-webui.key
F5GC_WEBUI_CERT=${F5GC_WEBUI_CERT_DIR}/f5gc-webui.cert

.PHONY: help

help: ## This help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help


build: build-base build-gnbsim build-amf build-smf build-upf build-nrf build-ausf build-nssf build-pcf build-udm build-udr build-webui ## Build all images locally
push: push-base push-gnbsim push-amf push-smf push-upf push-nrf push-ausf push-nssf push-pcf push-udm push-udr push-webui ## Push all images to dockerhub


### Base Image ###
build-base:
	${DOCKER_ENV} docker build ${DOCKER_BUILD_ARGS} \
		--tag ${BASE_IMAGE_NAME} \
		--file ./images/${F5GC_BASE_NAME}/Dockerfile.alpine \
		--build-arg FREE5GC_VERSION=${FREE5GC_VERSION} \
		./images/${F5GC_BASE_NAME}
push-base:
	${DOCKER_ENV} docker push ${BASE_IMAGE_NAME}


### GNBSIM - a 5G SA gNB/UE simulator for testing 5GC system ###
build-gnbsim:
	${DOCKER_ENV} docker build ${DOCKER_BUILD_ARGS} \
		--tag ${GNBSIM_IMAGE_NAME} \
		--file ./images/${F5GC_GNBSIM_NAME}/Dockerfile.ubuntu18 \
		--build-arg FREE5GC_VERSION=${FREE5GC_VERSION} \
		--no-cache \
		./images/${F5GC_GNBSIM_NAME}
push-gnbsim:
	${DOCKER_ENV} docker push ${GNBSIM_IMAGE_NAME}


### AMF - Access and Mobility Management Function ###
build-amf: build-base
	${DOCKER_ENV} docker build ${DOCKER_BUILD_ARGS} \
		--tag ${AMF_IMAGE_NAME} \
		--file ./images/${F5GC_AMF_NAME}/Dockerfile.alpine \
		--build-arg FREE5GC_VERSION=${FREE5GC_VERSION} \
		./images/${F5GC_AMF_NAME}
push-amf:
	${DOCKER_ENV} docker push ${AMF_IMAGE_NAME}


### SMF - Session Management Function ###
build-smf: build-base
	${DOCKER_ENV} docker build ${DOCKER_BUILD_ARGS} \
		--tag ${SMF_IMAGE_NAME} \
		--file ./images/${F5GC_SMF_NAME}/Dockerfile.alpine \
		--build-arg FREE5GC_VERSION=${FREE5GC_VERSION} \
		./images/${F5GC_SMF_NAME}
push-smf:
	${DOCKER_ENV} docker push ${SMF_IMAGE_NAME}


### UPF - User Plane Function ###
build-upf: build-base
	${DOCKER_ENV} docker build ${DOCKER_BUILD_ARGS} \
		--tag ${UPF_IMAGE_NAME} \
		--file ./images/${F5GC_UPF_NAME}/Dockerfile.ubuntu18 \
		--build-arg FREE5GC_VERSION=${FREE5GC_VERSION} \
		./images/${F5GC_UPF_NAME}
push-upf:
	${DOCKER_ENV} docker push ${UPF_IMAGE_NAME}


### NRF - Network Repository Function ###
build-nrf: build-base
	${DOCKER_ENV} docker build ${DOCKER_BUILD_ARGS} \
		--tag ${NRF_IMAGE_NAME} \
		--file ./images/${F5GC_NRF_NAME}/Dockerfile.alpine \
		--build-arg FREE5GC_VERSION=${FREE5GC_VERSION} \
		./images/${F5GC_NRF_NAME}
push-nrf:
	${DOCKER_ENV} docker push ${NRF_IMAGE_NAME}


### AUSF - Authentication Server Function ###
build-ausf: build-base
	${DOCKER_ENV} docker build ${DOCKER_BUILD_ARGS} \
		--tag ${AUSF_IMAGE_NAME} \
		--file ./images/${F5GC_AUSF_NAME}/Dockerfile.alpine \
		--build-arg FREE5GC_VERSION=${FREE5GC_VERSION} \
		./images/${F5GC_AUSF_NAME}
push-ausf:
	${DOCKER_ENV} docker push ${AUSF_IMAGE_NAME}


### NSSF - Network slice selection function ###
build-nssf: build-base
	${DOCKER_ENV} docker build ${DOCKER_BUILD_ARGS} \
		--tag ${NSSF_IMAGE_NAME} \
		--file ./images/${F5GC_NSSF_NAME}/Dockerfile.alpine \
		--build-arg FREE5GC_VERSION=${FREE5GC_VERSION} \
		./images/${F5GC_NSSF_NAME}
push-nssf:
	${DOCKER_ENV} docker push ${NSSF_IMAGE_NAME}


## PCF - Policy Control Function ###
build-pcf: build-base
	${DOCKER_ENV} docker build ${DOCKER_BUILD_ARGS} \
		--tag ${PCF_IMAGE_NAME} \
		--file ./images/${F5GC_PCF_NAME}/Dockerfile.alpine \
		--build-arg FREE5GC_VERSION=${FREE5GC_VERSION} \
		./images/${F5GC_PCF_NAME}
push-pcf:
	${DOCKER_ENV} docker push ${PCF_IMAGE_NAME}


### UDM - Unified Data Manager Function ###
build-udm: build-base
	${DOCKER_ENV} docker build ${DOCKER_BUILD_ARGS} \
		--tag ${UDM_IMAGE_NAME} \
		--file ./images/${F5GC_UDM_NAME}/Dockerfile.alpine \
		--build-arg FREE5GC_VERSION=${FREE5GC_VERSION} \
		./images/${F5GC_UDM_NAME}
push-udm:
	${DOCKER_ENV} docker push ${UDM_IMAGE_NAME}


### UDR - Unified Data Repository ###
build-udr: build-base
	${DOCKER_ENV} docker build ${DOCKER_BUILD_ARGS} \
		--tag ${UDR_IMAGE_NAME} \
		--file ./images/${F5GC_UDR_NAME}/Dockerfile.alpine \
		--build-arg FREE5GC_VERSION=${FREE5GC_VERSION} \
		./images/${F5GC_UDR_NAME}
push-udr:
	${DOCKER_ENV} docker push ${UDR_IMAGE_NAME}


### WebUI ###
build-webui: build-base
	${DOCKER_ENV} docker build ${DOCKER_BUILD_ARGS} \
		--tag ${WEBUI_IMAGE_NAME} \
		--file ./images/${F5GC_WEBUI_NAME}/Dockerfile.alpine \
		--build-arg FREE5GC_VERSION=${FREE5GC_VERSION} \
		./images/${F5GC_WEBUI_NAME}
push-webui:
	${DOCKER_ENV} docker push ${WEBUI_IMAGE_NAME}


clean:
	docker rmi ${DOCKER_USER}/${F5GC_BASE_NAME}:${DOCKER_TAG} || true
	docker rmi ${DOCKER_USER}/${F5GC_GNBSIM_NAME}:${DOCKER_TAG} || true
	docker rmi ${DOCKER_USER}/${F5GC_AMF_NAME}:${DOCKER_TAG} || true
	docker rmi ${DOCKER_USER}/${F5GC_SMF_NAME}:${DOCKER_TAG} || true
	docker rmi ${DOCKER_USER}/${F5GC_UPF_NAME}:${DOCKER_TAG} || true
	docker rmi ${DOCKER_USER}/${F5GC_NRF_NAME}:${DOCKER_TAG} || true
	docker rmi ${DOCKER_USER}/${F5GC_AUSF_NAME}:${DOCKER_TAG} || true
	docker rmi ${DOCKER_USER}/${F5GC_NSSF_NAME}:${DOCKER_TAG} || true
	docker rmi ${DOCKER_USER}/${F5GC_PCF_NAME}:${DOCKER_TAG} || true
	docker rmi ${DOCKER_USER}/${F5GC_UDM_NAME}:${DOCKER_TAG} || true
	docker rmi ${DOCKER_USER}/${F5GC_UDR_NAME}:${DOCKER_TAG} || true
	docker rmi ${DOCKER_USER}/${F5GC_WEBUI_NAME}:${DOCKER_TAG} || true


deploy:  ## Deploy F5GCore Components
	kubectl apply -f ${K8S_DEPLOY_DIR}/00_namespace.yaml || true
	kubectl create secret tls mongoexpress-f5gc --key ${MONGO_EXPRESS_KEY} --cert ${MONGO_EXPRESS_CERT} --namespace istio-system || true
	kubectl create secret tls webui-f5gc --key ${F5GC_WEBUI_KEY} --cert ${F5GC_WEBUI_CERT} --namespace istio-system || true
	kubectl apply -k ${MONGODB_K8S_DEPLOY_DIR} || true
	kubectl apply -k ${MONGO_EXPRESS_K8S_DEPLOY_DIR} || true
	kubectl apply -k ${N6DUMMY_K8S_DEPLOY_DIR} || true
	kubectl apply -k ${GNBSIM_K8S_DEPLOY_DIR} || true
	kubectl apply -k ${AMF_K8S_DEPLOY_DIR} || true
	kubectl apply -k ${SMF_K8S_DEPLOY_DIR} || true
	kubectl apply -k ${UPF_K8S_DEPLOY_DIR} || true
	kubectl apply -k ${NRF_K8S_DEPLOY_DIR} || true
	kubectl apply -k ${AUSF_K8S_DEPLOY_DIR} || true
	kubectl apply -k ${NSSF_K8S_DEPLOY_DIR} || true
	kubectl apply -k ${PCF_K8S_DEPLOY_DIR} || true
	kubectl apply -k ${UDM_K8S_DEPLOY_DIR} || true
	kubectl apply -k ${UDR_K8S_DEPLOY_DIR} || true
	kubectl apply -k ${WEBUI_K8S_DEPLOY_DIR} || true


undeploy: ## Undeploy F5GCore Components
	kubectl delete -k ${WEBUI_K8S_DEPLOY_DIR} || true
	kubectl delete -k ${UDR_K8S_DEPLOY_DIR} || true
	kubectl delete -k ${UDM_K8S_DEPLOY_DIR} || true
	kubectl delete -k ${PCF_K8S_DEPLOY_DIR} || true
	kubectl delete -k ${NSSF_K8S_DEPLOY_DIR} || true
	kubectl delete -k ${AUSF_K8S_DEPLOY_DIR} || true
	kubectl delete -k ${NRF_K8S_DEPLOY_DIR} || true
	kubectl delete -k ${UPF_K8S_DEPLOY_DIR} || true
	kubectl delete -k ${SMF_K8S_DEPLOY_DIR} || true
	kubectl delete -k ${AMF_K8S_DEPLOY_DIR} || true
	kubectl delete -k ${GNBSIM_K8S_DEPLOY_DIR} || true
	kubectl delete -k ${N6DUMMY_K8S_DEPLOY_DIR} || true
	kubectl delete -k ${MONGO_EXPRESS_K8S_DEPLOY_DIR} || true
	kubectl delete -k ${MONGODB_K8S_DEPLOY_DIR} || true
	kubectl delete secret f5gc-mongoexpress --namespace istio-system || true
	kubectl delete secret f5gc-f5gcwebui --namespace istio-system || true
	kubectl delete -f ${K8S_DEPLOY_DIR}/00_namespace.yaml || true

redeploy: undeploy deploy ## Redeploy F5GCore Components

view-all:  ## View all free5gc pods, services and serviceaccounts
	kubectl get serviceaccounts -n f5gc -o wide 
	kubectl get services -n f5gc -o wide 
	kubectl get pods -n f5gc -o wide 
	kubectl get applications -n f5gc -o wide
	kubectl get secureingress -n f5gc -o wide

exec-gnbsim-00:  ## Kubectl exec in gnbsim container for bash console
	kubectl -n f5gc exec -it `kubectl get pods -n f5gc -l app=f5gc-gnbsim-00 --output=jsonpath={.items..metadata.name}` -c f5gc-gnbsim -- /bin/bash
exec-gnbsim-01:  ## Kubectl exec in gnbsim container for bash console
	kubectl -n f5gc exec -it `kubectl get pods -n f5gc -l app=f5gc-gnbsim-01 --output=jsonpath={.items..metadata.name}` -c f5gc-gnbsim -- /bin/bash
exec-gnbsim-02:  ## Kubectl exec in gnbsim container for bash console
	kubectl -n f5gc exec -it `kubectl get pods -n f5gc -l app=f5gc-gnbsim-02 --output=jsonpath={.items..metadata.name}` -c f5gc-gnbsim -- /bin/bash
exec-gnbsim-03:  ## Kubectl exec in gnbsim container for bash console
	kubectl -n f5gc exec -it `kubectl get pods -n f5gc -l app=f5gc-gnbsim-03 --output=jsonpath={.items..metadata.name}` -c f5gc-gnbsim -- /bin/bash
exec-gnbsim-04:  ## Kubectl exec in gnbsim container for bash console
	kubectl -n f5gc exec -it `kubectl get pods -n f5gc -l app=f5gc-gnbsim-04 --output=jsonpath={.items..metadata.name}` -c f5gc-gnbsim -- /bin/bash

test-gnbsim-00:  ## Kubectl exec in gnbsim container for load test
	kubectl -n f5gc exec -it `kubectl get pods -n f5gc -l app=f5gc-gnbsim-00 --output=jsonpath={.items..metadata.name}` -c f5gc-gnbsim -- ./run.sh
test-gnbsim-01:  ## Kubectl exec in gnbsim container for load test
	kubectl -n f5gc exec -it `kubectl get pods -n f5gc -l app=f5gc-gnbsim-01 --output=jsonpath={.items..metadata.name}` -c f5gc-gnbsim -- ./run.sh
test-gnbsim-02:  ## Kubectl exec in gnbsim container for load test
	kubectl -n f5gc exec -it `kubectl get pods -n f5gc -l app=f5gc-gnbsim-02 --output=jsonpath={.items..metadata.name}` -c f5gc-gnbsim -- ./run.sh
test-gnbsim-03:  ## Kubectl exec in gnbsim container for load test
	kubectl -n f5gc exec -it `kubectl get pods -n f5gc -l app=f5gc-gnbsim-03 --output=jsonpath={.items..metadata.name}` -c f5gc-gnbsim -- ./run.sh
test-gnbsim-04:  ## Kubectl exec in gnbsim container for load test
	kubectl -n f5gc exec -it `kubectl get pods -n f5gc -l app=f5gc-gnbsim-04 --output=jsonpath={.items..metadata.name}` -c f5gc-gnbsim -- ./run.sh

test-ingress:  ## Test ingress exposed service
	curl -v -HHost:f5gc-webui.udf-demo.org --resolve f5gc-webui.udf-demo.org:31002:10.1.1.6 https://f5gc-webui.udf-demo.org:31002/
	curl -v -HHost:mongo-express.udf-demo.org --resolve mongo-express.udf-demo.org:31002:10.1.1.6 https://mongo-express.udf-demo.org:31002/
	echo | openssl s_client -showcerts -servername f5gc-webui.udf-demo.org -connect f5gc-webui.udf-demo.org:31002 2>/dev/null | openssl x509 -inform pem -noout -text
	echo | openssl s_client -showcerts -servername f5gc-webui -connect f5gc-webui:31002 2>/dev/null | openssl x509 -inform pem -noout -text
	echo | openssl s_client -showcerts -servername 10.1.1.6 -connect 10.1.1.6:31002 2>/dev/null | openssl x509 -inform pem -noout -text
