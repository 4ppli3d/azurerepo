
@sys.description('The Azure Region to deploy to.')
param parLocation string

@sys.description('The name of the container registry to create.')
param parContainerRegistryName string

resource resContainerRegistry 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' = {
  name: parContainerRegistryName
  location: parLocation
  sku: {
    name: 'Basic'
  }
}
