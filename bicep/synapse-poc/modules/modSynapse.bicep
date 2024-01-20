@sys.description('The Azure Region to deploy the Synapse Environment into.')
param parLocation string

@sys.description('Adls Storage Reference.')
param parAdlsStorageName string

@sys.description('Username of the SQL Administrator Login.')
param parSqlAdminUsername string

@sys.description('Password of the SQL Administrator.')
@secure()
param parSqlAdminPassword string

var varSynapseWorkspaceName = 'syn${uniqueString(subscription().id)}'

resource resAdlsReference 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: parAdlsStorageName
}

resource resSynapseWorkspace 'Microsoft.Synapse/workspaces@2021-06-01' = {
  name: varSynapseWorkspaceName
  location: parLocation
  properties: {
    defaultDataLakeStorage: {
      accountUrl: resAdlsReference.properties.primaryEndpoints.dfs
      filesystem: 'container'
    }
    managedVirtualNetwork: 'default'
    sqlAdministratorLogin: parSqlAdminUsername
    sqlAdministratorLoginPassword: parSqlAdminPassword
  }
  resource resWorkspaceFirewallAllowAll 'firewallRules' = {
    name: 'allowAll'
    properties: {
      startIpAddress: '0.0.0.0'
      endIpAddress: '255.255.255.255'
    }
  }
  resource resWorkspaceFirewallAllowAzureIps 'firewallRules' = {
    name: 'AllowAllWIndowsAzureIps'
    properties: {
      startIpAddress: '0.0.0.0'
      endIpAddress: '255.255.255.255'
    }
  }
}
