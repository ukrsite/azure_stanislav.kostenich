$grp="devResGroup"
$location="eastus"
$vmName="devwindowsvm"
$automationAccount="devMyAutomationAccount2025"

# CREATE RESOURCE GROUP
az group create --name $grp --location $location

# CREATING VM
az vm create --resource-group $grp --name $vmName --image Win2019Datacenter --admin-username adminuser --admin-password Hello@12345#
az vm open-port -g $grp -n $vmName --priority 100 --port 80

# IMPORT THE CONFIGURATION
$grp="devResGroup"
Import-AzAutomationDscConfiguration -Published -ResourceGroupName $grp -SourcePath ./MyDSCConfig.ps1 -Force -AutomationAccountName $automationAccount
