# Makefile
F5GC_BASE_NAME          ?= f5gc-build-base
F5GC_GNBSIM_NAME        ?= f5gc-gnbsim
F5GC_AMF_NAME           ?= f5gc-amf
F5GC_SMF_NAME           ?= f5gc-smf
F5GC_UPF_NAME           ?= f5gc-upf
F5GC_NRF_NAME		 	?= f5gc-nrf
F5GC_AUSF_NAME          ?= f5gc-ausf
F5GC_NSSF_NAME          ?= f5gc-nssf
F5GC_PCF_NAME           ?= f5gc-pcf
F5GC_UDM_NAME           ?= f5gc-udm
F5GC_UDR_NAME           ?= f5gc-udr
F5GC_WEBUI_NAME		 	?= f5gc-webui

DOCKER_ENV              ?= DOCKER_BUILDKIT=1
DOCKER_TAG              ?= v3.0.4
DOCKER_USER       		?= boeboe
DOCKER_BUILD_ARGS       ?= --rm

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

K8S_DEPLOY_DIR       	?= ./manifests

GNBSIM_K8S_DEPLOY_DIR   ?= ${K8S_DEPLOY_DIR}/${F5GC_GNBSIM_NAME}
AMF_K8S_DEPLOY_DIR      ?= ${K8S_DEPLOY_DIR}/${F5GC_AMF_NAME}
SMF_K8S_DEPLOY_DIR      ?= ${K8S_DEPLOY_DIR}/${F5GC_SMF_NAME}
UPF_K8S_DEPLOY_DIR      ?= ${K8S_DEPLOY_DIR}/${F5GC_UPF_NAME}
NRF_K8S_DEPLOY_DIR      ?= ${K8S_DEPLOY_DIR}/${F5GC_NRF_NAME}
AUSF_K8S_DEPLOY_DIR     ?= ${K8S_DEPLOY_DIR}/${F5GC_AUSF_NAME}
NSSF_K8S_DEPLOY_DIR     ?= ${K8S_DEPLOY_DIR}/${F5GC_NSSF_NAME}
PCF_K8S_DEPLOY_DIR      ?= ${K8S_DEPLOY_DIR}/${F5GC_PCF_NAME}
UDM_K8S_DEPLOY_DIR      ?= ${K8S_DEPLOY_DIR}/${F5GC_UDM_NAME}
UDR_K8S_DEPLOY_DIR      ?= ${K8S_DEPLOY_DIR}/${F5GC_UDR_NAME}
WEBUI_K8S_DEPLOY_DIR    ?= ${K8S_DEPLOY_DIR}/${F5GC_WEBUI_NAME}
MONGODB_K8S_DEPLOY_DIR  ?= ${K8S_DEPLOY_DIR}/f5gc-mongodb
N6DUMMY_K8S_DEPLOY_DIR  ?= ${K8S_DEPLOY_DIR}/f5gc-n6dummy

K8S_CNI_DIR       		?= ./clusters/cni

.PHONY: build-base build-gnbsim build-amf build-smf build-upf build-nrf build-ausf build-nssf build-pcf build-udm build-udr build-webui
.PHONY: push-base push-gnbsim push-amf push-smf push-upf push-nrf push-ausf push-nssf push-pcf push-udm push-udr push-webui
.PHONY: create-ns deploy-mongodb deploy-n6dummy deploy-base deploy-gnbsim deploy-amf deploy-smf deploy-upf deploy-nrf deploy-ausf deploy-nssf deploy-pcf deploy-udm deploy-udr deploy-webui
.PHONY: undeploy-gnbsim undeploy-amf undeploy-smf undeploy-upf undeploy-nrf undeploy-ausf undeploy-nssf undeploy-pcf undeploy-udm undeploy-udr undeploy-webui undeploy-n6dummy undeploy-mongodb delete-ns

.PHONY: help

help: ## This help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help


build: build-base build-gnbsim build-amf build-smf build-upf build-nrf build-ausf build-nssf build-pcf build-udm build-udr build-webui ## Build all images locally

push: push-base push-gnbsim push-amf push-smf push-upf push-nrf push-ausf push-nssf push-pcf push-udm push-udr push-webui ## Push all images to dockerhub

deploy: create-ns deploy-mongodb deploy-n6dummy deploy-gnbsim deploy-amf deploy-smf deploy-upf deploy-nrf deploy-ausf deploy-nssf deploy-pcf deploy-udm deploy-udr deploy-webui ## Deploy all to k8s

undeploy: undeploy-gnbsim undeploy-amf undeploy-smf undeploy-upf undeploy-nrf undeploy-ausf undeploy-nssf undeploy-pcf undeploy-udm undeploy-udr undeploy-webui undeploy-n6dummy undeploy-mongodb delete-ns ## Undeploy all from k8s


### Base Image ###
build-base:
	${DOCKER_ENV} docker build ${DOCKER_BUILD_ARGS} \
		--tag ${BASE_IMAGE_NAME} \
		--file ./images/${F5GC_BASE_NAME}/Dockerfile.alpine \
		./images/${F5GC_BASE_NAME}
push-base:
	${DOCKER_ENV} docker push ${BASE_IMAGE_NAME}

### K8S Namespace ###
create-ns:
	kubectl apply -f ${K8S_DEPLOY_DIR}/
delete-ns:
	kubectl delete -f ${K8S_DEPLOY_DIR}/ || true


### Mongo DBB ###
deploy-mongodb:
	kubectl apply -k ${MONGODB_K8S_DEPLOY_DIR}
undeploy-mongodb:
	kubectl delete -k ${MONGODB_K8S_DEPLOY_DIR} || true


### N6 Dummy - Between User Plan Function (UPF) and DN (Data Network) ###
deploy-n6dummy:
	kubectl apply -k ${N6DUMMY_K8S_DEPLOY_DIR}
undeploy-n6dummy:
	kubectl delete -k ${N6DUMMY_K8S_DEPLOY_DIR} || true


### GNBSIM - a 5G SA gNB/UE simulator for testing 5GC system ###
build-gnbsim:
	${DOCKER_ENV} docker build ${DOCKER_BUILD_ARGS} \
		--tag ${GNBSIM_IMAGE_NAME} \
		--file ./images/${F5GC_GNBSIM_NAME}/Dockerfile.ubuntu18 \
		--build-arg TAG=${DOCKER_TAG} \
		--no-cache \
		./images/${F5GC_GNBSIM_NAME}
push-gnbsim:
	${DOCKER_ENV} docker push ${GNBSIM_IMAGE_NAME}
deploy-gnbsim:
	kubectl apply -k ${GNBSIM_K8S_DEPLOY_DIR}
undeploy-gnbsim:
	kubectl delete -k ${GNBSIM_K8S_DEPLOY_DIR} || true


### AMF - Access and Mobility Management Function ###
build-amf: build-base
	${DOCKER_ENV} docker build ${DOCKER_BUILD_ARGS} \
		--tag ${AMF_IMAGE_NAME} \
		--file ./images/${F5GC_AMF_NAME}/Dockerfile.alpine \
		--build-arg TAG=${DOCKER_TAG} \
		./images/${F5GC_AMF_NAME}
push-amf:
	${DOCKER_ENV} docker push ${AMF_IMAGE_NAME}
deploy-amf:
	kubectl apply -k ${AMF_K8S_DEPLOY_DIR}
undeploy-amf:
	kubectl delete -k ${AMF_K8S_DEPLOY_DIR} || true


### SMF - Session Management Function ###
build-smf: build-base
	${DOCKER_ENV} docker build ${DOCKER_BUILD_ARGS} \
		--tag ${SMF_IMAGE_NAME} \
		--file ./images/${F5GC_SMF_NAME}/Dockerfile.alpine \
		--build-arg TAG=${DOCKER_TAG} \
		./images/${F5GC_SMF_NAME}
push-smf:
	${DOCKER_ENV} docker push ${SMF_IMAGE_NAME}
deploy-smf:
	kubectl apply -k ${SMF_K8S_DEPLOY_DIR}
undeploy-smf:
	kubectl delete -k ${SMF_K8S_DEPLOY_DIR} || true


### UPF - User Plane Function ###
build-upf: build-base
	${DOCKER_ENV} docker build ${DOCKER_BUILD_ARGS} \
		--tag ${UPF_IMAGE_NAME} \
		--file ./images/${F5GC_UPF_NAME}/Dockerfile.ubuntu18 \
		--build-arg TAG=${DOCKER_TAG} \
		./images/${F5GC_UPF_NAME}
push-upf:
	${DOCKER_ENV} docker push ${UPF_IMAGE_NAME}
deploy-upf:
	kubectl apply -k ${UPF_K8S_DEPLOY_DIR}
undeploy-upf:
	kubectl delete -k ${UPF_K8S_DEPLOY_DIR} || true


### NRF - Network Repository Function ###
build-nrf: build-base
	${DOCKER_ENV} docker build ${DOCKER_BUILD_ARGS} \
		--tag ${NRF_IMAGE_NAME} \
		--file ./images/${F5GC_NRF_NAME}/Dockerfile.alpine \
		--build-arg TAG=${DOCKER_TAG} \
		./images/${F5GC_NRF_NAME}
push-nrf:
	${DOCKER_ENV} docker push ${NRF_IMAGE_NAME}
deploy-nrf:
	kubectl apply -k ${NRF_K8S_DEPLOY_DIR}
undeploy-nrf:
	kubectl delete -k ${NRF_K8S_DEPLOY_DIR} || true


### AUSF - Authentication Server Function ###
build-ausf: build-base
	${DOCKER_ENV} docker build ${DOCKER_BUILD_ARGS} \
		--tag ${AUSF_IMAGE_NAME} \
		--file ./images/${F5GC_AUSF_NAME}/Dockerfile.alpine \
		--build-arg TAG=${DOCKER_TAG} \
		./images/${F5GC_AUSF_NAME}
push-ausf:
	${DOCKER_ENV} docker push ${AUSF_IMAGE_NAME}
deploy-ausf:
	kubectl apply -k ${AUSF_K8S_DEPLOY_DIR}
undeploy-ausf:
	kubectl delete -k ${AUSF_K8S_DEPLOY_DIR} || true


### NSSF - Network slice selection function ###
build-nssf: build-base
	${DOCKER_ENV} docker build ${DOCKER_BUILD_ARGS} \
		--tag ${NSSF_IMAGE_NAME} \
		--file ./images/${F5GC_NSSF_NAME}/Dockerfile.alpine \
		--build-arg TAG=${DOCKER_TAG} \
		./images/${F5GC_NSSF_NAME}
push-nssf:
	${DOCKER_ENV} docker push ${NSSF_IMAGE_NAME}
deploy-nssf:
	kubectl apply -k ${NSSF_K8S_DEPLOY_DIR}
undeploy-nssf:
	kubectl delete -k ${NSSF_K8S_DEPLOY_DIR} || true


## PCF - Policy Control Function ###
build-pcf: build-base
	${DOCKER_ENV} docker build ${DOCKER_BUILD_ARGS} \
		--tag ${PCF_IMAGE_NAME} \
		--file ./images/${F5GC_PCF_NAME}/Dockerfile.alpine \
		--build-arg TAG=${DOCKER_TAG} \
		./images/${F5GC_PCF_NAME}
push-pcf:
	${DOCKER_ENV} docker push ${PCF_IMAGE_NAME}
deploy-pcf:
	kubectl apply -k ${PCF_K8S_DEPLOY_DIR}
undeploy-pcf:
	kubectl delete -k ${PCF_K8S_DEPLOY_DIR} || true


### UDM - Unified Data Manager Function ###
build-udm: build-base
	${DOCKER_ENV} docker build ${DOCKER_BUILD_ARGS} \
		--tag ${UDM_IMAGE_NAME} \
		--file ./images/${F5GC_UDM_NAME}/Dockerfile.alpine \
		--build-arg TAG=${DOCKER_TAG} \
		./images/${F5GC_UDM_NAME}
push-udm:
	${DOCKER_ENV} docker push ${UDM_IMAGE_NAME}
deploy-udm:
	kubectl apply -k ${UDM_K8S_DEPLOY_DIR}
undeploy-udm:
	kubectl delete -k ${UDM_K8S_DEPLOY_DIR} || true


### UDR - Unified Data Repository ###
build-udr: build-base
	${DOCKER_ENV} docker build ${DOCKER_BUILD_ARGS} \
		--tag ${UDR_IMAGE_NAME} \
		--file ./images/${F5GC_UDR_NAME}/Dockerfile.alpine \
		--build-arg TAG=${DOCKER_TAG} \
		./images/${F5GC_UDR_NAME}
push-udr:
	${DOCKER_ENV} docker push ${UDR_IMAGE_NAME}
deploy-udr:
	kubectl apply -k ${UDR_K8S_DEPLOY_DIR}
undeploy-udr:
	kubectl delete -k ${UDR_K8S_DEPLOY_DIR} || true


### WebUI ###
build-webui: build-base
	${DOCKER_ENV} docker build ${DOCKER_BUILD_ARGS} \
		--tag ${WEBUI_IMAGE_NAME} \
		--file ./images/${F5GC_WEBUI_NAME}/Dockerfile.alpine \
		--build-arg TAG=${DOCKER_TAG} \
		./images/${F5GC_WEBUI_NAME}
push-webui:
	${DOCKER_ENV} docker push ${WEBUI_IMAGE_NAME}
deploy-webui:
	kubectl apply -k ${WEBUI_K8S_DEPLOY_DIR}
undeploy-webui:
	kubectl delete -k ${WEBUI_K8S_DEPLOY_DIR} || true


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

reboot-k8s: ## Reboot Kubernetes Cluster
	ssh master sudo reboot
	ssh node1 sudo reboot
	ssh node2 sudo reboot
	ssh node3 sudo reboot
	ssh node4 sudo reboot
