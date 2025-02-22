#!/bin/bash

# Enable strict mode for error handling
set -euo pipefail

# Variables
RESOURCE_GROUP="StanislavKostenich"
LOCATION="eastus"
STORAGE_ACCOUNT="tfstatestorage2025dev"
CONTAINER_NAME="tfstate"
VM_NAME="devLynixVM"
LOG_FILE="terraform_setup.log"

# export SUBSCRIPTION_ID=$(az account show --query id -o tsv)

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

# Step 4: Confirm Storage Blob Exists using Azure AD Authentication
log "Verifying storage container contents..."
# az storage blob list --container-name "$CONTAINER_NAME" --account-name "$STORAGE_ACCOUNT" --auth-mode login --output table | tee -a "$LOG_FILE"

# Step 5: Create LynixVM
log "Creating LynixVM: $VM_NAME"
az vm create \
  --resource-group $RESOURCE_GROUP \
  --name $VM_NAME \
  --image Ubuntu2204 \
  --admin-username azureuser \
  --generate-ssh-keys \
  --size Standard_B1s \
  --location eastus \
  --output table | tee -a "$LOG_FILE"

az role assignment create \
  --assignee $(az ad signed-in-user show --query id -o tsv) \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT" \
  --output table | tee -a "$LOG_FILE"

az storage blob list --account-name $STORAGE_ACCOUNT --container-name tfstate --auth-mode login --output table
az storage blob service-properties delete-policy update   --account-name $STORAGE_ACCOUNT --enable true --days-retained 7 --auth-mode login --output table 

CLIENT_ID=0d9e6a34-4d15-4cec-85cf-8279f383fd06
CLIENT_SECRET=D3z8Q~U~YvsXeOFaoyVSxvVYFVDMj-kZ2h4XKcGl
TENANT_ID=8d1157bb-1f96-415f-824b-ab0a29485d7d
az login --service-principal -u $CLIENT_ID -p $CLIENT_SECRET --tenant $TENANT_ID

log "Terraform backend setup completed successfully!"

