@sys.description('Azure Region to deploy the Virtual Network to.')
param parLocation string

@sys.description('Name of the Virtual Network.')
param parVnetName string

resource resVirtualNetwork 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: parVnetName
  location: parLocation
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16' ]
    }
    subnets: [
      {
        name: 'development-subnet'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
      }
    }
    ]
  }
}

output outVirtualNetworkName string = resVirtualNetwork.name
output outVirtualNetworkSubnetId string = resVirtualNetwork.properties.subnets[0].id
