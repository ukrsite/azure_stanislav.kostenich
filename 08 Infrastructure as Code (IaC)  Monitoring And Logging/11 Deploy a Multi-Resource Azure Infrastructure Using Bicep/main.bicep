// Parameters
param location string = resourceGroup().location
param adminUsername string
param adminPublicKey string
param vmSize string = 'Standard_B2s'
param environmentName string = 'dev'

// Modules
module network 'modules/network.bicep' = {
  name: 'networkDeployment'
  params: {
    location: location // Ensure 'location' is a parameter in 'network.bicep'
    environmentName: environmentName
  }
}

module vm 'modules/vm.bicep' = {
  name: 'vmDeployment'
  params: {
    location: location // Ensure 'location' is a parameter in 'vm.bicep'
    adminUsername: adminUsername
    adminPublicKey: adminPublicKey
    vmSize: vmSize
    environmentName: environmentName
    subnetId: network.outputs.subnetId
    nsgId: network.outputs.nsgId
  }
}

// Outputs
output vmPublicIP string = vm.outputs.vmPublicIP
