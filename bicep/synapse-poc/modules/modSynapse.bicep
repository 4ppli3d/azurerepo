@sys.description('The Azure Region to deploy the Synapse Environment into.')
param parLocation string

@sys.description('Deploy Apache Spark Pool.')
param parDeployApacheSparkpool bool = true

@sys.description('The size of the Apache Spark Pool.')
@allowed([
  'Small'
  'Medium'
  'Large'
])
param parSparkNodeSize string = 'Medium'

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
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    defaultDataLakeStorage: {
      accountUrl: resAdlsReference.properties.primaryEndpoints.dfs
      filesystem: 'container'
    }
    managedVirtualNetwork: 'default'
    sqlAdministratorLogin: parSqlAdminUsername
    sqlAdministratorLoginPassword: parSqlAdminPassword
  }
  resource resApacheSparkPool 'bigDataPools' = if (parDeployApacheSparkpool) {
    location: parLocation
    name: 'sparkpool'
    properties: {
      autoPause: {
        delayInMinutes: 15
        enabled: true
      }
      autoScale: {
        enabled: true
        maxNodeCount: 3
        minNodeCount: 3
      }
      nodeCount: 3
      nodeSize: parSparkNodeSize
      nodeSizeFamily: 'MemoryOptimized'
      sparkVersion: '2.4'
    }
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
      endIpAddress: '0.0.0.0'
    }
  }
}
