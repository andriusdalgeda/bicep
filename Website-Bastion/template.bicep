param location string
param resourceGroup string
param bastionHostName string
param subnetId string
param bastionHostSku string
param bastionHostScaleUnits int
param enableIpConnect bool
param enableTunneling bool
param enableShareableLink bool
param enableKerberos bool
param disableCopyPaste bool
param enableSessionRecording bool
param enablePrivateOnlyBastion bool
param zones array
param publicIpZones array
param publicIpAddressName string
param vnetName string

resource publicIpAddress 'Microsoft.Network/publicIpAddresses@2020-08-01' = {
  name: publicIpAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  tags: {}
  zones: publicIpZones
}

resource sdasdsdsad 'Microsoft.Network/virtualNetworks@2019-09-01' = {
  name: 'sdasdsdsad'
  location: location
  properties: {
    subnets: [
      {
        name: 'default'
        id: '/subscriptions/f840b6f5-6a35-4434-9323-89c7b8722b47/resourceGroups/bastiontyesy/providers/Microsoft.Network/virtualNetworks/sdasdsdsad/subnets/default'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
      {
        name: 'AzureBastionSubnet'
        id: '/subscriptions/f840b6f5-6a35-4434-9323-89c7b8722b47/resourceGroups/bastiontyesy/providers/Microsoft.Network/virtualNetworks/sdasdsdsad/subnets/AzureBastionSubnet'
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
    ]
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
  }
  tags: {}
}

resource bastionHost 'Microsoft.Network/bastionHosts@2023-09-01' = {
  name: bastionHostName
  sku: {
    name: bastionHostSku
  }
  location: location
  properties: {
    enableIpConnect: enableIpConnect
    enableTunneling: enableTunneling
    enableShareableLink: enableShareableLink
    enableKerberos: enableKerberos
    disableCopyPaste: disableCopyPaste
    enableSessionRecording: enableSessionRecording
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: subnetId
          }
          publicIPAddress: {
            id: resourceId(resourceGroup, 'Microsoft.Network/publicIpAddresses', publicIpAddressName)
          }
        }
      }
    ]
    scaleUnits: bastionHostScaleUnits
    enablePrivateOnlyBastion: enablePrivateOnlyBastion
  }
  zones: zones
  tags: {}
  dependsOn: [
    resourceId(resourceGroup, 'Microsoft.Network/publicIpAddresses', publicIpAddressName)
    resourceId(resourceGroup, 'Microsoft.Network/virtualNetworks', vnetName)
  ]
}
