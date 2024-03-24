targetScope = 'subscription'

@sys.description('The location for the resources.')
param parLocation string

@sys.description('The number of Development VMs to deploy.')
param parVmCount int

@sys.description('The Admin Username for the Development VMs.')
param parAdminUsername string

@sys.description('The Admin Password for the Development VMs.')
@secure()
param parAdminPassword string

resource resDevelopmentRg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: 'development-rg'
  location: parLocation
}

module modVirtualNetworkDeploy 'modules/virtualNetwork.bicep' = {
  name: 'modVirtualNetworkDeploy'
  scope: resDevelopmentRg
  params: {
    parLocation: parLocation
  }
}

module modVirtualMachineDeploy 'modules/virtualMachines.bicep' = {
  name: 'modVirtualMachineDeploy'
  scope: resDevelopmentRg
  params: {
    parVmCount: parVmCount
    parAdminPassword: parAdminPassword
    parAdminUsername: parAdminUsername
    parSubnetResourceId:modVirtualNetworkDeploy.outputs.outVirtualNetworkSubnetId
    parLocation: parLocation
  }
}
