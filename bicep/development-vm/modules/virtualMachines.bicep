@sys.description('The ID of the subnet to deploy the VMs into.')
param parSubnetResourceId string

@sys.description('The chosen Azure Region for your deployment.')
param parLocation string

@sys.description('The username for the VMs.')
param parAdminUsername string

@sys.description('The password for the VMs.')
@secure()
param parAdminPassword string

@sys.description('The number of VMs to deploy.')
param parVmCount int

resource resVmNic 'Microsoft.Network/networkInterfaces@2023-09-01' = [for vm in range(0, parVmCount): {
  name: 'nic-${vm}-0'
  location: parLocation
  properties: {
    ipConfigurations: [{
      name: 'ipconfig-${vm}-0'
      properties: {
        privateIPAllocationMethod: 'Dynamic'
        subnet: {
          id: parSubnetResourceId
        }
      }
    }]
  }
}]

resource resVmDeploy 'Microsoft.Compute/virtualMachines@2023-09-01' = [for vm in range(0, parVmCount): {
  name: 'devvm-${vm}'
  location: parLocation
  properties: {
    osProfile: {
      computerName: 'devvm-${vm}'
      adminUsername: parAdminUsername
      adminPassword: parAdminPassword
    }
    hardwareProfile: {
      vmSize: 'Standard_DS1_v2'
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        name: 'osdisk-${vm}'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [{
        id: resVmNic[vm].id
      }]
    }
  }
}]
