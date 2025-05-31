param paramLocation string = resourceGroup().location

////////////////////////////////// vnent & dependencies
param paramVnetName string = 'vnet-uks-prod-1'

@description('e.g 10.0.0.0/16')
param paramVnetPrefix string = '10.0.0.0/16'

// subnets
param paramVMSubnetName string = 'subnet-uks-vm'

@description('e.g 10.0.1.0/24')
param paramVMSubnetPrefix string = '10.0.1.0/24'

@description('Keep name the same')
param paramBastionSubnetName string = 'AzureBastionSubnet'
param paramBastionSubnetPrefix string = '10.0.2.0/24'

// nsg
param paramNSGName string = 'nsg-AllowRDP'

////////////////////////////////// vm & dependencies

@secure()
param paramAdminPassword string

param paramAdminUsername string

@description('Total number of VMs you want to deploy')
param paramVMCount int = 2
param paramVMNamePrefix string = 'vm-uks-prod'

////////////////////////////////// bastion & dependencies

param paramPIPName string = 'pip-global-bastion'
param paramBastionHostName string = 'bastion-uks-prod'

////////////////////////////////// start

module VM 'bastionVM.bicep' = [for i in range(0, paramVMCount): {
  name: '${i}-Deploy-${paramVMNamePrefix}'
  params:{
    paramAdminPassword: paramAdminPassword
    paramSubnetName: paramVMSubnetName
    paramVMNamePrefix: paramVMNamePrefix
    paramVnetName: paramVnetName
    paramAdminUsername: paramAdminUsername
  }
  dependsOn:[
    resVnet
  ]
}]

resource resVnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: paramVnetName
  location: paramLocation
  properties:{
    addressSpace: {
      addressPrefixes:[
        paramVnetPrefix
      ]
    }
  subnets:[
    {
      name: paramVMSubnetName
      properties:{
        addressPrefix: paramVMSubnetPrefix
        networkSecurityGroup: {
          id: resNSG.id
        }
      }
    }
        {
      name: paramBastionSubnetName
      properties:{
        addressPrefix: paramBastionSubnetPrefix
      }
    }

  ]
  }
}

resource resNSG 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: paramNSGName
  location: paramLocation
  properties:{
    securityRules:[
      {
        name: paramNSGName
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
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

resource publicIpAddressForBastion 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: paramPIPName
  location: paramLocation
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }

}

resource bastionHost 'Microsoft.Network/bastionHosts@2022-01-01' = {
  name: paramBastionHostName
  location: paramLocation
  sku: {
    name: 'Standard'
  }
  properties: {
    scaleUnits: 2
    enableShareableLink: true

    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/VirtualNetworks/subnets', paramVnetName, paramBastionSubnetName)
          }
          publicIPAddress: {
            id: publicIpAddressForBastion.id
          }
        }
      }
    ]
  }
  dependsOn:[
    resVnet
  ]
  
}

output bastionIP string = publicIpAddressForBastion.properties.ipAddress
