# Makefile

#NGINX_PPA=ppa:nginx/development
NGINX_CERTS_DIR=/etc/ssl/nginx

.PHONY: help

help: ## This help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help


install:  ## Install Nginx OSS
	printf "deb https://nginx.org/packages/ubuntu/ `lsb_release -cs` nginx\n" | sudo tee -a /etc/apt/sources.list.d/nginx.list
	printf "deb-src https://nginx.org/packages/ubuntu/ `lsb_release -cs` nginx\n" | sudo tee -a /etc/apt/sources.list.d/nginx.list
	sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ABF5BD827BD9BF62
	sudo apt-get update -y
	sudo apt-get install -y nginx
	sudo mkdir -p ${NGINX_CERTS_DIR}
	sudo cp ./ssl/* ${NGINX_CERTS_DIR}
	sudo service nginx start


config-update:  ## Update Nginx config
	sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.back
	sudo cp ./nginx.conf /etc/nginx/nginx.conf
	sudo rm -f /etc/nginx/conf.d/*
	sudo cp -R conf.d/* /etc/nginx/conf.d/
	sudo service nginx restart
