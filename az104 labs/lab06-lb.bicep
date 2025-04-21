param parLocation string = resourceGroup().location

@description('Password for the Virtual Machine.')
@minLength(12)
@secure()
param parAdminPassword string

param parVMNamePrefix string
param parSubnetName string
param parVnetName string

@description('10.0.0.0/16')
param parVnetPrefix string
@description('10.0.1.0/24')
param parSubnetPrefix string

param parNSGName string = 'WebServerNSG'

param parLBName string = 'publicLB'

param parScriptExtension string = 'powershell.exe Install-WindowsFeature -name Web-Server -IncludeManagementTools && powershell.exe remove-item \'C:\\inetpub\\wwwroot\\iisstart.htm\' && powershell.exe Add-Content -Path \'C:\\inetpub\\wwwroot\\iisstart.htm\' -Value $(\'Hello World from \' + $env:computername)'

param parVMCount int = 2

module VM 'modules/lab06-lb-vm.bicep' = [for i in range(0, parVMCount): {
  name: '${i}-Deploy-${parVMNamePrefix}'
  params:{
    parAdminPassword: parAdminPassword
    parSubnetName: parSubnetName
    parVMNamePrefix: parVMNamePrefix
    parVnetName: parVnetName
    parScriptExtension: parScriptExtension
    parLBName: parLBName
  }
  dependsOn:[
    resVnet
    resLB
  ]
}]

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
      name: parSubnetName
      properties:{
        addressPrefix: parSubnetPrefix
        networkSecurityGroup: {
          id: resNSG.id
        }
      }
    }

  ]
  }
}

resource resLB 'Microsoft.Network/loadBalancers@2024-05-01' = {
  name: parLBName
  location: parLocation
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties:{
    frontendIPConfigurations:[
      {
        name: 'frontendLB'
        properties:{
          publicIPAddress: {
            id: resPIP.id
          }
        }
      }
    ]
    backendAddressPools:[
      {
        name: 'backendLB'
      }
    ]
    loadBalancingRules:[
      {
        name:'ruleLB'
        properties:{
          frontendIPConfiguration:{
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', parLBName, 'frontendLB')
          }
          backendAddressPool:{
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', parLBName, 'backendLB')
          }
          probe:{
            id: resourceId('Microsoft.Network/loadBalancers/probes', parLBName, 'lbprobe')
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          idleTimeoutInMinutes: 15
        }
      }
    ]
    probes:[
      {
        name: 'lbprobe'
        properties:{
          port: 80
          protocol: 'Tcp'
          intervalInSeconds: 60
          numberOfProbes: parVMCount
        }
      }
    ]
  }
}




