# Kubespray configuration

Move this folder to Kubespray Git Repo : ~/kubespray/inventory/aspenmesh [branch release-2.14]

To run the ansible installer

```
# cd ~/kubespray
# ansible-playbook -i inventory/aspenmesh/hosts.yaml --become --become-user=root cluster.yml
```
