targetScope = 'subscription'

@sys.description('The Azure Region to deploy the Synapse Environment into.')
param parLocation string

@sys.description('Username of the SQL Administrator Login.')
param parSqlAdminUsername string

@sys.description('Password of the SQL Administrator.')
@secure()
param parSqlAdminPassword string

@sys.description('Deploy SQL Pool.')
param parDeploySqlPool bool

@sys.description('The SKU of the SQL Pool.')
@allowed([
  'DW100c'
  'DW200c'
  'DW300c'
  'DW400c'
  'DW500c'
  'DW1000c'
  'DW1500c'
  'DW2000c'
  'DW2500c'
  'DW3000c'
])
param parSqlPoolSku string

@sys.description('Deploy MetaData Sync.')
param parMetaDataSyncEnabled bool

@sys.description('Deploy Apache Spark Pool.')
param parDeployApacheSparkpool bool

@sys.description('The size of the Apache Spark Pool.')
@allowed([
  'Small'
  'Medium'
  'Large'
])
param parSparkNodeSize string

@sys.description('Frequency of the Resume Logic App.')
@allowed([
  'Daily'
  'Weekdays'
])
param parFrequency string

@sys.description('Time Zone to use in the Resume Logic App.')
@allowed([
  'Dateline Standard Time'
  'Samoa Standard Time'
  'Hawaiian Standard Time'
  'Alaskan Standard Time'
  'Pacific Standard Time'
  'Mountain Standard Time'
  'Mexico Standard Time 2'
  'Central Standard Time'
  'Canada Central Standard Time'
  'Mexico Standard Time'
  'Central America Standard Time'
  'Eastern Standard Time'
  'Atlantic Standard Time'
  'Newfoundland and Labrador Standard Time'
  'E. South America Standard Time'
  'S.A. Eastern Standard Time'
  'Greenland Standard Time'
  'Mid-Atlantic Standard Time'
  'Azores Standard Time'
  'Cape Verde Standard Time'
  'GMT Standard Time'
  'Greenwich Standard Time'
  'Central Europe Standard Time'
  'Central European Standard Time'
  'Romance Standard Time'
  'W. Europe Standard Time'
  'W. Central Africa Standard Time'
  'E. Europe Standard Time'
  'Egypt Standard Time'
  'FLE Standard Time'
  'GTB Standard Time'
  'Israel Standard Time'
  'South Africa Standard Time'
  'Russian Standard Time'
  'Arab Standard Time'
  'E. Africa Standard Time'
  'Arabic Standard Time'
  'Iran Standard Time'
  'Arabian Standard Time'
  'Caucasus Standard Time'
  'Transitional Islamic State of Afghanistan Standard Time'
  'Ekaterinburg Standard Time'
  'West Asia Standard Time'
  'India Standard Time'
  'Nepal Standard Time'
  'Central Asia Standard Time'
  'Sri Lanka Standard Time'
  'Myanmar Standard Time'
  'North Asia Standard Time'
  'China Standard Time'
  'Singapore Standard Time'
  'Taipei Standard Time'
  'North Asia East Standard Time'
  'Korea Standard Time'
  'Tokyo Standard Time'
  'Yakutsk Standard Time'
  'Tasmania Standard Time'
  'Vladivostok Standard Time'
  'West Pacific Standard Time'
  'Central Pacific Standard Time'
  'Fiji Islands Standard Time'
  'New Zealand Standard Time'
  'Tonga Standard Time'
])
param parTIME_ZONE string

@sys.description('Time to resume the Synapse SQL Pool.')
@allowed([
  '12:00 AM (  0:00 )'
  '01:00 AM (  1:00 )'
  '02:00 AM (  2:00 )'
  '03:00 AM (  3:00 )'
  '04:00 AM (  4:00 )'
  '05:00 AM (  5:00 )'
  '06:00 AM (  6:00 )'
  '07:00 AM (  7:00 )'
  '08:00 AM (  8:00 )'
  '09:00 AM (  9:00 )'
  '10:00 AM ( 10:00 )'
  '11:00 AM ( 11:00 )'
  '12:00 PM ( 12:00 )'
  '01:00 PM ( 13:00 )'
  '02:00 PM ( 14:00 )'
  '03:00 PM ( 15:00 )'
  '04:00 PM ( 16:00 )'
  '05:00 PM ( 17:00 )'
  '06:00 PM ( 18:00 )'
  '07:00 PM ( 19:00 )'
  '08:00 PM ( 20:00 )'
  '09:00 PM ( 21:00 )'
  '10:00 PM ( 22:00 )'
  '11:00 PM ( 23:00 )'
])
param parResumeTime string

@sys.description('Time to pause the Synapse SQL Pool.')
@allowed([
  '12:00 AM (  0:00 )'
  '01:00 AM (  1:00 )'
  '02:00 AM (  2:00 )'
  '03:00 AM (  3:00 )'
  '04:00 AM (  4:00 )'
  '05:00 AM (  5:00 )'
  '06:00 AM (  6:00 )'
  '07:00 AM (  7:00 )'
  '08:00 AM (  8:00 )'
  '09:00 AM (  9:00 )'
  '10:00 AM ( 10:00 )'
  '11:00 AM ( 11:00 )'
  '12:00 PM ( 12:00 )'
  '01:00 PM ( 13:00 )'
  '02:00 PM ( 14:00 )'
  '03:00 PM ( 15:00 )'
  '04:00 PM ( 16:00 )'
  '05:00 PM ( 17:00 )'
  '06:00 PM ( 18:00 )'
  '07:00 PM ( 19:00 )'
  '08:00 PM ( 20:00 )'
  '09:00 PM ( 21:00 )'
  '10:00 PM ( 22:00 )'
  '11:00 PM ( 23:00 )'
])
param parPauseTime string

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
    parDeploySqlPool: parDeploySqlPool
    parMetaDataSyncEnabled: parMetaDataSyncEnabled
    parSqlPoolSku: parSqlPoolSku
    parDeployApacheSparkpool: parDeployApacheSparkpool
    parSparkNodeSize: parSparkNodeSize
    parAdlsStorageName: modAdlsDeploy.outputs.outAdlsName
    parLocation: parLocation
    parSqlAdminPassword: parSqlAdminPassword
    parSqlAdminUsername: parSqlAdminUsername
  }
}

module modRoleAssignmentsDeploy 'modules/modRoleAssignments.bicep' = {
  scope: resourceGroup(resSynapseResourceGroup.name)
  name: 'modRoleAssignmentsDeploy'
  params: {
    parAdlsName: modAdlsDeploy.outputs.outAdlsName
    parSynapseWorkspaceId: modSynapseDeploy.outputs.outSynapsePrincipalId
  }
}

module modResumeLogicAppDeploy 'modules/modResumeLogicApp.bicep' = {
  scope: resourceGroup(resSynapseResourceGroup.name)
  name: 'modResumeLogicAppDeploy'
  params: {
    parFrequency: parFrequency
    parSynapseWorkspaceName: modSynapseDeploy.outputs.outSynapseWorkspaceName
    parTIME_ZONE: parTIME_ZONE
    parLocation: parLocation
    parLogicAppName: 'la-${parLocation}-resume-001'
    parResumeTime: parResumeTime
    parSynapseSqlPoolName: 'sqlpool'
  }
}

module modPauseLogicAppDeploy 'modules/modPauseLogicApp.bicep' = {
  scope: resourceGroup(resSynapseResourceGroup.name)
  name: 'modPauseLogicAppDeploy'
  params: {
    parFrequency: parFrequency
    parSynapseWorkspaceName: modSynapseDeploy.outputs.outSynapseWorkspaceName
    parTIME_ZONE: parTIME_ZONE
    parLocation: parLocation
    parLogicAppName: 'la-${parLocation}-pause-001'
    parPauseTime: parPauseTime
    parSynapseSqlPoolName: 'sqlpool'
  }
}

module modPauseLogicAppRoleAssignment 'modules/modLogicAppRoleAssignments.bicep' = {
  scope: resourceGroup(resSynapseResourceGroup.name)
  name: 'modPauseLogicAppRoleAssignment'
  params: {
    parLogicAppId: modPauseLogicAppDeploy.outputs.outLogicAppId
    parSynapseWorkspaceName: modSynapseDeploy.outputs.outSynapseWorkspaceName
  }
}

module modResumeLogicAppRoleAssignment 'modules/modLogicAppRoleAssignments.bicep' = {
  scope: resourceGroup(resSynapseResourceGroup.name)
  name: 'modResumeLogicAppRoleAssignment'
  params: {
    parLogicAppId: modResumeLogicAppDeploy.outputs.outLogicAppId
    parSynapseWorkspaceName: modSynapseDeploy.outputs.outSynapseWorkspaceName
  }
}
