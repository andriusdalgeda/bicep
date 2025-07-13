param paramLocation string

// hub
param paramHubVnetName string
param paramHubVnetIPRange string

//  gateway subnet
param paramGatewaySubnetRange string

//  firewall subnet
param paramFirewallSubnetRange string

//  bastion subnet
param paramBastionSubnetRange string

// tags
param paramTags object

resource resHubVnet 'Microsoft.Network/virtualNetworks@2024-07-01' = {
  name: paramHubVnetName
  location: paramLocation
  properties:{
    addressSpace:{
      addressPrefixes:[
        paramHubVnetIPRange
      ]
    }
    subnets: [
      {
        name: 'GatewaySubnet'
        properties:{
          addressPrefix: paramGatewaySubnetRange
        }
      }
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: paramFirewallSubnetRange
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties:{
          addressPrefix: paramBastionSubnetRange
        }
      }
    ]
  }
  tags: paramTags
}

output hubVnetId string = resHubVnet.id
output hubVnetName string = paramHubVnetName
