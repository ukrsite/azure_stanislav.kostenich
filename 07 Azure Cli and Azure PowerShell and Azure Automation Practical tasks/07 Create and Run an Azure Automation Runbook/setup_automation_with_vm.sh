#!/bin/bash

# Set variables
RESOURCE_GROUP="devMyResourceGroup"
AUTOMATION_ACCOUNT="devMyAutomationAccount"
RUNBOOK_NAME="StartAzureVMRunbook"
LOCATION="East US"
VM_NAME="devMyLinuxVM"
VNET_NAME="MyVNet"
SUBNET_NAME="MySubnet"
VM_SIZE="Standard_B1s"
ADMIN_USER="azureuser"
ADMIN_PASSWORD="YourSecurePassword123!"
SCHEDULE_NAME="DailySchedule"
START_TIME="2025-02-09T06:00:00Z"
VM_IMAGE="OpenLogic:CentOS:7_9-gen2:latest"
SUBSCRIPTION_ID="9a6ae428-d8c3-44fe-bdf2-4e08593901a0"

echo "============================================="
echo "🚀 Step 1: Creating Azure Resource Group"
echo "============================================="
az group create --name $RESOURCE_GROUP --location "$LOCATION" --output table

echo "============================================="
echo "🌐 Step 2: Creating Virtual Network and Subnet"
echo "============================================="
az network vnet create --resource-group $RESOURCE_GROUP --name $VNET_NAME --address-prefix 10.0.0.0/16 --subnet-name $SUBNET_NAME --subnet-prefix 10.0.1.0/24 --output table

echo "============================================="
echo "💻 Step 3: Creating Linux Virtual Machine (CentOS 7.9)"
echo "============================================="
az vm create --resource-group $RESOURCE_GROUP --name $VM_NAME \
    --image $VM_IMAGE --size $VM_SIZE \
    --vnet-name $VNET_NAME --subnet $SUBNET_NAME \
    --admin-username $ADMIN_USER --admin-password $ADMIN_PASSWORD \
    --public-ip-sku Standard --output table

echo "============================================="
echo "🔐 Step 4: Opening SSH Port (22)"
echo "============================================="
az vm open-port --port 22 --resource-group $RESOURCE_GROUP --name $VM_NAME --output table

echo "============================================="
echo "🛠 Step 5: Creating Azure Automation Account (with Managed Identity & Role Assignment)"
echo "============================================="

az config set extension.dynamic_install_allow_preview=true
az config set extension.use_dynamic_install=yes_without_prompt


az automation account create \
  --name $AUTOMATION_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --location "$LOCATION" \
  --output table
az resource update \
  --resource-group $RESOURCE_GROUP \
  --name $AUTOMATION_ACCOUNT \
  --resource-type Microsoft.Automation/automationAccounts \
  --set identity.type="SystemAssigned" \
  --output table

# Get the Managed Identity's Principal ID
IDENTITY_PRINCIPAL_ID=$(az automation account show \
  --name $AUTOMATION_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --query "identity.principalId" -o tsv)

echo "ℹ️  Managed Identity Principal ID: $IDENTITY_PRINCIPAL_ID"

# Sleep for a longer period to account for replication delay (10 seconds)
echo "⏳ Sleeping for 5 seconds to allow more time for replication..."
sleep 5
az vm deallocate --resource-group $RESOURCE_GROUP --name $VM_NAME --output table
echo "✅ VM $VM_NAME has been stopped successfully."

# Assign Contributor Role to the Managed Identity with explicit principal type
az role assignment create \
  --assignee-object-id $IDENTITY_PRINCIPAL_ID \
  --role "Contributor" \
  --scope /subscriptions/$SUBSCRIPTION_ID \
  --assignee-principal-type "ServicePrincipal"\
  --output table  

# Check if the role assignment was successful
if [ $? -eq 0 ]; then
    echo "✅ Role 'Contributor' assigned successfully to Managed Identity."
else
    echo "❌ Failed to assign role. Please check the error message for details."
    az role assignment create \
  --assignee-object-id $IDENTITY_PRINCIPAL_ID \
  --role "Contributor" \
  --scope /subscriptions/$SUBSCRIPTION_ID \
  --assignee-principal-type "ServicePrincipal"\
  --output table  
fi


echo "✅ Automation Account created and Managed Identity assigned with Contributor role."


echo "============================================="
echo "📄 Step 6: Creating PowerShell Runbook"
echo "============================================="
az automation runbook create --automation-account-name $AUTOMATION_ACCOUNT --name $RUNBOOK_NAME --resource-group $RESOURCE_GROUP --type PowerShell --output table

echo "============================================="
echo "✍️ Step 7: Uploading Runbook Script"
echo "============================================="

az automation runbook replace-content --automation-account-name $AUTOMATION_ACCOUNT \
  --resource-group $RESOURCE_GROUP --name $RUNBOOK_NAME --content '
param (
    [string]$ResourceGroupName = "devMyResourceGroup",
    [string]$VMName = "devMyLinuxVM"
)

# Authenticate using Managed Identity
$AzContext = Connect-AzAccount -Identity

# Get Subscription ID explicitly
$SubscriptionId = (Get-AzSubscription -TenantId $AzContext.Context.Tenant.Id).Id

# Ensure Subscription Context is Set
Set-AzContext -SubscriptionId $SubscriptionId

# Start the VM
Start-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName

Write-Output "VM $VMName in resource group $ResourceGroupName started successfully!"
' --output table


echo "============================================="
echo "🚀 Step 8: Publishing Runbook"
echo "============================================="
az automation runbook publish --automation-account-name $AUTOMATION_ACCOUNT --resource-group $RESOURCE_GROUP --name $RUNBOOK_NAME --output table

echo "============================================="
echo "🔬 Step 9: Testing Runbook Execution"
echo "============================================="
az automation runbook start --automation-account-name $AUTOMATION_ACCOUNT --resource-group $RESOURCE_GROUP --name $RUNBOOK_NAME --output table

echo "============================================="
echo "📅 Step 11: Linking Schedule to Runbook"
echo "============================================="
# Create the schedule first
az automation schedule create \
  --automation-account-name $AUTOMATION_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --name "DailySchedule" \
  --frequency "Day" \
  --interval 1 \
  --start-time "2025-02-09T06:00:00Z"

# Now, link the schedule to the runbook
az automation runbook schedule link \
  --automation-account-name $AUTOMATION_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --runbook-name $RUNBOOK_NAME \
  --schedule-id "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Automation/automationAccounts/$AUTOMATION_ACCOUNT/schedules/DailySchedule"

echo "============================================="
echo "🌐 Step 11: Retrieving Public IP of the Linux VM"
echo "============================================="
PUBLIC_IP=$(az vm list-ip-addresses --resource-group $RESOURCE_GROUP --name $VM_NAME --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" --output tsv)
echo "🔗 Connect to your CentOS VM: ssh $ADMIN_USER@$PUBLIC_IP"

echo "============================================="
echo "🔍 Step 12: Connecting to VM via SSH"
echo "============================================="

# Check if the public IP is available
if [ -z "$PUBLIC_IP" ]; then
    echo "❌ Public IP not found for the VM. Please verify the VM creation and public IP association."
    exit 1
fi

# Attempt SSH connection with password (if necessary)
if [ -n "$SSH_PASSWORD" ]; then
    # If SSH password is provided, use sshpass
    sshpass -p "$SSH_PASSWORD" ssh -o StrictHostKeyChecking=no $ADMIN_USER@$PUBLIC_IP << EOF
        echo "✅ Successfully connected to the VM!"
        hostname
        exit
EOF
else
    # Try SSH without password (key-based authentication)
    ssh -o StrictHostKeyChecking=no $ADMIN_USER@$PUBLIC_IP << EOF
        echo "✅ Successfully connected to the VM!"
        hostname
        exit
EOF
fi

# Check if SSH was successful
if [ $? -eq 0 ]; then
    echo "✅ SSH connection established successfully to $PUBLIC_IP."
else
    echo "❌ SSH connection failed. Please check firewall settings, NSG rules, or SSH configuration."
    echo "Make sure port 22 is open and accessible."
    exit 0  # Exit if password is required or connection fails
fi

echo "============================================="
echo "✅ Task Completed: Runbook Scheduled at 6:00 AM Daily"
echo "============================================="



