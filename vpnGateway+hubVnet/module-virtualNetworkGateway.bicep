param paramLocation string

param paramHubVnetName string

param paramTags object

// vpn gateway
param paramVnetGatewayName string
param paramVpnGatewayGeneration string
param paramVpnGatewaySku string
param paramVpnClientAddressPool string 

@description('Entra ID TenantID')
param paramAadTenantId string
param paramAadTenantURL string = 'https://login.microsoftonline.com/${paramAadTenantId}/'
param paramAadIssuerURL string = 'https://sts.windows.net/${paramAadTenantId}/'

resource resPublicIP1 'Microsoft.Network/publicIPAddresses@2024-07-01' = {
  name: 'pip-vgw-prod-1'
  location: paramLocation
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  sku:{
    name:'Standard'
  }
  tags: paramTags
}

resource resPublicIP2 'Microsoft.Network/publicIPAddresses@2024-07-01' = {
  name: 'pip-vgw-prod-2'
  location: paramLocation
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    name: 'Standard'
  }
  tags: paramTags
}

resource resPublicIP3 'Microsoft.Network/publicIPAddresses@2024-07-01' = {
  name: 'pip-vgw-prod-3'
  location: paramLocation
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    name: 'Standard'
  }
  tags: paramTags
}

resource resVnetGateway 'Microsoft.Network/virtualNetworkGateways@2024-07-01' = {
  name: paramVnetGatewayName
  location: paramLocation
  properties: {
    activeActive: true
    allowRemoteVnetTraffic: true
    allowVirtualWanTraffic: true

    ipConfigurations:[
      {
        name: 'vnetGateway1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resPublicIP1.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', paramHubVnetName, 'GatewaySubnet')
          }
        }
      }
      {
        name: 'vnetGateway2'
        properties:{
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress:{
            id: resPublicIP2.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', paramHubVnetName, 'GatewaySubnet')
          }
        }
      }
      {
        name: 'vnetGateway3'
        properties:{
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress:{
            id: resPublicIP3.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', paramHubVnetName, 'GatewaySubnet')
          }
        }
      }
    ]
    
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'

    vpnGatewayGeneration: paramVpnGatewayGeneration
    sku: {
      name: paramVpnGatewaySku
      tier: paramVpnGatewaySku
    }

    vpnClientConfiguration: {
      vpnClientAddressPool: {
        addressPrefixes: [
          paramVpnClientAddressPool
        ]
      }
      vpnClientProtocols: [
        'OpenVPN'
      ]
      aadTenant: paramAadTenantURL
      aadAudience: '41b23e61-6c1e-4545-b367-cd054e0ed4b4' // azure vpn 
      aadIssuer: paramAadIssuerURL
    }

    enableBgp: false
  
  }
  tags: paramTags
}
