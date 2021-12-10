# Makefile

GIT_REPO=https://github.com/boeboe/free5gc-k8s
HOME_DIR=/home/ubuntu
REPO_DIR=${HOME_DIR}/free5gc-k8s


.PHONY: help

help: ## This help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help


install-k8s: ## Install k8s using kubespray
	cd /tmp && git clone https://github.com/kubernetes-sigs/kubespray.git && \
	cd kubespray && git checkout release-2.14 && \
	cp -R ${REPO_DIR}/kubespray/aspenmesh /tmp/kubespray/inventory && \
	sudo pip3 install -r requirements.txt && \
	ansible-playbook -i inventory/aspenmesh/hosts.yaml  --become --become-user=root cluster.yml


reset-k8s: ## Reset k8s using kubespray
	cd /tmp && git clone https://github.com/kubernetes-sigs/kubespray.git && \
	cd kubespray && git checkout release-2.14 && \
	cp -R ${REPO_DIR}/kubespray/aspenmesh /tmp/kubespray/inventory && \
	sudo pip3 install -r requirements.txt && \
	ansible-playbook -i inventory/aspenmesh/hosts.yaml  --become --become-user=root reset.yml || true
	ssh master "sudo service kubelet stop ; sudo rm -rf /etc/kubernetes /var/lib/kubelet" || true
	ssh node1 "sudo service kubelet stop ; sudo rm -rf /etc/kubernetes /var/lib/kubelet" || true
	ssh node2 "sudo service kubelet stop ; sudo rm -rf /etc/kubernetes /var/lib/kubelet" || true
	ssh node3 "sudo service kubelet stop ; sudo rm -rf /etc/kubernetes /var/lib/kubelet" || true
	ssh node4 "sudo service kubelet stop ; sudo rm -rf /etc/kubernetes /var/lib/kubelet" || true


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
	ssh jumphost 		'cd ${REPO_DIR}; git pull > /dev/null ; sudo updatedb' || true
	ssh master  		'cd ${REPO_DIR}; git pull > /dev/null ; sudo updatedb' || true
	ssh node1   		'cd ${REPO_DIR}; git pull > /dev/null ; sudo updatedb' || true
	ssh node2   		'cd ${REPO_DIR}; git pull > /dev/null ; sudo updatedb' || true
	ssh node3   		'cd ${REPO_DIR}; git pull > /dev/null ; sudo updatedb' || true
	ssh node4   		'cd ${REPO_DIR}; git pull > /dev/null ; sudo updatedb' || true
