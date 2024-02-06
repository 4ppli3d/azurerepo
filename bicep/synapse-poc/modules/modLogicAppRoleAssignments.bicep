param parSynapseWorkspaceName string

param parLogicAppId string

resource resSynapseWorkspaceRef 'Microsoft.Synapse/workspaces@2021-06-01' existing = {
 name: parSynapseWorkspaceName
}

resource resRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(uniqueString(parSynapseWorkspaceName, parLogicAppId))
  scope: resSynapseWorkspaceRef
  properties: {
    principalId: parLogicAppId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  }
}
