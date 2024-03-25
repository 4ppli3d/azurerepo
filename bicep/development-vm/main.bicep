targetScope = 'subscription'

@sys.description('Whether to use an existing Virtual Network or not.')
param parUseExistingVnet bool

@sys.description('SKIP IF NOT USING EXISTING. The name of the Resource Group containing the existing Virtual Network.')
param parVnetRgName string

@sys.description('The name of the existing Virtual Network to use.')
param parVnetName string

@sys.description('The location for the resources.')
param parLocation string

@sys.description('The number of Development VMs to deploy.')
param parVmCount int

@sys.description('The Admin Username for the Development VMs.')
param parAdminUsername string

@sys.description('The Admin Password for the Development VMs.')
@secure()
param parAdminPassword string

@sys.description('The name of the Container Registry to deploy.')
param parContainerRegistryName string

resource resVirtualNetworkRef 'Microsoft.Network/virtualNetworks@2023-09-01' existing = if (parUseExistingVnet) {
  name: parVnetName
  scope: resourceGroup(parVnetRgName)
}

resource resDevelopmentRg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: 'development-rg'
  location: parLocation
}

module modVirtualNetworkDeploy 'modules/virtualNetwork.bicep' = if (!parUseExistingVnet) {
  name: 'modVirtualNetworkDeploy'
  scope: resDevelopmentRg
  params: {
    parVnetName: parVnetName
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
    parSubnetResourceId: parUseExistingVnet? resVirtualNetworkRef.properties.subnets[0].id : modVirtualNetworkDeploy.outputs.outVirtualNetworkSubnetId
    parLocation: parLocation
  }
}

module modContainerRegistryDeploy 'modules/containers.bicep' = {
  name: 'modContainerRegistryDeploy'
  scope: resDevelopmentRg
  params: {
    parLocation: parLocation
    parContainerRegistryName: parContainerRegistryName
  }
}

module modVirtualNetworkGatewayDeploy 'modules/virtualNetworkGateway.bicep' = {
  scope: resDevelopmentRg
  name:  'modVirtualNetworkGatewayDeploy'
  params: {
    parLocation: parLocation
    parVnetName: modVirtualNetworkDeploy.outputs.outVirtualNetworkName
  }
}
