param(
    [string] $adminUsername = "adminuser",
    [SecureString] $adminPassword = (ConvertTo-SecureString "defaultP@ssword" -AsPlainText -Force),
    [string] $ResourceGroupName = "devMyResourceGroup",
    [string] $location = "EastUS",
    [string] $VMName = "devMyWinVM",
    [string] $diskName = "WebServerDisk",
    [int] $diskSizeGB = 128
)

# Initialize logging function
function Log-Message {
    param (
        [string] $message,
        [string] $level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Output "[$timestamp] [$level] $message"
}

# Authenticate using Managed Identity
Log-Message "Authenticating using Managed Identity..."
$AzContext = Connect-AzAccount -Identity
if (-not $AzContext) {
    Log-Message "Failed to authenticate using Managed Identity." "ERROR"
    throw "Failed to authenticate using Managed Identity."
}

# Get Subscription ID and set context
$SubscriptionId = (Get-AzSubscription -DefaultProfile $AzContext).Id
Set-AzContext -SubscriptionId $SubscriptionId
Log-Message "Set context to Subscription ID: $SubscriptionId"

Log-Message "Initializing variables..."

# Create a new Resource Group
Log-Message "Creating resource group $ResourceGroupName in location $location..."
New-AzResourceGroup -Name $ResourceGroupName -Location $location -Force
Log-Message "Resource group $ResourceGroupName created successfully."

# Create Virtual Network
Log-Message "Creating virtual network for $VMName..."
$vnet = New-AzVirtualNetwork -Name "$VMName-VNet" -ResourceGroupName $ResourceGroupName -Location $location -AddressPrefix "10.0.0.0/16" -Force -Confirm:$false
Log-Message "Virtual network $VMName-VNet created successfully."

# Create Subnet
Log-Message "Creating subnet..."
Add-AzVirtualNetworkSubnetConfig -Name "default" -AddressPrefix "10.0.0.0/24" -VirtualNetwork $vnet | Out-Null
$updatedVNet = Set-AzVirtualNetwork -VirtualNetwork $vnet

# Validate that subnet creation was successful
if (-not $updatedVNet.Subnets -or $updatedVNet.Subnets.Count -eq 0) {
    Log-Message "Failed to create subnet." "ERROR"
    throw "Failed to create subnet."
}
Log-Message "Subnet created successfully."

# Create Public IP
Log-Message "Creating public IP for $VMName..."
$publicIp = New-AzPublicIpAddress -ResourceGroupName $ResourceGroupName `
                                  -Name "$VMName-PublicIP" `
                                  -Location $location `
                                  -AllocationMethod Static `
                                  -Sku Standard
Log-Message "Public IP $VMName-PublicIP created successfully."

# Create Network Interface
Log-Message "Creating network interface for $VMName..."
$nic = New-AzNetworkInterface -ResourceGroupName $ResourceGroupName `
                              -Name "$VMName-NIC" `
                              -Location $location `
                              -SubnetId $updatedVNet.Subnets[0].Id `
                              -PublicIpAddressId $publicIp.Id
# Validate NIC creation
if (-not $nic) {
    Log-Message "Failed to create Network Interface." "ERROR"
    throw "Failed to create Network Interface."
}
Log-Message "Network Interface $VMName-NIC created successfully."

# Create Network Security Group (NSG) to allow inbound port 80 (HTTP)
Log-Message "Creating Network Security Group for $VMName..."
$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroupName `
                                  -Location $location `
                                  -Name "$VMName-NSG"
Log-Message "Network Security Group $VMName-NSG created successfully."

# Create inbound rule to allow port 80 (HTTP)
Log-Message "Creating inbound rule for HTTP (port 80)..."
$rule = New-AzNetworkSecurityRuleConfig -Name "Allow-HTTP" `
                                         -Description "Allow inbound HTTP traffic on port 80" `
                                         -Access Allow `
                                         -Protocol Tcp `
                                         -Direction Inbound `
                                         -Priority 1000 `
                                         -SourceAddressPrefix "*" `
                                         -SourcePortRange "*" `
                                         -DestinationAddressPrefix "*" `
                                         -DestinationPortRange 80
$nsg | Add-AzNetworkSecurityRuleConfig -SecurityRule $rule
$nsg | Set-AzNetworkSecurityGroup
Log-Message "Inbound rule for port 80 created successfully."

# Associate NSG with the NIC
Log-Message "Associating Network Security Group with Network Interface..."
$nic | Set-AzNetworkInterface -NetworkSecurityGroup $nsg
Log-Message "Network Security Group associated successfully."

# Create VM Configuration
Log-Message "Creating VM configuration for $VMName..."
$vmConfig = New-AzVMConfig -VMName $VMName -VMSize "Standard_DS1_v2" | `
             Set-AzVMOperatingSystem -Windows -ComputerName $VMName -Credential (New-Object System.Management.Automation.PSCredential -ArgumentList $adminUsername, $adminPassword) | `
             Set-AzVMSourceImage -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2019-Datacenter" -Version "latest" | `
             Add-AzVMNetworkInterface -Id $nic.Id
Log-Message "VM configuration for $VMName created successfully."

# Create VM
Log-Message "Deploying VM $VMName..."
New-AzVM -ResourceGroupName $ResourceGroupName -Location $location -VM $vmConfig
Log-Message "VM $VMName deployed successfully."

# Create Managed Disk
Log-Message "Creating managed disk $diskName..."
$diskConfig = New-AzDiskConfig -SkuName Standard_LRS -Location $location -CreateOption Empty -DiskSizeGB $diskSizeGB
New-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $diskName -Disk $diskConfig
Log-Message "Managed disk $diskName created successfully."

# Attach Managed Disk to VM
Log-Message "Attaching managed disk $diskName to VM $VMName..."
$vm = Get-AzVM -ResourceGroupName $ResourceGroupName -VMName $VMName
$disk = Get-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $diskName
$vm = Add-AzVMDataDisk -VM $vm -ManagedDiskId $disk.Id -Lun 0 -CreateOption Attach
Update-AzVM -ResourceGroupName $ResourceGroupName -VM $vm
Log-Message "Managed disk $diskName attached to VM $VMName successfully."

Log-Message "Deployment and configuration completed successfully."
