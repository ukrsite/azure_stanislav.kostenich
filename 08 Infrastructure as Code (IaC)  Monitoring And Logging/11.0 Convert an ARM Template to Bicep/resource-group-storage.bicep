@description('Unique name of the Storage Account. Must be globally unique.')
param storageAccountName string

@description('Location for all resources.')
param location string = 'eastus'

@description('SKU Name.')
param skuName string = 'Standard_LRS'

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: skuName
  }
  properties: {
    allowBlobPublicAccess: false
  }
}
