#!/bin/bash

# chmod +x manage_azure_storage.sh
# ./manage_azure_storage.sh

# Define Variables
RESOURCE_GROUP="devStorageResourceGroup"
STORAGE_ACCOUNT="devmystoragecli"
LOCATION="eastus"

# Login to Azure (if not already logged in)
echo "🔹 Logging in to Azure..."
az login --output none

# Create Resource Group
echo "🔹 Creating resource group: $RESOURCE_GROUP..."
az group create --name $RESOURCE_GROUP --location $LOCATION --output none

# Create Storage Account
echo "🔹 Creating storage account: $STORAGE_ACCOUNT..."
az storage account create --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP --location $LOCATION --sku Standard_LRS --output none

# List All Storage Accounts
echo "🔹 Listing all storage accounts..."
# az storage account list --output table
az storage account list --query "[?name=='$STORAGE_ACCOUNT']" --output table

# Retrieve Storage Account Connection String
echo "🔹 Retrieving connection string for $STORAGE_ACCOUNT..."
az storage account show-connection-string --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP --output table

# Delete Storage Account
echo "🔹 Deleting storage account: $STORAGE_ACCOUNT..."
az storage account delete --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP --yes

# Delete Resource Group (Optional Cleanup)
echo "🔹 Deleting resource group: $RESOURCE_GROUP..."
az group delete --name $RESOURCE_GROUP --yes --no-wait

echo "✅ Task Completed Successfully!"
