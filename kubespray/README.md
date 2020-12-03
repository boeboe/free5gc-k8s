# Kubespray configuration

Move this folder to Kubespray Git Repo : ~/kubespray/inventory/aspenmesh [branch release-2.14]

To run the ansible installer

```
# cd ~/kubespray
# ansible-playbook -i inventory/aspenmesh/hosts.yaml --become --become-user=root cluster.yml
```


If you want to upgrade your K8S version of the cluster:
```
# cd ~/kubespray
# ansible-playbook -i inventory/aspenmesh/hosts.yaml --become --become-user=root upgrade-cluster.yml -e kube_version=v1.18.12
```
