To assign the built-in Contributor role to the Admins group 
for a specific resource group, you can use the New-AzRoleAssignment command in Azure PowerShell. 

Here’s a general outline of the steps you would follow:

1 Get the object ID of the Admins group using the Get-MgGroup command.
groupId=064f14ba-f6d4-4192-8d67-4c42c16105b4
2 Save the group object ID in a variable.
2 Get the ID of your subscription using the Get-AzSubscription command.
3 Save the subscription scope in a variable.
4 Assign the Contributor role to the Admins group at the resource group scope using the New-AzRoleAssignment command.
5 Here’s a sample command for assigning the Contributor role:


// Make sure to replace "your-resource-group-name" with the actual name of your resource group.

New-AzRoleAssignment -ObjectId 064f14ba-f6d4-4192-8d67-4c42c16105b4 `
-RoleDefinitionName "Contributor" `
-ResourceGroupName "rs-developers"

References:

Tutorial: Grant a group access to Azure resources using Azure PowerShell
Azure role-based access control in Azure Lab Services
AI-g