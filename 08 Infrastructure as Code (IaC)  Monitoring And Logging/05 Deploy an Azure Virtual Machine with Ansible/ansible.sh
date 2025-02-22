#!/bin/bash

# Write Ansible Inventory File
# Write an Ansible Role for Nginx
# Create an Ansible Playbook (`azure_vm_setup.yml`)
# ansible-galaxy init roles/nginx
# Edit `roles/nginx/tasks/main.yml`
# Create `roles/nginx/files/index.html`

# Run the Playbook
ansible-playbook --ask-vault-pass -i inventory.yml azure_vm_setup.yml

az vm show -d -g ansible-rg -n ansible-vm --query publicIps -o tsv

# http://<public-ip>