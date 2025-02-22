#!/bin/bash

# Enable strict mode for error handling
set -euo pipefail

# Variables
RESOURCE_GROUP="terraform-rg-dev2025"
LOCATION="eastus"
STORAGE_ACCOUNT="tfstatestorage12345dev"
CONTAINER_NAME="tfstate-container"
LOG_FILE="terraform_setup.log"

export SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Function to log messages
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Start Logging
log "Starting Terraform backend setup..."

# Step 1: Create Resource Group
log "Creating resource group: $RESOURCE_GROUP"
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output table | tee -a "$LOG_FILE"

# Step 2: Create Storage Account
log "Creating storage account: $STORAGE_ACCOUNT"
az storage account create --name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP" --location "$LOCATION" --sku Standard_LRS --encryption-services blob --output table | tee -a "$LOG_FILE"

# Step 3: Create Storage Container using Azure AD Authentication
log "Creating storage container: $CONTAINER_NAME"
az storage container create --name "$CONTAINER_NAME" --account-name "$STORAGE_ACCOUNT" --auth-mode login --output table | tee -a "$LOG_FILE"
az role assignment create \
  --assignee $(az ad signed-in-user show --query id -o tsv) \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/terraform-rg-dev2025/providers/Microsoft.Storage/storageAccounts/tfstatestorage12345dev" \
  --output table | tee -a "$LOG_FILE"

# Step 4: Confirm Storage Blob Exists using Azure AD Authentication
log "Verifying storage container contents..."
# az storage blob list --container-name "$CONTAINER_NAME" --account-name "$STORAGE_ACCOUNT" --auth-mode login --output table | tee -a "$LOG_FILE"

# az storage blob list --account-name $STORAGE_ACCOUNT --container-name tfstate-container --auth-mode login --output table
# az storage blob service-properties delete-policy update   --account-name $STORAGE_ACCOUNT --enable true --days-retained 7 --auth-mode login --output table 

# Step 0: 
# Create an Azure service principal
log "Creating service principal"
az ad sp create-for-rbac --name tfserviceprincipal --role Contributor --scopes /subscriptions/$SUBSCRIPTION_ID

# {
#   "appId": "0d9e6a34-4d15-4cec-85cf-8279f383fd06",
#   "displayName": "tfserviceprincipal",
#   "password": "D3z8Q~U~YvsXeOFaoyVSxvVYFVDMj-kZ2h4XKcGl",
#   "tenant": "8d1157bb-1f96-415f-824b-ab0a29485d7d"
# }

log "Terraform backend setup completed successfully!"

