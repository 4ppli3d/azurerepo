@sys.description('The Azure Region to deploy the Synapse Environment into.')
param parLocation string

var varAdlsName = 'stgadls${uniqueString(subscription().id)}'

resource resAdls 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: varAdlsName
  location: parLocation
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'BlobStorage'
  properties: {
    isHnsEnabled: true
    supportsHttpsTrafficOnly: true
    accessTier: 'Hot'
  }
  resource resAdlsBlobServices 'blobServices' = {
    name: 'default'
    resource resAdlsBlobContainer 'containers' = {
      name: 'container'
    }
  }
}

output outAdlsName string = varAdlsName
