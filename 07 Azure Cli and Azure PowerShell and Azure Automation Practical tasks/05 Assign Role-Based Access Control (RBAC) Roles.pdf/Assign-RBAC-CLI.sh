#!/bin/bash

# Define variables
USER_EMAIL="StanislavKostenich@dmytroslotvinskyygmail.onmicrosoft.com"
USER_NAME="StanislavKostenich"
RESOURCE_GROUP="devRBACResourceGroup"
STORAGE_ACCOUNT="devrbacstoragecli"
LOCATION="eastus"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Login to Azure
echo "🔹 Logging in to Azure..."
az login --output none

# Create Resource Group
echo "🔹 Creating resource group: $RESOURCE_GROUP..."
az group create --name $RESOURCE_GROUP --location $LOCATION --output none

# Assign Reader Role at Resource Group Level
echo "🔹 Assigning Reader role to $USER_EMAIL for $RESOURCE_GROUP..."
az role assignment create --assignee "$USER_EMAIL" --role "Reader" --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP" --output table

# Assign Contributor Role at Storage Account Level
echo "🔹 Assigning Contributor role to $USER_EMAIL for $STORAGE_ACCOUNT..."
STORAGE_ID=$(az storage account show --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP --query "id" -o tsv)
az role assignment create --assignee "$USER_EMAIL" --role "Contributor" --scope "$STORAGE_ID" --output table

# Verify Role Assignments
echo "🔹 Verifying role assignments for $USER_EMAIL..."
az role assignment list --assignee "$USER_EMAIL" --output table
az role assignment list --all --output table | grep $USER_NAME


# Remove Role Assignments
echo "🔹 Removing role assignments..."
az role assignment delete --assignee "$USER_EMAIL" --role "Reader" --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"
az role assignment delete --assignee "$USER_EMAIL" --role "Contributor" --scope "$STORAGE_ID"

echo "✅ Task Completed Successfully!"
