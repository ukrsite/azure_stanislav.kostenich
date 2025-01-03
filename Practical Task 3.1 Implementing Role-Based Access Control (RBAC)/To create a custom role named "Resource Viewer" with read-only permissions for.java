To create a custom role named "Resource Viewer" with read-only permissions for a specific resource group in Azure, follow these steps:

Define the Role: 
Specify the role name as "Resource Viewer" and include the necessary permissions. 
For read-only access, you would typically include actions such as 
Microsoft.Resources/subscriptions/resourceGroups/read.

Use an ARM Template: 
You can create the custom role using an Azure Resource Manager (ARM) template. 
The template should include the role name, permissions, and the scope where the role can be assigned (in this case, the specific resource group).

Assign the Role: 
After creating the role, assign it to the users or groups that need read-only access to the specified resource group.

Make sure you have the required permissions to create custom roles, such as the User Access Administrator role.


// Example ARM Template for Custom Role


Steps to Create and Assign the Role

// 1 Create the Custom Role:

Save the above JSON template to a file, e.g., customRole.json.
Use Azure CLI or PowerShell to create the custom role.
Azure CLI:


# az role definition create --role-definition customRole.json
#    New-AzRoleDefinition -InputFile "customRole.json"
   

// Replace {subscription-id} with your actual subscription ID and {resource-group-name} 
// with the name of the resource group you want to assign the role to.

{
  "Name": "Resource Viewer",
  "IsCustom": true,
  "Description": "Can view resources in a specific resource group",
  "Actions": [
    "Microsoft.Resources/subscriptions/resourceGroups/read",
    "Microsoft.Resources/subscriptions/resourceGroups/resources/read"
  ],
  "NotActions": [],
  "AssignableScopes": [
    "/subscriptions/{subscription-id}/resourceGroups/{resource-group-name}"
  ]
}

2 Assign the Custom Role:

Assign the custom role to a user or group.
Azure CLI:

// Replace {user-principal-name-or-object-id} with the user principal name or object ID of the user, group, 
// or service principal you want to assign the role to.

By following these steps, you will create a custom role named "Resource Viewer" with read-only permissions for a specific resource group and assign it to the desired user or group.

#    az role assignment create --assignee 53d41dbc-716a-4525-9ab0-49b3a7948677 --role "Resource Viewer" --scope /subscriptions/bf75502e-bab2-4709-9623-046fbddb39b7/resourceGroups/rs-developers

#    New-AzRoleAssignment -ObjectId {user-object-id} -RoleDefinitionName "Resource Viewer" -Scope /subscriptions/{subscription-id}/resourceGroups/{resource-group-name}
   

References:
How to use role-based access control in Azure API Management
Create or update Azure custom roles using an ARM template

