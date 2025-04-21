param parLocation string = resourceGroup().location

@description('Username for the Virtual Machine.')
param parAdminUsername string = 'andriusadmin'

@description('Password for the Virtual Machine.')
@minLength(12)
@secure()
param parAdminPassword1 string

@description('Password for the Virtual Machine.')
@minLength(12)
@secure()
param parAdminPassword2 string

@description('The size of the VM')
param parvmSize string = 'Standard_D2s_v3'
var parosDiskType = 'Standard_LRS'

@description('The Windows version for the VM. This will pick a fully patched image of this given Windows version.')
param parOSVersion string = '2022-datacenter-azure-edition'
param parVM1Name string = 'CoreServicesVM'
param parVM2Name string = 'ManufacturingVM'

resource resASGWeb 'Microsoft.Network/applicationSecurityGroups@2024-05-01' = {
  name: 'asg-web'
  location: parLocation
}

resource resNSG1 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'myNSG'
  location: parLocation
  properties:{
  securityRules:[
    {
      name: 'AllowASG'
      properties: {
        access: 'Allow'
        sourceApplicationSecurityGroups: [
          {
            id: resASGWeb.id
            location: parLocation
          }
        ]
        sourcePortRange: '*'
        destinationAddressPrefix: '*'
        destinationPortRanges: [
          '40'
          '443'
        ]
        direction: 'Inbound'

        priority: 100
        protocol: 'TCP'
        description: 'Allow inbound from ASG'
      }
    }
    {
      name: 'DenyAnyCustom8080Outbound'
      properties:{
        access: 'Deny'
        description: 'Deny all outbound'
        sourceAddressPrefix: '0.0.0.0/0'
        sourcePortRange: '*' 
        destinationPortRange: '8080'
        protocol: '*'
        priority: 4096
        direction: 'Outbound'
        destinationApplicationSecurityGroups:[
          {
            id: resASGWeb.id
            location: parLocation
          }
        ]
      }
    }
    {
      name: 'default-allow-3389'
      properties: {
        priority: 1000
        access: 'Allow'
        direction: 'Inbound'
        destinationPortRange: '3389'
        protocol: 'Tcp'
        sourcePortRange: '*'
        sourceAddressPrefix: '*'
        destinationAddressPrefix: '*'
      }
    }
  ]
  }
}

resource resNSG2 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'myNSG2'
  location: parLocation
  properties:{
  securityRules:[
  {
    name: 'default-allow-3389'
    properties: {
      priority: 1000
      access: 'Allow'
      direction: 'Inbound'
      destinationPortRange: '3389'
      protocol: 'Tcp'
      sourcePortRange: '*'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: '*'
    }
  }
  ]
  }
}

resource resCoreServicesVnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'CoreServicesVnet'
  location: parLocation
  properties:{
    addressSpace: {
      addressPrefixes:[
        '10.20.0.0/16'
      ]
    }
  subnets:[
    {
      name: 'DatabaseSubnet'
      properties:{
        addressPrefix: '10.20.20.0/24'
      }
    }
    {
      name: 'SharedServicesSubnet'
      properties:{
        addressPrefix: '10.20.10.0/24'
        networkSecurityGroup:{
          id: resNSG1.id
        }
      }
    }
    {
      name: 'perimeter'
      properties:{
        addressPrefix: '10.20.1.0/24'
        networkSecurityGroup:{
          id: resNSG1.id
        }
        routeTable:{
          id: resRouteTable.id
        }
      }
    }
  ]
  }
}
resource resManufacturingVnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'ManufacturingVnet'
  location: parLocation
  properties:{
    addressSpace: {
      addressPrefixes:[
        '172.16.0.0/16'
      ]
    }
  subnets:[
    {
      name: 'Manufacturing'
      properties:{
        addressPrefix: '172.16.0.0/24'
        networkSecurityGroup: {
          id: resNSG2.id
        }
      }
    }
  ]
  }
}

resource resNIC 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: 'nic-${parVM1Name}'
  location: parLocation
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'CoreServicesVnet', 'SharedServicesSubnet')
          }
        }
      }
    ]
  }
  dependsOn: [
    resCoreServicesVnet
  ]
}

resource resVM1 'Microsoft.Compute/virtualMachines@2024-11-01' = {
  name: parVM1Name
  location: parLocation
  properties: {
    hardwareProfile: {
      vmSize: parvmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: parosDiskType
        }
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: parOSVersion
        version: 'latest'
        }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resNIC.id
        }
      ]
    }
    osProfile: {
      computerName: parVM1Name
      adminUsername: parAdminUsername
      adminPassword: parAdminPassword1
    }
  }
}

resource resNIC2 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: 'nic-${parVM2Name}'
  location: parLocation
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig2'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'ManufacturingVnet', 'Manufacturing')
          }
        }
      }
    ]
  }
  dependsOn: [
    resManufacturingVnet
  ]
}

resource resVM2 'Microsoft.Compute/virtualMachines@2024-11-01' = {
  name: parVM2Name
  location: parLocation
  properties: {
    hardwareProfile: {
      vmSize: parvmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: parosDiskType
        }
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: parOSVersion
        version: 'latest'
        }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resNIC2.id
        }
      ]
    }
    osProfile: {
      computerName: parVM2Name
      adminUsername: parAdminUsername
      adminPassword: parAdminPassword2
    }
  }
}

resource resCoreToManufacturing 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  parent: resCoreServicesVnet
  name: 'core-to-manufacturing'
  properties:{
    allowForwardedTraffic: true
    allowGatewayTransit: true
    remoteVirtualNetwork:{
      id: resManufacturingVnet.id
    }
  }
}

resource resManufacturingToCore 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  parent: resManufacturingVnet
  name: 'manufacturing-to-core'
  properties:{
    allowForwardedTraffic: true
    allowGatewayTransit: true
    remoteVirtualNetwork:{
      id: resCoreServicesVnet.id
    }
  }
}

resource resRouteTable 'Microsoft.Network/routeTables@2024-05-01' = {
  name: 'rt-CoreServices'
  location: parLocation
  properties: {
    disableBgpRoutePropagation: true
    routes: [
      {
        name: 'PerimetertoCore'
        properties: {
          addressPrefix: '10.20.0.0/16'
          nextHopIpAddress: '10.20.1.7'
          nextHopType: 'VirtualAppliance'
        }
      }
    ]
  }
}

output id1 string = resVM1.id
output id2 string = resVM2.id

