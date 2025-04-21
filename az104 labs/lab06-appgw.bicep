param parLocation string = resourceGroup().location

@description('Password for the Virtual Machine.')
@minLength(12)
@secure()
param parAdminPassword string

param parVMNamePrefix string = 'web'
param parSubnetName1 string= 'image'
param parSubnetName2 string = 'video'
param parAppGWSubnetName string = 'subnet-appgw'
param parVnetName string = 'vnet1'

@description('10.0.0.0/16')
param parVnetPrefix string = '10.60.0.0/16'

@description('10.0.1.0/24')
param parSubnetPrefix1 string = '10.60.1.0/24'
param parSubnetPrefix2 string = '10.60.2.0/24'
param parAppGWSubnetPrefix string = '10.60.3.0/24'


param parNSGName string = 'WebServerNSG'
param parNSG1Name string = 'AppGWNSG'

param parAppGWName string = 'andriustest-gw'

var subnets = {
  subnet1 :{
    subnetName: parSubnetName1
  }
  subnet2 :{
    subnetName: parSubnetName2
  }
}

module VM 'modules/lab06-appgw-vm.bicep' = [for (item, index) in items(subnets): {
  name: '${item.key}-Deploy'
  params:{
    parAdminPassword: parAdminPassword
    parSubnetName: item.value.subnetName
    parVMNamePrefix: parVMNamePrefix
    parVnetName: parVnetName
    parAppGWName: parAppGWName
  }
  dependsOn:[
    resVnet
    resAppGW
  ]
}]

resource resPIP 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: 'PIP-AppGW'
  location: parLocation
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties:{
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource resNSG 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: parNSGName
  location: parLocation
  properties:{
    securityRules:[
      {
        name: 'AllowPort80'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
        }
    ]
  }
}

resource resNSG1 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: parNSG1Name
  location: parLocation
  properties:{
    securityRules:[
      {
        name: 'AllowPort80'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowAppGWPorts'
        properties: {
          protocol: '*'
          sourcePortRange: '65200-65535'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 900
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
    ]
  }
}

resource resVnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: parVnetName
  location: parLocation
  properties:{
    addressSpace: {
      addressPrefixes:[
        parVnetPrefix
      ]
    }
  subnets:[
    {
      name: parSubnetName1
      properties:{
        addressPrefix: parSubnetPrefix1
        networkSecurityGroup: {
          id: resNSG.id
        }
      }
    }
    {
      name: parSubnetName2
      properties:{
        addressPrefix: parSubnetPrefix2
        networkSecurityGroup: {
          id: resNSG.id
        }
      }
    }
    {
      name: parAppGWSubnetName
      properties:{
        addressPrefix: parAppGWSubnetPrefix
        networkSecurityGroup: {
          id: resNSG1.id
        }
        }
      
    }
  ]
  }
}

resource resAppGW 'Microsoft.Network/applicationGateways@2024-05-01' = {
  name: parAppGWName
  location: parLocation
  properties: {
    sku: {
      tier: 'Standard_v2'
      name: 'Standard_v2'
    }
    autoscaleConfiguration: {
      minCapacity: 2
      maxCapacity: 4
    }
    gatewayIPConfigurations: [
      {
        name: 'GWIPConfig'
        properties: {
          subnet:{
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', parVnetName, parAppGWSubnetName)
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'frontendAppGWIPConfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resPIP.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port80'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'image'
        properties: {
          backendAddresses: [
          ]
        }
      }
      {
        name: 'video'
        properties: {
          backendAddresses: [
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'http'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          requestTimeout: 20
        }
      }
    ]
    httpListeners: [
      {
        name: 'listener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', parAppGWName, 'frontendAppGWIPConfig')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', parAppGWName, 'port80')
          }
          protocol: 'Http'
          requireServerNameIndication: false
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'pathBasedRoutingRule'
        properties: {
          ruleType: 'PathBasedRouting'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', parAppGWName, 'listener')
          }
          urlPathMap: {
            id: resourceId('Microsoft.Network/applicationGateways/urlPathMaps', parAppGWName, 'urlPathMap')
          }
          priority: 100
        }
      }
    ]
    urlPathMaps: [
      {
        name: 'urlPathMap'
        properties: {
          defaultBackendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', parAppGWName, 'image')
          }
          defaultBackendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', parAppGWName, 'http')
          }
          pathRules: [
            {
              name: 'imagePathRule'
              properties: {
                paths: [
                  '/image*'
                ]
                backendAddressPool: {
                  id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', parAppGWName, 'image')
                }
                backendHttpSettings: {
                  id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', parAppGWName, 'http')
                }
              }
            }
            {
              name: 'videoPathRule'
              properties: {
                paths: [
                  '/video*'
                ]
                backendAddressPool: {
                  id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', parAppGWName, 'video')
                }
                backendHttpSettings: {
                  id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', parAppGWName, 'http')
                }
              }
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    resVnet
  ]
}





