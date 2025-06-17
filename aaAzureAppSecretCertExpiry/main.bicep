extension microsoftGraphV1

param __Location string = resourceGroup().location

// automation & runbook params
param __AutomationAccName string = ''
param __RunbookName string = ''
param __RunbookDescription string = ''
param __RunbookUri string = 'https://raw.githubusercontent.com/andriusdalgeda/bicep/refs/heads/main/aaAzureAppSecretCertExpiry/main.ps1'

// communication services params
@description('Globally unique')
param __CommunicationServiceName string = ''
@description('Globally unique')
param __CommunicationServiceEmailName string = ''

param __CommunicationServiceEmailLocation string = 'UK'
param __SenderAddress string = 'DoNotReply'

// Communication and Email Service Owner
var __RoleDefinitionId string = '09976791-48a7-449e-bb21-39d1a415f350'

// graph api permissions 
var __appRoles array = ['User.Read.All', 'Application.Read.All', 'Directory.Read.All']

// module loop - ps module and version
var __AAModules = {
  'Az.Communication':{
      Version                    : '0.6.0'
  }
  'Microsoft.Graph.Applications':{
      Version                    : '2.25.0'
  }
  'Microsoft.Graph.Authentication':{
      Version                    : '2.25.0'
  }
  'Az.Accounts':{
      Version                    : '5.1.0'
  }
}

// Loop through varAAModules and install all the listed modules in the 7.2 ps environment
module moduleAppPSModules 'module-aaModules.bicep' = [for aaModule in items(__AAModules): {
  name: '${aaModule.key}-Deploy'
  params:{
    __AAModuleVersion            : aaModule.value.Version
    __AAModuleName               : aaModule.key
    __AutomationAccName          : __AutomationAccName
  }
  dependsOn: [
    automationAcc
  ]
}]

// grants managed identity attached to automation account specified roles to the graph app - used to authorise mggraph PS cmdlets
module moduleGraphAppRoles 'module-graphAppRoles.bicep' = {
  name: 'appScopeGrantDeploy'
  params: {
    __MIId              : automationAcc.identity.principalId
    __appRoles         : __appRoles
  }
}

resource automationAcc 'Microsoft.Automation/automationAccounts@2024-10-23' = {
  name: __AutomationAccName
  location: __Location

  identity:{
    type: 'SystemAssigned'
  }

    properties: {
    disableLocalAuth: false
    encryption: {
      identity: {
      }
      keySource: 'Microsoft.Automation'
    }
    publicNetworkAccess: true
    sku: {
      capacity: null
      family: null
      name: 'Basic'
    }
    }

  tags:{
    environment:' prod'
  }
}

resource runbook 'Microsoft.Automation/automationAccounts/runbooks@2024-10-23' = {
  name: __RunbookName
  parent: automationAcc
  location: __Location
  properties: {
    runbookType: 'PowerShell72'
    logProgress: false
    logVerbose: false
    description: __RunbookDescription

    publishContentLink: {
      uri: __RunbookUri
      version: '1.0.0'
    }
  }
}

resource schedule 'Microsoft.Automation/automationAccounts/schedules@2024-10-23' = {
  name: 'weeklyRun'
  parent: automationAcc
  
  properties: {
    frequency: 'Week'
    description: '8AM run every Monday'
    startTime: '2025-06-16T08:00:00+01:00'
    expiryTime: '9999-12-31T23:59:00+00:00'
    interval: 1
    timeZone: 'Europe/London'
    advancedSchedule:{
      weekDays: [
        'Monday'
      ]

    }
  }
}

resource setSchedule 'Microsoft.Automation/automationAccounts/jobSchedules@2024-10-23' = {
  name: guid(resourceGroup().id)
  parent: automationAcc
  properties: {
    runbook: {
      name: runbook.name
    }
    schedule: {
      name: schedule.name
    }
  }
  
}

resource emailCommunicationService 'Microsoft.Communication/emailServices@2023-04-01' = {
  name: __CommunicationServiceEmailName
  location: 'global'
  properties: {
    dataLocation: __CommunicationServiceEmailLocation
  }
}

resource emailDomain 'Microsoft.Communication/emailServices/domains@2023-04-01' = {
  parent: emailCommunicationService
  name: 'AzureManagedDomain'
  location: 'global'
  properties: {
    domainManagement: 'AzureManaged'
    userEngagementTracking: 'Disabled'
  }
  resource sender 'senderUsernames@2023-03-31' = {
    name: __SenderAddress
    properties: {
      username: __SenderAddress
      displayName: __SenderAddress
    }
  }
}

resource communicationService 'Microsoft.Communication/communicationServices@2023-04-01' = {
  name: __CommunicationServiceName
  location: 'global'
  properties: {
    dataLocation: 'UK'
    linkedDomains: [
      emailDomain.id
    ]
  }
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, automationAcc.id, communicationService.id)
  scope: communicationService
  properties: {
    // ideally replace with custom role with limited perms - /providers/Microsoft.Authorization/roleDefinitions/09976791-48a7-449e-bb21-39d1a415f350
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', __RoleDefinitionId)
    principalId: automationAcc.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// returns formatted host name needed for script
output emailEndpoint string = 'https://${communicationService.properties.hostName}'

// returns formatted sender address needed for script
output emailSenderDomain string = '${__SenderAddress}@${emailDomain.properties.mailFromSenderDomain}'



