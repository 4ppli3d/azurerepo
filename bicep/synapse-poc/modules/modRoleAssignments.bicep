param parAdlsName string

param parSynapseWorkspaceId string

resource resAdlsStorageReference 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: parAdlsName
}

resource resRoleAssignment1 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(uniqueString(parAdlsName))
  scope: resAdlsStorageReference
  properties: {
    principalId: parSynapseWorkspaceId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
  }
}
