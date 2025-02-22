#!/bin/bash

# Enable strict mode for error handling
set -euo pipefail

# Variables
RESOURCE_GROUP="devBicepResourceGroup"
ADMIN_USER="azureadmin"
LOG_FILE="Bicep_setup.log"

# export SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Function to log messages
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Start Logging
log "Starting Bicep backend setup..."

# Step 1: Deploy the Template
log "Use the Azure CLI to deploy the Bicep template"
az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file main.bicep \
  --parameters @parameters.json \
  --output table | tee -a "$LOG_FILE"

# Step 2: Verify the Deployment:
PUBLIC_IP=$(az deployment group show \
  --resource-group "$RESOURCE_GROUP" \
  --name vmDeployment \
  --query properties.outputs.vmPublicIP.value \
  --output tsv | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+') 

log "SSH into the VM using the public IP address: ssh $ADMIN_USER@$PUBLIC_IP"

log "Bicep backend setup completed successfully!"

