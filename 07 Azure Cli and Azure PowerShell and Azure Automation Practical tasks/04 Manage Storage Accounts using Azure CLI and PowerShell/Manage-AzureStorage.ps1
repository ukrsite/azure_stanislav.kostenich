
# Open PowerShell and allow script execution 
# Set-ExecutionPolicy Unrestricted -Scope Process
# .\Manage-AzureStorage.ps1


# Define Variables
$ResourceGroup = "StoragePSResourceGroup"
$StorageAccount = "devmystorageps"
$Location = "westeurope"

# Login to Azure (if not already logged in)
Write-Host "🔹 Logging in to Azure..."
Connect-AzAccount | Out-Null

# Create Resource Group
Write-Host "🔹 Creating resource group: $ResourceGroup..."
New-AzResourceGroup -Name $ResourceGroup -Location $Location -ErrorAction Stop | Out-Null

# Create Storage Account
Write-Host "🔹 Creating storage account: $StorageAccount..."
New-AzStorageAccount -ResourceGroupName $ResourceGroup -Name $StorageAccount -Location $Location -SkuName Standard_LRS -Kind StorageV2 -ErrorAction Stop | Out-Null

# List Storage Account
Write-Host "🔹 Listing storage accounts in subscription..."
Get-AzStorageAccount | Where-Object { $_.StorageAccountName -eq $StorageAccount } | Format-Table -AutoSize

# Retrieve Connection String
Write-Host "🔹 Retrieving connection string for $StorageAccount..."
$ConnectionString = (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroup -Name $StorageAccount)[0].Value
Write-Host "Connection String: $ConnectionString"

# Delete Storage Account
Write-Host "🔹 Deleting storage account: $StorageAccount..."
Remove-AzStorageAccount -ResourceGroupName $ResourceGroup -Name $StorageAccount -Force

# Delete Resource Group (Optional Cleanup)
Write-Host "🔹 Deleting resource group: $ResourceGroup..."
Remove-AzResourceGroup -Name $ResourceGroup -Force -AsJob

Write-Host "✅ Task Completed Successfully!"
