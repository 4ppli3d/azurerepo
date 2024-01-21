targetScope  = 'subscription'

@sys.description('The Azure Region to deploy the Synapse Environment into.')
param parLocation string

@sys.description('Username of the SQL Administrator Login.')
param parSqlAdminUsername string

@sys.description('Password of the SQL Administrator.')
@secure()
param parSqlAdminPassword string

var varSynapseResourceGroupName = 'rg-${parLocation}-synapse-001'

resource resSynapseResourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: varSynapseResourceGroupName
  location: parLocation
}

module modAdlsDeploy 'modules/modAdls.bicep' = {
  scope: resourceGroup(resSynapseResourceGroup.name)
  name: 'modAdlsDeploy'
  params: {
    parLocation: parLocation
  }
}

module modSynapseDeploy 'modules/modSynapse.bicep' = {
  scope: resourceGroup(resSynapseResourceGroup.name)
  name: parLocation
  params: {
    parAdlsStorageName: modAdlsDeploy.outputs.outAdlsName
    parLocation: parLocation
    parSqlAdminPassword: parSqlAdminPassword
    parSqlAdminUsername: parSqlAdminUsername
  }
}
