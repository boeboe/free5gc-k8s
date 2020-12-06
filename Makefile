# Makefile

GIT_REPO=https://github.com/boeboe/free5gc-k8s
HOME_DIR=/home/ubuntu
REPO_DIR=${HOME_DIR}/free5gc-k8s

K8S_DEPLOY_DIR								?= ./f5gcore/manifests

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

.PHONY: help

help: ## This help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help


deploy:  ## Deployment F5GCore Compoments
	kubectl apply -f ${K8S_DEPLOY_DIR}/00_namespace.yaml || true
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


undeploy: ## Undeployment F5GCore Compoments
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
	kubectl delete -f ${K8S_DEPLOY_DIR}/00_namespace.yaml || true


install-k8s: ## Install k8s using kubespray
	cd /tmp && git clone https://github.com/kubernetes-sigs/kubespray.git && \
	cd kubespray && git checkout release-2.14 && \
	cp -R ${REPO_DIR}/kubespray/aspenmesh /tmp/kubespray/inventory && \
	sudo pip3 install -r requirements.txt && \
	ansible-playbook -i inventory/aspenmesh/hosts.yml  --become --become-user=root cluster.yml


reboot-k8s: ## Reboot k8s cluster hosts
	ssh master sudo reboot || true
	ssh node1 sudo reboot || true
	ssh node2 sudo reboot || true
	ssh node3 sudo reboot || true
	ssh node4 sudo reboot || true


git-clone-all: ## Clone all git repos
	ssh jumphost 		'cd ${HOME_DIR} ; git clone ${GIT_REPO}' || true
	ssh master  		'cd ${HOME_DIR} ; git clone ${GIT_REPO}' || true
	ssh node1   		'cd ${HOME_DIR} ; git clone ${GIT_REPO}' || true
	ssh node2   		'cd ${HOME_DIR} ; git clone ${GIT_REPO}' || true
	ssh node3   		'cd ${HOME_DIR} ; git clone ${GIT_REPO}' || true
	ssh node4   		'cd ${HOME_DIR} ; git clone ${GIT_REPO}' || true


git-pull-all: ## Pull all git repos
	ssh jumphost 		'cd ${REPO_DIR}; git pull ; sudo updatedb' || true
	ssh master  		'cd ${REPO_DIR}; git pull ; sudo updatedb' || true
	ssh node1   		'cd ${REPO_DIR}; git pull ; sudo updatedb' || true
	ssh node2   		'cd ${REPO_DIR}; git pull ; sudo updatedb' || true
	ssh node3   		'cd ${REPO_DIR}; git pull ; sudo updatedb' || true
	ssh node4   		'cd ${REPO_DIR}; git pull ; sudo updatedb' || true
