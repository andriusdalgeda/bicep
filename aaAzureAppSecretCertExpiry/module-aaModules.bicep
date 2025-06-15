param __AAModuleVersion string
param __AAModuleName string
param __AutomationAccName string 

param __AAModuleUri string = 'https://www.powershellgallery.com/api/v2/package/${__AAModuleName}/${__AAModuleVersion}'

param __Location string = resourceGroup().location

resource automationAccount 'Microsoft.Automation/automationAccounts@2024-10-23' existing = {
  name: __AutomationAccName
}

resource symbolicname 'Microsoft.Automation/automationAccounts/powerShell72Modules@2023-11-01' = {
  location: __Location
  parent: automationAccount
  name: __AAModuleName
  properties: {
    contentLink: {
      uri: __AAModuleUri
    }
  }
}
