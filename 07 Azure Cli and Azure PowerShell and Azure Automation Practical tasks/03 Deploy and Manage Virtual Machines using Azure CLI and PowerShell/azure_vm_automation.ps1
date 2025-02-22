# Fully automated deployment and management of Azure VMs.
# Uses Azure CLI for MyVM1 and Azure PowerShell for MyVM2.
# Prompts for VM2 credentials (username & password).
# Cleans up resources after execution (optional)

# Open PowerShell (with Admin privileges)
# ./azure_vm_automation.ps1

# Define Variables
$resourceGroup = "VMResourceGroup"
$location = "eastus"
$vm1Name = "MyVM1"
$vm2Name = "MyVM2"
$adminUsername = "azureuser"
$vmImage = "Ubuntu2204"

# Login to Azure
Write-Host "Logging in to Azure..."
az login --only-show-errors | Out-Null
Connect-AzAccount | Out-Null

# Create a Resource Group
Write-Host "Creating resource group: $resourceGroup..."
az group create --name $resourceGroup --location $location --output none

# Create Virtual Machine MyVM1 using Azure CLI
Write-Host "Creating VM: $vm1Name using Azure CLI..."
az vm create --resource-group $resourceGroup --name $vm1Name --image $vmImage --admin-username $adminUsername --generate-ssh-keys --output none

# Create Virtual Machine MyVM2 using Azure PowerShell
Write-Host "Creating VM: $vm2Name using Azure PowerShell..."
New-AzResourceGroup -Name $resourceGroup -Location $location | Out-Null
$cred = Get-Credential -Message "Enter credentials for MyVM2"
New-AzVM -ResourceGroupName $resourceGroup -Name $vm2Name -Image $vmImage -Credential $cred | Out-Null

# Retrieve VM Details
Write-Host "`nListing VM details..."
az vm show --resource-group $resourceGroup --name $vm1Name --output table
Get-AzVM -ResourceGroupName $resourceGroup -Name $vm2Name | Format-Table -AutoSize

# Stop Virtual Machines
Write-Host "`nStopping VMs..."
az vm stop --resource-group $resourceGroup --name $vm1Name --output none
Stop-AzVM -ResourceGroupName $resourceGroup -Name $vm2Name -Force | Out-Null

# Delete Virtual Machines
Write-Host "`nDeleting VMs..."
az vm delete --resource-group $resourceGroup --name $vm1Name --yes --output none
Remove-AzVM -ResourceGroupName $resourceGroup -Name $vm2Name -Force | Out-Null

# Cleanup Resource Group (Optional)
Write-Host "`nDeleting Resource Group (Optional)..."
az group delete --name $resourceGroup --yes --no-wait --output none

Write-Host "`n✅ Task Completed Successfully!"
