param parLocation string

param parVnetName string

resource resVnetGatewaySubnetRef 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' existing = {
  name: '${parVnetName}/GatewaySubnet'
} 

resource resVngPip 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: 'development-vng-pip'
  sku: {
    name: 'Basic'
  }
  location: parLocation
  properties: {

    publicIPAllocationMethod: 'Dynamic'
  }
}

resource resVirtualNetworkGateway 'Microsoft.Network/virtualNetworkGateways@2023-09-01' = {
  name: 'development-vnet-gateway'
  location: parLocation
  properties: {
    sku: {
      name: 'Basic'
      tier: 'Basic'
    }
    vpnType: 'RouteBased'
    ipConfigurations: [
      {
        name: 'development-vnet-gateway-ipconfig'
        properties: {
          publicIPAddress: {
            id: resVngPip.id
          }
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resVnetGatewaySubnetRef.id
          }
        }
      }
    ]
  }
}
