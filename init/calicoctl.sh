#!/usr/bin/env bash

echo "Installing calicoctl"
curl -O -L  https://github.com/projectcalico/calicoctl/releases/download/v3.17.0/calicoctl
chmod +x calicoctl
sudo mv calicoctl /usr/local/bin

sudo tee -a /home/ubuntu/.bashrc << END

# Calicoctl environment variables
export DATASTORE_TYPE=kubernetes
export KUBECONFIG=/home/ubuntu/.kube/config
END

sudo tee -a /root/.bashrc << END

# Calicoctl environment variables
export DATASTORE_TYPE=kubernetes
export KUBECONFIG=/home/ubuntu/.kube/config
END
