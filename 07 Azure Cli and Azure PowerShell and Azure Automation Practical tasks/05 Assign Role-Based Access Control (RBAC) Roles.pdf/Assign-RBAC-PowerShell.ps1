# Set-ExecutionPolicy -Execut onPolicy Bypass -Scope Process -Force
# ./Assign-RBAC-PowerShell.ps1

# Define variables
$UserEmail = "StanislavKostenich@dmytroslotvinskyygmail.onmicrosoft.com"
$UserName = "StanislavKostenich"
$ResourceGroup = "devRBACResourceGroup"
$StorageAccount = "devrbacstoragecli"
$Location = "West Europe"

# Login to Azure (if needed)
Write-Host "🔹 Logging in to Azure..."
Connect-AzAccount

# Get Subscription ID
$SubscriptionId = (Get-AzSubscription).Id

# Create Resource Group if not exists
Write-Host "🔹 Creating resource group: $ResourceGroup..."
if (-not (Get-AzResourceGroup -Name $ResourceGroup -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $ResourceGroup -Location $Location
}

# Get or Create User
Write-Host "🔹 Checking if user $UserEmail exists..."
$User = Get-AzADUser -UserPrincipalName $UserEmail -ErrorAction SilentlyContinue
if (-not $User) {
    Write-Host "🔹 User $UserEmail does not exist, creating..."
    $User = New-AzADUser -DisplayName $UserName -UserPrincipalName $UserEmail -MailNickname $UserName -PasswordProfile (New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile -Property @{ Password = "Test@1234"; ForceChangePasswordNextLogin = $false }) -AccountEnabled $true
}

# Assign Reader Role at Resource Group Level
Write-Host "🔹 Assigning Reader role to $UserEmail for $ResourceGroup..."
New-AzRoleAssignment -SignInName $UserEmail -RoleDefinitionName "Reader" -Scope "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup"

# Assign Contributor Role at Storage Account Level
Write-Host "🔹 Assigning Contributor role to $UserEmail for Storage Account $StorageAccount..."
$StorageAccountId = (Get-AzStorageAccount -ResourceGroupName $ResourceGroup -Name $StorageAccount).Id
New-AzRoleAssignment -SignInName $UserEmail -RoleDefinitionName "Contributor" -Scope $StorageAccountId

# Verify Role Assignments
Write-Host "🔹 Verifying role assignments for $UserEmail..."
Get-AzRoleAssignment -SignInName $UserEmail | Format-Table

# Remove Role Assignments (Uncomment if needed)
# Write-Host "🔹 Removing role assignments..."
# Remove-AzRoleAssignment -SignInName $UserEmail -RoleDefinitionName "Reader" -Scope "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup"
# Remove-AzRoleAssignment -SignInName $UserEmail -RoleDefinitionName "Contributor" -Scope $StorageAccountId

Write-Host "✅ Task Completed Successfully!"
