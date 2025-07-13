param paramTags object = {
  env     : 'prod'
  region  : 'uksouth'
  iac     : 'true'
}

module hubVnet 'module-hubVnet.bicep' = {
  name:                        'hubVnet'
  params:{
    paramHubVnetName:          'vnet-hub-uks-prod'
    paramHubVnetIPRange:       '10.0.0.0/16'
    paramGatewaySubnetRange:   '10.0.1.0/24'
    paramFirewallSubnetRange:  '10.0.2.0/24'
    paramBastionSubnetRange:   '10.0.3.0/24'

    paramLocation: resourceGroup().location
    paramTags: paramTags
  }
  // outputs:
  // hubVnetId
  // hubVnetName
}

/// deploys vpn gateway in active-active config (requiring 3 PIPs)
module virtualNetworkGateway 'module-virtualNetworkGateway.bicep' = {
  name:                        'virtualNetworkGateway'
  params: {
    paramVnetGatewayName:      'vng-hub-uks-prod'
    
    paramVpnGatewayGeneration: 'Generation1'
    paramVpnGatewaySku:        'VpnGw1'
    paramVpnClientAddressPool: '172.16.0.0/24'

    paramAadTenantId:          '970b9027-1298-479c-8ade-f396586b719c'

    paramHubVnetName: hubVnet.outputs.hubVnetName
    paramLocation: resourceGroup().location

    paramTags: paramTags
  }
}

