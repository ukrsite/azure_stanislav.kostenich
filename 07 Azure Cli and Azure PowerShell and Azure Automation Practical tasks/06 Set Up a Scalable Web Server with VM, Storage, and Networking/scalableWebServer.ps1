echo "Setting up variables..."
# Define variables
$resourceGroup = "devWebServerGroup"
$vmName = "WebVM"
$location = "East US"
$vnetName = "WebVNet"
$subnetName = "WebSubnet"
$storageAccount = "webserverlogs" + (Get-Random -Minimum 1000 -Maximum 9999)
$containerName = "logs"
$adminUser = "azureuser"
$adminPassword = "YourSecurePassword123!"
$vmImage = "OpenLogic:CentOS:7_9-gen2:latest"

# Storage account for diagnostics extension
$storageAccountName = $storageAccount
$storageAccountResourceGroup = $resourceGroup

echo "Creating Resource Group..."
az group create --name $resourceGroup --location $location --output table

echo "Creating Virtual Network and Subnet..."
az network vnet create --resource-group $resourceGroup --name $vnetName --address-prefix 10.0.0.0/16 --subnet-name $subnetName --subnet-prefix 10.0.0.0/24 --output table

echo "Creating Storage Account..."
New-AzStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccount -Location $location -SkuName Standard_LRS -Kind StorageV2

echo "Retrieving Storage Account Key..."
$storageKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroup -Name $storageAccount)[0].Value
$context = New-AzStorageContext -StorageAccountName $storageAccount -StorageAccountKey $storageKey

echo "Creating Blob Container..."
New-AzStorageContainer -Name $containerName -Context $context -Permission Off

echo "Creating Table Storage..."
New-AzStorageTable -Name "DiagnosticLogs" -Context $context

echo "Creating Virtual Machine with Cloud-Init..."
$cloudInitScript = @'
#cloud-config
package_update: true
packages:
  - python2
  - python3
  - nginx
runcmd:
  - ln -s /usr/bin/python2 /usr/bin/python
'@

$cloudInitFile = "cloud-init.yaml"
$cloudInitScript | Out-File -Encoding UTF8 $cloudInitFile

az vm create --resource-group $resourceGroup --name $vmName --image $vmImage --vnet-name $vnetName --subnet $subnetName --admin-username $adminUser --admin-password $adminPassword --public-ip-sku Standard --custom-data $cloudInitFile --output table

echo "Opening Port 80 for Web Traffic..."
az vm open-port --port 80 --resource-group $resourceGroup --name $vmName --output table

echo "Enabling system-assigned identity on the VM..."
$vm = Get-AzVM -Name $vmName -ResourceGroupName $resourceGroup
Update-AzVM -ResourceGroupName $resourceGroup -VM $vm -IdentityType SystemAssigned

echo "Getting public settings template for diagnostics..."
$publicSettings = (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Azure/azure-linux-extensions/master/Diagnostic/tests/lad_2_3_compatible_portal_pub_settings.json").Content
$publicSettings = $publicSettings.Replace('__DIAGNOSTIC_STORAGE_ACCOUNT__', $storageAccountName)
$publicSettings = $publicSettings.Replace('__VM_RESOURCE_ID__', $vm.Id)

echo "Generating SAS token for diagnostics..."
$sasToken = New-AzStorageAccountSASToken -Service Blob,Table -ResourceType Service,Container,Object -Permission "racwdluap" -Context (Get-AzStorageAccount -ResourceGroupName $storageAccountResourceGroup -AccountName $storageAccountName).Context -ExpiryTime $([System.DateTime]::Now.AddYears(10))

# Build the protected settings (storage account SAS token)
$protectedSettings = "{'storageAccountName': '$storageAccountName', 'storageAccountSasToken': '$sasToken'}"

echo "Installing LinuxDiagnostic extension..."
Set-AzVMExtension -ResourceGroupName $resourceGroup -VMName $vmName -Location $vm.Location -ExtensionType LinuxDiagnostic -Publisher Microsoft.Azure.Diagnostics -Name LinuxDiagnostic -SettingString $publicSettings -ProtectedSettingString $protectedSettings -TypeHandlerVersion 4.0

echo "Diagnostics successfully enabled on the VM."

echo "Retrieving Public IP..."
$publicIp = az vm list-ip-addresses --resource-group $resourceGroup --name $vmName --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" --output tsv
echo "Web server running at: http://$publicIp"

echo "Press Enter to delete all resources..."
Read-Host "Press Enter to delete all resources..."

echo "Deleting all resources..."
az group delete --name $resourceGroup --yes --no-wait --output table
