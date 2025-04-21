// http://microsoftlearning.github.io/AZ-104-MicrosoftAzureAdministrator/Instructions/Labs/LAB_07-Manage_Azure_Storage.html 

param parLocation string = resourceGroup().location
param parPrefix string = 'testSA'
param parStorageAccountName string = take('${parPrefix}-${newGuid()}',24)
param parRetentionDays int = 180

param parVnetRange string = '10.10.0.0/16'
param parSubnetRange string = '10.10.5.0/24'

// http://ifconfig.me/ip - ipv4 only or cidr range
param parPublicIp string = '45.89.85.20'

resource resVnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet1'
  location: parLocation
  properties: {
    addressSpace: {
       addressPrefixes: [
        parVnetRange
       ]
    }
    subnets: [
      {
        name: 'subnet1'
        properties: {
          addressPrefix: parSubnetRange
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
            }
          ]
        }
      }
    ]
  }
}

resource resStorageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' = {
  kind: 'StorageV2'
  location: parLocation
  name: parStorageAccountName
  sku: {
    name: 'Standard_GRS'
  }
  properties:{
    publicNetworkAccess: 'Enabled'
    immutableStorageWithVersioning:{
      enabled: true
      immutabilityPolicy:{
        immutabilityPeriodSinceCreationInDays: parRetentionDays
        state: 'Unlocked'
      }
    }

    encryption:{
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
        file: {
          enabled: true
          keyType: 'Account'
        }
      }
      keySource: 'Microsoft.Storage'
    }

    networkAcls:{
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules:[
        {
          action: 'Allow'
          value: parPublicIp
        }
      ]
    }

    accessTier: 'Hot'
  }

  resource resBlobService 'blobServices@2024-01-01' = {
    name: 'default'
    properties: { 
    }

    resource resBlob 'containers@2024-01-01' = {
      name: 'data'
      properties: {
        publicAccess: 'None'
      }
    }
  }

  resource resFileService 'fileServices@2024-01-01' = {
    name: 'default'

    resource resFileShare 'shares' = {
      name: 'share1'
      properties: {
      }
  }
  }
}


resource resPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: 'storagePrivateEndpoint'
  location: parLocation
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/Subnets', 'vnet1', 'subnet1')
    }
    privateLinkServiceConnections: [
      {
        name: 'fileShareToSubnet'
        properties: {
          privateLinkServiceId: resStorageAccount.id
          groupIds:[
            'file'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
  }
  dependsOn: [
    resVnet
  ]
}

resource resManagementRule 'Microsoft.Storage/storageAccounts/managementPolicies@2024-01-01' = {
  parent: resStorageAccount
  // name has to be default otherwise an api error is thrown up
  name: 'default' 
  properties:{
    policy: {
      rules: [
        {
          definition: {
            actions: {
              baseBlob: {
                tierToCool: {
                  daysAfterModificationGreaterThan: 30
                }
              }
            }
            filters:{
              blobTypes:[
                'blockBlob'
              ]
            }
          }
        name: 'Movetocool'
        type: 'Lifecycle'
        enabled: true
        
      }
      ]
    }
  }
}

