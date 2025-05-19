// templates used:
// https://www.jorgebernhardt.com/bicep-azure-virtual-machine-scale-sets/
// https://learn.microsoft.com/en-us/azure/virtual-machine-scale-sets/quick-create-bicep-windows?tabs=CLI

param parLocation string = resourceGroup().location

@description('The SKU of the VM.')
param vmSku string = 'Standard_D2s_v3'

@description('The number of VM instances.')
param instanceCount int

@description('The prefix for the VMSS name.')
param nameSubfix string

@description('The operating system type.')
@allowed([
  'Windows'
  'Ubuntu'
])
param osType string

@description('The admin username for the VM.')
param adminUsername string

@secure()
@description('The admin password for the VM.')
param adminPassword string

@description('The tags to be associated with the VMSS.')
param tags object = {
  bicep: 'true'
}

var osProfile = {
  computerNamePrefix: nameSubfix
  adminUsername: adminUsername
  adminPassword: adminPassword
  windowsConfiguration: osType == 'Windows' ? {
    enableAutomaticUpdates: true
  } : null
  linuxConfiguration: osType != 'Windows' ? {
    disablePasswordAuthentication: false
  } : null
}

var imageReference = {
  publisher: osType == 'Windows' ? 'MicrosoftWindowsServer' : 'Canonical'
  offer: osType == 'Windows' ? 'WindowsServer' : 'UbuntuServer'
  sku: osType == 'Windows' ? '2022-Datacenter' : '18_04-LTS-GEN2'
  version: 'latest'
}

var networkConfig = {
  networkInterfaceConfigurations: [
    {
      name: 'nic'
      properties: {
        primary: true
        ipConfigurations: [
          {
            name: 'ipconfig'
            properties: {
              subnet: {
                id: resVnet.properties.subnets[0].id
              }
              loadBalancerBackendAddressPools: [
                {
                  id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'vmss-lb', 'vmss-bepool')
                }
              ]
            }
          }
        ]
      }
    }
  ]
}

var osDiskConfig = {
  caching: 'ReadWrite'
  managedDisk: {
    storageAccountType: 'Standard_LRS'
  }
  createOption: 'FromImage'
}

var storageProfile = {
  imageReference: imageReference
  osDisk: osDiskConfig
}
param parSubnetName string
param parVnetName string

@description('10.0.0.0/16')
param parVnetPrefix string
@description('10.0.1.0/24')
param parSubnetPrefix string

resource resPIP 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: 'PIP-LB'
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

resource loadBalancer 'Microsoft.Network/loadBalancers@2023-04-01' = {
  name: 'vmss-lb'
  location: parLocation
  properties: {
    frontendIPConfigurations: [
      {
        name: 'vmss-fepool'
        properties: {
          publicIPAddress: {
            id: resPIP.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'vmss-bepool'
      }
    ]
    loadBalancingRules: [
      {
        name: 'LBRule'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', 'vmss-lb', 'vmss-fepool')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'vmss-lb', 'vmss-bepool')
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', 'vmss-lb', 'tcpProbe')
          }
        }
      }
    ]
    probes: [
      {
        name: 'tcpProbe'
        properties: {
          protocol: 'Tcp'
          port: 80
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
  }
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
}

resource resVnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: parVnetName
  location: parLocation
  properties: {
    addressSpace: {
       addressPrefixes: [
        parVnetPrefix
       ]
    }
    subnets: [
      {
        name: parSubnetName
        properties: {
          addressPrefix: parSubnetPrefix
        }
      }
    ]
  }
}

resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2023-07-01' = {
  name: 'vmss-${nameSubfix}'
  location: parLocation
  tags: tags
  sku: {
    name: vmSku
    tier: 'Standard'
    capacity: instanceCount
  }
  properties: {
    overprovision: true
    upgradePolicy: {
      mode: 'Manual'
    }
    virtualMachineProfile: {
      osProfile: osProfile
      storageProfile: storageProfile
      networkProfile: networkConfig
    }
  }
  zones:[
    '2'
  ]
}

resource autoscalehost 'Microsoft.Insights/autoscalesettings@2022-10-01' = {
  name: 'autoscalehost'
  location: parLocation
  properties: {
    name: 'autoscalehost'
    targetResourceUri: vmss.id
    enabled: true
    profiles: [
      {
        name: 'Profile1'
        capacity: {
          minimum: '1'
          maximum: '10'
          default: '1'
        }
        rules: [
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricResourceUri: vmss.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: 50
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricResourceUri: vmss.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: 30
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
        ]
      }
    ]
  }
}

