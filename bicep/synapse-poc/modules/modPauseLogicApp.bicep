@sys.description('Location of the Resume Logic App.')
param parLocation string

@sys.description('Name of the Resume Logic App.')
param parLogicAppName string

@sys.description('Frequency of the Resume Logic App.')
param parFrequency string

@sys.description('Time Zone to use in the Resume Logic App.')
param parTIME_ZONE string

@sys.description('Time to resume the Synapse SQL Pool.')
param parPauseTime string

@sys.description('Name of the Synapse Workspace.')
param parSynapseWorkspaceName string

@sys.description('Name of the Synapse SQL Pool.')
param parSynapseSqlPoolName string

var resumeTimeHour = split(substring(parPauseTime, 11, 5), ':')[0]
var recurrenceHours = [
  resumeTimeHour
]
var recurrenceMinutes = [
  0
]
var dailySchedule = [
  'Monday'
  'Tuesday'
  'Wednesday'
  'Thursday'
  'Friday'
  'Saturday'
  'Sunday'
]
var weekdaySchedule = [
  'Monday'
  'Tuesday'
  'Wednesday'
  'Thursday'
  'Friday'
]
var recurrenceSchedule = ((parFrequency == 'Weekdays') ? weekdaySchedule : dailySchedule)
var managementEndpoint = environment().resourceManager
var getRESTAPI = 'subscriptions/@{variables(\'RestAPIVariables\')[\'SubscriptionId\']}/resourceGroups/@{variables(\'RestAPIVariables\')[\'ResourceGroupName\']}/providers/Microsoft.Synapse/workspaces/@{variables(\'RestAPIVariables\')[\'workspaceName\']}/sqlPools/@{variables(\'RestAPIVariables\')[\'sqlPoolName\']}?api-version=2019-06-01-preview'
var pauseRESTAPI = 'subscriptions/@{variables(\'RestAPIVariables\')[\'SubscriptionId\']}/resourceGroups/@{variables(\'RestAPIVariables\')[\'ResourceGroupName\']}/providers/Microsoft.Synapse/workspaces/@{variables(\'RestAPIVariables\')[\'workspaceName\']}/sqlPools/@{variables(\'RestAPIVariables\')[\'sqlPoolName\']}/pause?api-version=2019-06-01-preview'
var aqcRESTAPI = 'subscriptions/@{variables(\'RestAPIVariables\')[\'SubscriptionId\']}/resourceGroups/@{variables(\'RestAPIVariables\')[\'ResourceGroupName\']}/providers/Microsoft.Synapse/workspaces/@{variables(\'RestAPIVariables\')[\'WorkspaceName\']}/sqlpools/@{variables(\'RestAPIVariables\')[\'SQLPoolName\']}/dataWarehouseUserActivities/current?api-version=2019-06-01-preview'

resource LogicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: parLogicAppName
  location: parLocation
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      actions: {
        Initialize_API_variables: {
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'RestAPIVariables'
                type: 'Object'
                value: {
                  workspaceName: parSynapseWorkspaceName
                  sqlPoolName: parSynapseSqlPoolName
                  ResourceGroupName: resourceGroup().name
                  SubscriptionId: subscription().subscriptionId
                  TenantId: subscription().tenantId
                  ScheduleTimeZone: parTIME_ZONE
                  ResumeTime: parPauseTime
                }
              }
            ]
          }
        }
        Initialize_ActiveQueryCount_variable: {
          inputs: {
            variables: [
              {
                name: 'ActiveQueryCount'
                type: 'Integer'
                value: 1
              }
            ]
          }
          runAfter: {
            Initialize_API_variables: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
        }
        Get_Synapse_state: {
          type: 'Http'
          inputs: {
            method: 'GET'
            uri: '${managementEndpoint}${getRESTAPI}'
            authentication: {
              type: 'ManagedServiceIdentity'
            }
          }
          runAfter: {
            Initialize_API_Variables: [
              'Succeeded'
            ]
          }
        }
        Parse_JSON: {
          inputs: {
            content: '@body(\'Get_Synapse_state\')'
            schema: {
              properties: {
                id: {
                  type: 'string'
                }
                location: {
                  type: 'string'
                }
                name: {
                  type: 'string'
                }
                properties: {
                  properties: {
                    collation: {
                      type: 'string'
                    }
                    creationDate: {
                      type: 'string'
                    }
                    maxSizeBytes: {
                      type: 'integer'
                    }
                    provisioningState: {
                      type: 'string'
                    }
                    restorePointInTime: {
                      type: 'string'
                    }
                    status: {
                      type: 'string'
                    }
                  }
                  type: 'object'
                }
                sku: {
                  properties: {
                    capacity: {
                      type: 'integer'
                    }
                    name: {
                      type: 'string'
                    }
                  }
                  type: 'object'
                }
                type: {
                  type: 'string'
                }
              }
              type: 'object'
            }
          }
          runAfter: {
            Get_Synapse_state: [
              'Succeeded'
            ]
          }
          type: 'ParseJson'
        }
        PauseSynapseIfOnline: {
          type: 'If'
          expression: {
            and: [
              {
                equals: [
                  '@body(\'Get_Synapse_state\')[\'properties\'][\'status\']'
                  'Online'
                ]
              }
            ]
          }
          actions: {
            Pause_SQL_Pool: {
              type: 'Http'
              inputs: {
                method: 'POST'
                uri: '${managementEndpoint}${pauseRESTAPI}'
                authentication: {
                  type: 'ManagedServiceIdentity'
                }
              }
            }
            Until_ZeroActiveQueries: {
              type: 'Until'
              expression: '@equals(variables(\'ActiveQueryCount\'), 0)'
              limit: {
                count: 3
                timeout: 'PT3H'
              }
              actions: {
                GetActiveQueryCount: {
                  type: 'Http'
                  inputs: {
                    method: 'GET'
                    uri: '${managementEndpoint}${aqcRESTAPI}'
                    authentication: {
                      type: 'ManagedServiceIdentity'
                    }
                  }
                }
                Update_ActiveQueryCount_variable: {
                  type: 'SetVariable'
                  inputs: {
                    name: 'ActiveQueryCount'
                    value: '@body(\'GetActiveQueryCount\')[\'properties\'][\'activeQueriesCount\']'
                  }
                  runAfter: {
                    GetActiveQueryCount: [
                      'Succeeded'
                    ]
                  }
                }
                Wait5minsIfActiveQuery: {
                  type: 'If'
                  actions: {
                    Wait_5mins: {
                      inputs: {
                        interval: {
                          count: 5
                          unit: 'Minute'
                        }
                      }
                      type: 'Wait'
                    }
                  }
                  expression: {
                    and: [
                      {
                        greater: [
                          '@variables(\'ActiveQueryCount\')'
                          0
                        ]
                      }
                    ]
                  }
                  runAfter: {
                    Update_ActiveQueryCount_variable: [
                      'Succeeded'
                    ]
                  }
                }
              }
            }
          }
          runAfter: {
            Parse_JSON: [
              'Succeeded'
            ]
          }
        }
      }
      triggers: {
        Recurrence: {
          type: 'Recurrence'
          recurrence: {
            frequency: 'Week'
            interval: 1
            timeZone: parTIME_ZONE
            startTime: '2019-01-01T00:00:00Z'
            schedule: {
              weekDays: recurrenceSchedule
              hours: recurrenceHours
              minutes: recurrenceMinutes
            }
          }
        }
      }
      contentVersion: '1.0.0.0'
    }
  }
}

output outLogicAppId string = LogicApp.identity.principalId
