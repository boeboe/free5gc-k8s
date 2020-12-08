#!/usr/bin/env bash

sudo tee -a /etc/hosts << END

# Host aliases for the UDF systems
10.1.1.4    jumphost
10.1.1.5    master
10.1.1.6    node1
10.1.1.7    node2
10.1.1.8    node3
10.1.1.9    node4
END

sudo tee -a /etc/hosts << END

# Host aliases for extra services
10.1.1.4    elasticsearch
10.1.1.4    kibana
END

sudo tee -a /etc/hosts << END

# Host aliases for istio gateway exposed workloads
10.1.1.5    f5gc-webui
10.1.1.6    f5gc-webui
10.1.1.7    f5gc-webui
10.1.1.8    f5gc-webui
10.1.1.9    f5gc-webui
10.1.1.5    mongo-express
10.1.1.6    mongo-express
10.1.1.7    mongo-express
10.1.1.8    mongo-express
10.1.1.9    mongo-express
END
