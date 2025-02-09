param (
    [boolean]$AutoConfirm = $false
)

# WEBHOOK_URL=https://8d44c37b-5d9e-4cfd-b7c9-8b11ba6e20b5.webhook.eus.azure-automation.net/webhooks?token=Mnq8qNHyfRW%2fRZxcMoASL74lRNM9TRtTCUhxb%2bmgO8A%3d
# az rest --method post --uri $WEBHOOK_URL --body "{ \"AutoConfirm\": true }"

# Authenticate using Managed Identity
try {
    Write-Output "Logging in to Azure using Managed Identity..."
    $AzContext = Connect-AzAccount -Identity

    # Retrieve the list of subscriptions
    $Subscriptions = Get-AzSubscription

    if ($Subscriptions.Count -eq 0) {
        throw "No Azure subscriptions found for the Managed Identity."
    }

    # Select the first available subscription
    $SubscriptionId = $Subscriptions[0].Id
    Write-Output "Using Subscription: $SubscriptionId"

    # Ensure Subscription Context is Set
    Set-AzContext -SubscriptionId $SubscriptionId

} catch {
    Write-Error "Azure login failed: $_"
    exit 1
}

# Define the cutoff date (30 days ago)
$cutoffDate = (Get-Date).AddDays(-30)

# Get all resource groups
$resourceGroups = Get-AzResourceGroup

if (-not $resourceGroups) {
    Write-Output "No resource groups found. Exiting."
    exit 0
}

# Initialize an array to store stale resource groups
$staleResourceGroups = @()

foreach ($rg in $resourceGroups) {
    # Get all resources in the resource group
    $resources = Get-AzResource -ResourceGroupName $rg.ResourceGroupName
    
    # Assume the group is stale unless a resource is found with recent activity
    $isStale = $true
    
    foreach ($resource in $resources) {
        $activityLogs = Get-AzActivityLog -ResourceId $resource.Id -StartTime $cutoffDate -MaxRecord 1
        if ($activityLogs) {
            $isStale = $false
            break
        }
    }
    
    # If no resources have been modified, mark the group as stale
    if ($isStale) {
        $staleResourceGroups += [PSCustomObject]@{
            ResourceGroupName = $rg.ResourceGroupName
            Location = $rg.Location
        }
    }
}

# Display the stale resource groups
if ($staleResourceGroups.Count -gt 0) {
    Write-Output "Stale resource groups detected:"
    $staleResourceGroups | Format-Table -AutoSize

    # Ask for user confirmation before deleting
    $confirm = if ($AutoConfirm) { "yes" } else { Read-Host "Do you want to delete these stale resource groups? (yes/no)" }
    if ($confirm -eq "yes") {
        foreach ($rg in $staleResourceGroups) {
            try {
                Remove-AzResourceGroup -Name $rg.ResourceGroupName -Force -Confirm:$false
                Write-Output "Deleted resource group: $($rg.ResourceGroupName)"
            } catch {
                Write-Error "Failed to delete resource group: $($rg.ResourceGroupName). Error: $_"
            }
        }
    } else {
        Write-Output "No resource groups were deleted."
    }
} else {
    Write-Output "No stale resource groups found."
}
