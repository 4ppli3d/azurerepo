@sys.description('Azure Region to deploy the Virtual Network to.')
param parLocation string

resource resVirtualNetwork 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: 'development-vnet'
  location: parLocation
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/24' ]
    }
    subnets: [
      {
        name: 'development-subnet'
        properties: {
          addressPrefix: '10.0.0.0/27'
        }
      }
    ]
  }
}

output outVirtualNetworkSubnetId string = resVirtualNetwork.properties.subnets[0].id
