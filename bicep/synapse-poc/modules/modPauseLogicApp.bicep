param location string
param companyTla string
param deploymentType string
param LogicAppName string
param Frequency string
param TIME_ZONE string
param PauseTime string

var pauseTimeHour = split(substring(PauseTime, 11, 5), ':')[0]
var recurrenceHours = [
  pauseTimeHour
]
var recurrenceMinutes = [
  0
]
var pauseTimeString = substring(PauseTime, 0, 8)
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
var recurrenceSchedule = ((Frequency == 'Weekdays') ? weekdaySchedule : dailySchedule)
var synapseWorkspaceName = toLower('${synapseName}ws1')
var synapseName = '${companyTla}${deploymentType}'
var synapseSQLPoolName = toLower('${workspaceName}p1')
var workspaceName = toLower('${synapseName}ws1')
var getRESTAPI = 'subscriptions/@{variables(\'RestAPIVariables\')[\'SubscriptionId\']}/resourceGroups/@{variables(\'RestAPIVariables\')[\'ResourceGroupName\']}/providers/Microsoft.Synapse/workspaces/@{variables(\'RestAPIVariables\')[\'workspaceName\']}/sqlPools/@{variables(\'RestAPIVariables\')[\'sqlPoolName\']}?api-version=2019-06-01-preview'
var pauseRESTAPI = 'subscriptions/@{variables(\'RestAPIVariables\')[\'SubscriptionId\']}/resourceGroups/@{variables(\'RestAPIVariables\')[\'ResourceGroupName\']}/providers/Microsoft.Synapse/workspaces/@{variables(\'RestAPIVariables\')[\'workspaceName\']}/sqlPools/@{variables(\'RestAPIVariables\')[\'sqlPoolName\']}/pause?api-version=2019-06-01-preview'
var aqcRESTAPI = 'subscriptions/@{variables(\'RestAPIVariables\')[\'SubscriptionId\']}/resourceGroups/@{variables(\'RestAPIVariables\')[\'ResourceGroupName\']}/providers/Microsoft.Synapse/workspaces/@{variables(\'RestAPIVariables\')[\'WorkspaceName\']}/sqlpools/@{variables(\'RestAPIVariables\')[\'SQLPoolName\']}/dataWarehouseUserActivities/current?api-version=2019-06-01-preview'
var managementEndpoint = environment().resourceManager

resource LogicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: LogicAppName
  location: location
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
                  workspaceName: synapseWorkspaceName
                  sqlPoolName: synapseSQLPoolName
                  ResourceGroupName: resourceGroup().name
                  SubscriptionId: subscription().subscriptionId
                  TenantId: subscription().tenantId
                  ScheduleTimeZone: TIME_ZONE
                  PauseTime: pauseTimeString
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
            uri: '${managementEndpoint} ${getRESTAPI}'
            authentication: {
              type: 'ManagedServiceIdentity'
            }
          }
          runAfter: {
            Initialize_ActiveQueryCount_variable: [
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
              runAfter: {
                Until_ZeroActiveQueries: [
                  'Succeeded'
                ]
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
            timeZone: TIME_ZONE
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
